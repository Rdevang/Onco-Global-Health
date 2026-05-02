/**
 * Creates a new Person Account for a first-time patient when no existing
 * record matches the provided PersonEmail. Idempotent: if the email already
 * resolves to a Person Account, returns success with wasAlreadyRegistered=true
 * so callers (and the planner) can treat it as a no-op.
 *
 * Patient identity contract mirrors the rest of the Onco agent surface:
 *   - inputs are patient-friendly strings (name, email, optional phone/DOB/city)
 *   - NEVER returns a Salesforce Account Id to the caller
 *   - consentToContact must be true before creating a record
 */
public without sharing class OncoPatientRegister {

    private static final String PERSON_ACCOUNT_RT = 'PersonAccount';

    public class RegisterRequest {
        @InvocableVariable(required = true label = 'First name'
            description = 'Patient legal first name. Required.')
        public String firstName;

        @InvocableVariable(required = true label = 'Last name'
            description = 'Patient legal last name. Required.')
        public String lastName;

        @InvocableVariable(required = true label = 'Email'
            description = 'Plain email string (e.g. jane.doe@example.com). Used as the Person Account chart key. Never a Salesforce Id.')
        public String email;

        @InvocableVariable(label = 'Mobile phone (optional)'
            description = 'E.164 or local mobile number. Optional.')
        public String mobilePhone;

        @InvocableVariable(label = 'Date of birth (YYYY-MM-DD, optional)'
            description = 'ISO date. Optional but recommended for identity matching.')
        public String dateOfBirth;

        @InvocableVariable(label = 'City (optional)'
            description = 'Patient mailing city. Optional.')
        public String city;

        @InvocableVariable(required = true label = 'Consent to contact'
            description = 'Boolean confirming the patient explicitly consented to being contacted about appointments and care. Must be true before registration.')
        public Boolean consentToContact;
    }

    public class RegisterResult {
        @InvocableVariable public Boolean success;

        @InvocableVariable(
            label = 'Was already registered'
            description = 'True when the email resolved to an existing Person Account; no new record was created.'
        )
        public Boolean wasAlreadyRegistered;

        @InvocableVariable(
            label = 'Patient display name'
            description = 'Human-readable patient name to confirm in the reply. Never an Id.'
        )
        public String patientDisplayName;

        @InvocableVariable(
            label = 'Registered email'
            description = 'Plain email used for the patient record, echoed for confirmation.'
        )
        public String registeredEmail;

        @InvocableVariable(
            label = 'Message'
            description = 'Confirmation or error text safe to show to the patient.'
        )
        public String message;
    }

    @InvocableMethod(
        label='Register Patient'
        description='Creates a Person Account for a first-time patient using plain name, email, and optional phone/DOB/city. Idempotent: re-registering an existing email is a no-op. Never returns a Salesforce record Id.'
        category='Onco'
    )
    public static List<RegisterResult> registerPatient(List<RegisterRequest> requests) {
        RegisterResult r = new RegisterResult();
        r.success = false;
        r.wasAlreadyRegistered = false;

        if (requests == null || requests.isEmpty()) {
            r.message = 'No request provided.';
            return new List<RegisterResult>{ r };
        }
        RegisterRequest req = requests[0];

        String normalizedEmail = normalize(req.email);
        String first = trimOrNull(req.firstName);
        String last  = trimOrNull(req.lastName);
        String phone = trimOrNull(req.mobilePhone);

        if (String.isBlank(first) || String.isBlank(last) || String.isBlank(normalizedEmail)) {
            r.message = 'First name, last name, and email are all required.';
            return new List<RegisterResult>{ r };
        }
        if (!isLikelyEmail(normalizedEmail)) {
            r.message = 'Email does not look like a valid address (e.g. jane.doe@example.com).';
            return new List<RegisterResult>{ r };
        }
        if (req.consentToContact != true) {
            r.message = 'Patient must consent to contact before we create a chart. Please confirm consent and retry.';
            return new List<RegisterResult>{ r };
        }

        Id existing = OncoPatientEmailLookup.findPersonAccountIdByEmail(normalizedEmail);
        if (existing != null) {
            Account a = [SELECT FirstName, LastName, PersonEmail FROM Account WHERE Id = :existing LIMIT 1];
            r.success = true;
            r.wasAlreadyRegistered = true;
            r.patientDisplayName = displayName(a.FirstName, a.LastName);
            r.registeredEmail = a.PersonEmail;
            r.message = 'A chart already exists for ' + r.patientDisplayName
                + ' at ' + r.registeredEmail + '. You can go ahead and book.';
            return new List<RegisterResult>{ r };
        }

        Id rtId;
        try {
            rtId = Schema.SObjectType.Account
                .getRecordTypeInfosByDeveloperName()
                .get(PERSON_ACCOUNT_RT)
                .getRecordTypeId();
        } catch (Exception e) {
            r.message = 'Person Account record type is not available in this org.';
            return new List<RegisterResult>{ r };
        }
        if (rtId == null) {
            r.message = 'Person Account record type is not available in this org.';
            return new List<RegisterResult>{ r };
        }

        Account acct = new Account(
            RecordTypeId = rtId,
            FirstName = first,
            LastName = last,
            PersonEmail = normalizedEmail
        );
        if (String.isNotBlank(phone)) acct.PersonMobilePhone = phone;
        Date dob = parseDateOrNull(req.dateOfBirth);
        if (dob != null) acct.PersonBirthdate = dob;
        // city (PersonMailingCity) is not written here: compound address fields are not
        // exposed via permission-set FLS in this org, and writing them would trip the
        // Agent user's FLS. Keep the input so we can wire it up when an Account-address
        // field perm becomes deployable.

        try {
            insert acct;
        } catch (DmlException e) {
            r.message = 'Could not register the patient: ' + e.getDmlMessage(0);
            return new List<RegisterResult>{ r };
        }

        r.success = true;
        r.wasAlreadyRegistered = false;
        r.patientDisplayName = displayName(first, last);
        r.registeredEmail = normalizedEmail;
        r.message = 'Registered ' + r.patientDisplayName + ' at ' + r.registeredEmail
            + '. You can now book an appointment with this email.';
        sendWelcomeEmailSafe(first, last, normalizedEmail);
        return new List<RegisterResult>{ r };
    }

    /**
     * Fire-and-forget welcome email so an email failure can never roll back
     * the just-created Person Account.
     */
    @TestVisible
    private static void sendWelcomeEmailSafe(String first, String last, String email) {
        if (String.isBlank(email)) {
            return;
        }
        try {
            OncoEmailService.EmailContext ctx = new OncoEmailService.EmailContext();
            ctx.patientFirstName = first;
            ctx.patientLastName = last;
            ctx.patientEmail = email;
            OncoEmailService.sendPatientWelcome(ctx);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'OncoPatientRegister welcome email skipped: ' + e.getMessage());
        }
    }

    @TestVisible
    private static String normalize(String raw) {
        if (String.isBlank(raw)) return null;
        String s = raw.trim().toLowerCase();
        return s;
    }

    @TestVisible
    private static String trimOrNull(String raw) {
        if (raw == null) return null;
        String s = raw.trim();
        return s.length() == 0 ? null : s;
    }

    @TestVisible
    private static Boolean isLikelyEmail(String s) {
        if (String.isBlank(s)) return false;
        return Pattern.matches('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}', s);
    }

    @TestVisible
    private static Date parseDateOrNull(String s) {
        if (String.isBlank(s)) return null;
        try {
            return Date.valueOf(s.trim());
        } catch (Exception e) {
            return null;
        }
    }

    @TestVisible
    private static String displayName(String first, String last) {
        String f = first == null ? '' : first.trim();
        String l = last  == null ? '' : last.trim();
        if (f.length() == 0) return l;
        if (l.length() == 0) return f;
        return f + ' ' + l;
    }
}

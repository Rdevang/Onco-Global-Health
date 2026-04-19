/**
 * Resolves the running Experience Cloud / community user to a patient Account (Person or business patient).
 * Used by flows and Agentforce actions that need "current patient" context.
 */
public with sharing class OncoPatientContext {
    public class PatientContextResult {
        @InvocableVariable(label='Patient Account Id')
        public Id accountId;
        @InvocableVariable(label='Patient Contact Id')
        public Id contactId;
        @InvocableVariable(label='Email')
        public String email;
        @InvocableVariable(label='Is Person Account')
        public Boolean isPersonAccount;
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    public class PatientContextRequest {
        @InvocableVariable(label='Invoke')
        public Boolean invoke;
    }

    @InvocableMethod(
        label='Get Current Patient Context'
        description='Returns Account and Contact for the running user (Experience Cloud patient).'
        category='Onco'
    )
    public static List<PatientContextResult> getCurrentPatientContext(List<PatientContextRequest> requests) {
        PatientContextResult out = new PatientContextResult();
        try {
            Id uid = UserInfo.getUserId();
            User u = [
                SELECT ContactId, Contact.AccountId, Contact.Email, Contact.Account.IsPersonAccount, Contact.Account.PersonEmail
                FROM User
                WHERE Id = :uid
                LIMIT 1
            ];
            if (u.ContactId == null) {
                out.errorMessage = 'No Contact on User — not a community patient user.';
                return new List<PatientContextResult>{ out };
            }
            out.contactId = u.ContactId;
            out.accountId = u.Contact.AccountId;
            out.isPersonAccount = u.Contact.Account.IsPersonAccount;
            if (u.Contact.Account.IsPersonAccount == true && u.Contact.Account.PersonEmail != null) {
                out.email = u.Contact.Account.PersonEmail;
            } else {
                out.email = u.Contact.Email;
            }
            return new List<PatientContextResult>{ out };
        } catch (Exception e) {
            out.errorMessage = e.getMessage();
            return new List<PatientContextResult>{ out };
        }
    }
}
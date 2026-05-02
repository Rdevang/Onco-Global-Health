/**
 * Centralized transactional email service for Onco patient journeys.
 *
 * Sends plain-text + HTML emails for the following events:
 *   - Patient registration (welcome)
 *   - Appointment booking confirmation
 *   - Appointment reschedule notification
 *   - Appointment cancellation notification
 *   - Pre-appointment reminders (1 day prior, 4 hours prior)
 *
 * Failures are swallowed and logged; email is fire-and-forget so a delivery
 * problem never blocks the underlying scheduling/registration transaction.
 *
 * Org configuration prerequisites:
 *   - Email deliverability set to "All email" (Setup -> Email -> Deliverability)
 *   - Optional: configure an Org-Wide Email Address with display name
 *     "Onco Care Team" and the running user's profile granted access; if
 *     present it is used automatically.
 */
public without sharing class OncoEmailService {

    /** Org-Wide Email display name used as the from-address when available. */
    @TestVisible
    private static final String OWA_DISPLAY_NAME = 'Onco Care Team';

    /** Default reply-to subject prefix for all Onco emails. */
    @TestVisible
    private static final String SUBJECT_PREFIX = '[Onco Care] ';

    public enum EventType {
        PATIENT_WELCOME,
        APPOINTMENT_BOOKED,
        APPOINTMENT_RESCHEDULED,
        APPOINTMENT_CANCELED,
        REMINDER_24H,
        REMINDER_4H
    }

    /** Lightweight context for transactional sends. Any field may be null. */
    public class EmailContext {
        public String patientFirstName;
        public String patientLastName;
        public String patientEmail;
        public String appointmentNumber;
        public Datetime appointmentStartUtc;
        public String appointmentTimeZone;
        public String facilityName;
        public String providerName;
    }

    /**
     * Send a welcome email to a newly registered patient.
     * Returns true when Salesforce accepted the message for delivery.
     */
    public static Boolean sendPatientWelcome(EmailContext ctx) {
        if (ctx == null || String.isBlank(ctx.patientEmail)) {
            return false;
        }
        String subject = SUBJECT_PREFIX + 'Welcome to Onco Care';
        String greeting = greetingFor(ctx);
        String plain =
            greeting + '\n\n' +
            'Thank you for registering with Onco Care. Your patient chart has been created and you can now book appointments using ' + ctx.patientEmail + '.\n\n' +
            'If you did not initiate this registration, please reply to this email and we will remove the record.\n\n' +
            'Warm regards,\nOnco Care Team';
        String html =
            '<p>' + escape(greeting) + '</p>' +
            '<p>Thank you for registering with <strong>Onco Care</strong>. Your patient chart has been created and you can now book appointments using <strong>' + escape(ctx.patientEmail) + '</strong>.</p>' +
            '<p>If you did not initiate this registration, please reply to this email and we will remove the record.</p>' +
            '<p>Warm regards,<br/>Onco Care Team</p>';
        return sendSingle(ctx.patientEmail, subject, plain, html);
    }

    /** Confirmation email after a patient successfully books an appointment. */
    public static Boolean sendBookingConfirmation(EmailContext ctx) {
        return sendAppointmentEmail(ctx, EventType.APPOINTMENT_BOOKED);
    }

    /** Notification email after an appointment is rescheduled. */
    public static Boolean sendRescheduleNotice(EmailContext ctx) {
        return sendAppointmentEmail(ctx, EventType.APPOINTMENT_RESCHEDULED);
    }

    /** Notification email after an appointment is canceled. */
    public static Boolean sendCancellationNotice(EmailContext ctx) {
        return sendAppointmentEmail(ctx, EventType.APPOINTMENT_CANCELED);
    }

    /** 1-day-prior reminder. */
    public static Boolean sendReminder24h(EmailContext ctx) {
        return sendAppointmentEmail(ctx, EventType.REMINDER_24H);
    }

    /** 4-hour-prior reminder. */
    public static Boolean sendReminder4h(EmailContext ctx) {
        return sendAppointmentEmail(ctx, EventType.REMINDER_4H);
    }

    /**
     * Build the patient EmailContext for a list of ServiceAppointment Ids by
     * joining ServiceAppointment -> Account (Person) -> AssignedResource ->
     * ServiceResource. Used by the reminder scheduler.
     */
    public static Map<Id, EmailContext> buildContextsForAppointments(Set<Id> appointmentIds) {
        Map<Id, EmailContext> out = new Map<Id, EmailContext>();
        if (appointmentIds == null || appointmentIds.isEmpty()) {
            return out;
        }
        Map<Id, ServiceAppointment> sas = new Map<Id, ServiceAppointment>([
            SELECT Id, AppointmentNumber, SchedStartTime, TimeZone,
                   ParentRecordId, ServiceTerritoryId,
                   ServiceTerritory.Name
            FROM ServiceAppointment
            WHERE Id IN :appointmentIds
        ]);
        Set<Id> acctIds = new Set<Id>();
        for (ServiceAppointment sa : sas.values()) {
            if (sa.ParentRecordId != null) {
                acctIds.add(sa.ParentRecordId);
            }
        }
        Map<Id, Account> acctById = new Map<Id, Account>();
        if (!acctIds.isEmpty()) {
            acctById = new Map<Id, Account>([
                SELECT Id, FirstName, LastName, PersonEmail
                FROM Account
                WHERE Id IN :acctIds
            ]);
        }
        Map<Id, String> resourceNameByAppt = new Map<Id, String>();
        for (AssignedResource ar : [
            SELECT ServiceAppointmentId, ServiceResource.Name
            FROM AssignedResource
            WHERE ServiceAppointmentId IN :appointmentIds
        ]) {
            if (!resourceNameByAppt.containsKey(ar.ServiceAppointmentId)) {
                resourceNameByAppt.put(ar.ServiceAppointmentId, ar.ServiceResource != null ? ar.ServiceResource.Name : null);
            }
        }
        for (ServiceAppointment sa : sas.values()) {
            EmailContext ctx = new EmailContext();
            Account a = sa.ParentRecordId != null ? acctById.get(sa.ParentRecordId) : null;
            if (a != null) {
                ctx.patientFirstName = a.FirstName;
                ctx.patientLastName = a.LastName;
                ctx.patientEmail = a.PersonEmail;
            }
            ctx.appointmentNumber = sa.AppointmentNumber;
            ctx.appointmentStartUtc = sa.SchedStartTime;
            ctx.appointmentTimeZone = sa.TimeZone;
            ctx.facilityName = sa.ServiceTerritory != null ? sa.ServiceTerritory.Name : null;
            ctx.providerName = resourceNameByAppt.get(sa.Id);
            out.put(sa.Id, ctx);
        }
        return out;
    }

    private static Boolean sendAppointmentEmail(EmailContext ctx, EventType evt) {
        if (ctx == null || String.isBlank(ctx.patientEmail)) {
            return false;
        }
        String whenLabel = formatWhen(ctx.appointmentStartUtc, ctx.appointmentTimeZone);
        String greeting = greetingFor(ctx);
        String apptNum = String.isNotBlank(ctx.appointmentNumber) ? ctx.appointmentNumber : 'N/A';
        String facility = String.isNotBlank(ctx.facilityName) ? ctx.facilityName : 'your selected facility';
        String provider = String.isNotBlank(ctx.providerName) ? ctx.providerName : 'your provider';

        String subject;
        String headline;
        String body;
        switch on evt {
            when APPOINTMENT_BOOKED {
                subject = SUBJECT_PREFIX + 'Appointment Confirmed - ' + apptNum;
                headline = 'Your appointment is confirmed.';
                body = 'We have booked your consultation with ' + provider + ' at ' + facility + ' on ' + whenLabel + '. '
                     + 'You will receive a reminder one day before and another four hours before the visit.';
            }
            when APPOINTMENT_RESCHEDULED {
                subject = SUBJECT_PREFIX + 'Appointment Rescheduled - ' + apptNum;
                headline = 'Your appointment has been rescheduled.';
                body = 'Your consultation with ' + provider + ' at ' + facility + ' is now scheduled for ' + whenLabel + '. '
                     + 'Reminders will follow one day before and four hours before the new time.';
            }
            when APPOINTMENT_CANCELED {
                subject = SUBJECT_PREFIX + 'Appointment Canceled - ' + apptNum;
                headline = 'Your appointment has been canceled.';
                body = 'Your consultation with ' + provider + ' at ' + facility + ' on ' + whenLabel + ' has been canceled. '
                     + 'Reply to this email or contact us to rebook whenever you are ready.';
            }
            when REMINDER_24H {
                subject = SUBJECT_PREFIX + 'Reminder: Appointment Tomorrow - ' + apptNum;
                headline = 'This is a friendly reminder about your appointment tomorrow.';
                body = 'Your consultation with ' + provider + ' at ' + facility + ' is scheduled for ' + whenLabel + '. '
                     + 'Please arrive 15 minutes early and bring any prior reports.';
            }
            when REMINDER_4H {
                subject = SUBJECT_PREFIX + 'Reminder: Appointment in ~4 hours - ' + apptNum;
                headline = 'Your appointment is coming up in about four hours.';
                body = 'Your consultation with ' + provider + ' at ' + facility + ' is at ' + whenLabel + '. '
                     + 'If you need to reschedule or cancel, please reply to this email as soon as possible.';
            }
            when else {
                subject = SUBJECT_PREFIX + 'Appointment Update - ' + apptNum;
                headline = 'There is an update regarding your appointment.';
                body = 'Your consultation with ' + provider + ' at ' + facility + ' on ' + whenLabel + ' has been updated.';
            }
        }

        String plain =
            greeting + '\n\n' +
            headline + '\n\n' +
            body + '\n\n' +
            'Appointment number: ' + apptNum + '\n' +
            'When: ' + whenLabel + '\n' +
            'Provider: ' + provider + '\n' +
            'Facility: ' + facility + '\n\n' +
            'Warm regards,\nOnco Care Team';

        String html =
            '<p>' + escape(greeting) + '</p>' +
            '<p><strong>' + escape(headline) + '</strong></p>' +
            '<p>' + escape(body) + '</p>' +
            '<table style="border-collapse:collapse;">' +
            '<tr><td><strong>Appointment number</strong></td><td>&nbsp;' + escape(apptNum) + '</td></tr>' +
            '<tr><td><strong>When</strong></td><td>&nbsp;' + escape(whenLabel) + '</td></tr>' +
            '<tr><td><strong>Provider</strong></td><td>&nbsp;' + escape(provider) + '</td></tr>' +
            '<tr><td><strong>Facility</strong></td><td>&nbsp;' + escape(facility) + '</td></tr>' +
            '</table>' +
            '<p>Warm regards,<br/>Onco Care Team</p>';

        return sendSingle(ctx.patientEmail, subject, plain, html);
    }

    /**
     * Low-level send. Returns true if Salesforce accepted the message.
     * Catches and logs any exception so callers do not have to.
     */
    @TestVisible
    private static Boolean sendSingle(String toAddress, String subject, String plain, String html) {
        if (String.isBlank(toAddress)) {
            return false;
        }
        try {
            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setToAddresses(new List<String>{ toAddress });
            msg.setSubject(subject);
            msg.setPlainTextBody(plain);
            msg.setHtmlBody(html);
            msg.setSaveAsActivity(false);
            Id owaId = getOrgWideEmailAddressId();
            if (owaId != null) {
                msg.setOrgWideEmailAddressId(owaId);
            }
            Messaging.SendEmailResult[] results = Messaging.sendEmail(
                new Messaging.SingleEmailMessage[]{ msg },
                false
            );
            if (results == null || results.isEmpty()) {
                return false;
            }
            Boolean ok = results[0].isSuccess();
            if (!ok) {
                System.debug(LoggingLevel.WARN, 'OncoEmailService send failed: ' + results[0].getErrors());
            }
            return ok;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'OncoEmailService send exception: ' + e.getMessage());
            return false;
        }
    }

    @TestVisible
    private static Id cachedOwaId;
    @TestVisible
    private static Boolean owaResolved = false;

    @TestVisible
    private static Id getOrgWideEmailAddressId() {
        if (owaResolved) {
            return cachedOwaId;
        }
        owaResolved = true;
        try {
            List<OrgWideEmailAddress> rows = [
                SELECT Id FROM OrgWideEmailAddress
                WHERE DisplayName = :OWA_DISPLAY_NAME
                LIMIT 1
            ];
            cachedOwaId = rows.isEmpty() ? null : rows[0].Id;
        } catch (Exception e) {
            cachedOwaId = null;
        }
        return cachedOwaId;
    }

    @TestVisible
    private static String greetingFor(EmailContext ctx) {
        String first = ctx == null ? null : ctx.patientFirstName;
        if (String.isBlank(first)) {
            return 'Hello,';
        }
        return 'Hello ' + first.trim() + ',';
    }

    @TestVisible
    private static String formatWhen(Datetime startUtc, String timeZoneId) {
        if (startUtc == null) {
            return 'the scheduled time';
        }
        String tz = String.isNotBlank(timeZoneId) ? timeZoneId : 'GMT';
        try {
            return startUtc.format('EEEE, MMM d, yyyy h:mm a z', tz);
        } catch (Exception e) {
            return startUtc.formatGmt('yyyy-MM-dd HH:mm') + ' UTC';
        }
    }

    @TestVisible
    private static String escape(String s) {
        if (s == null) {
            return '';
        }
        return s
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;')
            .replace('\'', '&#39;');
    }
}

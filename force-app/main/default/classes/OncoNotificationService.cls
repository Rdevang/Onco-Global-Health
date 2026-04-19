/**
 * Placeholder for Digital Engagement (WhatsApp / SMS). Wire Messaging API in Phase 07.
 */
public with sharing class OncoNotificationService {
    public class NotifyRequest {
        @InvocableVariable(label='Service Appointment Id')
        public String serviceAppointmentId;
        @InvocableVariable(label='Channel')
        public String channel;
        @InvocableVariable(label='Template Developer Name')
        public String templateDeveloperName;
    }

    public class NotifyResult {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }

    @InvocableMethod(
        label='Send Appointment Notification (stub)'
        description='Reserved for WhatsApp/SMS; returns guidance until Messaging is configured.'
        category='Onco'
    )
    public static List<NotifyResult> sendReminder(List<NotifyRequest> requests) {
        NotifyResult r = new NotifyResult();
        r.success = false;
        r.message = 'Outbound WhatsApp/SMS not configured. Complete Digital Engagement setup (Phase 07).';
        return new List<NotifyResult>{ r };
    }
}
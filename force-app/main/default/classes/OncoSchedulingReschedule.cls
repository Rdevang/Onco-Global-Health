public without sharing class OncoSchedulingReschedule {
    public class RescheduleRequest {
        @InvocableVariable(required=true label='Service Appointment Id')
        public String serviceAppointmentId;
        @InvocableVariable(required=true label='Patient Account Id')
        public String patientAccountId;
        @InvocableVariable(required=true label='New Start Time (UTC)')
        public Datetime newStartTimeUtc;
    }

    public class MutationResult {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String serviceAppointmentId;
        @InvocableVariable public String message;
    }

    @InvocableMethod(
        label='Reschedule Appointment'
        description='Moves SchedStartTime for a patient-owned appointment.'
        category='Onco'
    )
    public static List<MutationResult> rescheduleAppointment(List<RescheduleRequest> requests) {
        MutationResult r = new MutationResult();
        if (requests == null || requests.isEmpty()) {
            r.success = false;
            r.message = 'No request';
            return new List<MutationResult>{ r };
        }
        RescheduleRequest req = requests[0];
        try {
            ServiceAppointment sa = [
                SELECT Id, ParentRecordId, WorkTypeId
                FROM ServiceAppointment
                WHERE Id = :req.serviceAppointmentId
                LIMIT 1
            ];
            if (sa.ParentRecordId != req.patientAccountId) {
                r.success = false;
                r.message = 'Appointment does not belong to patient.';
                return new List<MutationResult>{ r };
            }
            Decimal durDec = OncoSchedulerGateway.getWorkTypeDurationMinutes(sa.WorkTypeId);
            Integer dur = durDec.intValue();
            sa.SchedStartTime = req.newStartTimeUtc;
            sa.SchedEndTime = req.newStartTimeUtc.addMinutes(dur);
            sa.EarliestStartTime = req.newStartTimeUtc.addHours(-2);
            sa.DueDate = req.newStartTimeUtc.addHours(2);
            update sa;
            // Reset reminder flags so the patient receives fresh 24h / 4h
            // reminders relative to the new SchedStartTime.
            try {
                update new ServiceAppointment(
                    Id = sa.Id,
                    Reminder_24h_Sent__c = false,
                    Reminder_4h_Sent__c = false
                );
            } catch (Exception ignore) {
                System.debug(LoggingLevel.WARN, 'Could not reset reminder flags: ' + ignore.getMessage());
            }
            r.success = true;
            r.serviceAppointmentId = sa.Id;
            r.message = 'Rescheduled.';
            sendRescheduleEmailSafe(sa.Id);
            return new List<MutationResult>{ r };
        } catch (Exception e) {
            r.success = false;
            r.message = e.getMessage();
            return new List<MutationResult>{ r };
        }
    }

    @TestVisible
    private static void sendRescheduleEmailSafe(Id appointmentId) {
        if (appointmentId == null) {
            return;
        }
        try {
            Map<Id, OncoEmailService.EmailContext> ctxMap =
                OncoEmailService.buildContextsForAppointments(new Set<Id>{ appointmentId });
            OncoEmailService.EmailContext ctx = ctxMap.get(appointmentId);
            if (ctx != null && String.isNotBlank(ctx.patientEmail)) {
                OncoEmailService.sendRescheduleNotice(ctx);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'OncoSchedulingReschedule email skipped: ' + e.getMessage());
        }
    }
}
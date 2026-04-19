public with sharing class OncoSchedulingReschedule {
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
            r.success = true;
            r.serviceAppointmentId = sa.Id;
            r.message = 'Rescheduled.';
            return new List<MutationResult>{ r };
        } catch (Exception e) {
            r.success = false;
            r.message = e.getMessage();
            return new List<MutationResult>{ r };
        }
    }
}
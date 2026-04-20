public without sharing class OncoSchedulingCancel {
    public class CancelRequest {
        @InvocableVariable(required=true label='Service Appointment Id')
        public String serviceAppointmentId;
        @InvocableVariable(required=true label='Patient Account Id')
        public String patientAccountId;
    }

    public class MutationResult {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String serviceAppointmentId;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Cancel Appointment' description='Sets status to Canceled.' category='Onco')
    public static List<MutationResult> cancelAppointment(List<CancelRequest> requests) {
        MutationResult r = new MutationResult();
        if (requests == null || requests.isEmpty()) {
            r.success = false;
            r.message = 'No request';
            return new List<MutationResult>{ r };
        }
        CancelRequest req = requests[0];
        try {
            ServiceAppointment sa = [SELECT Id, ParentRecordId FROM ServiceAppointment WHERE Id = :req.serviceAppointmentId LIMIT 1];
            if (sa.ParentRecordId != req.patientAccountId) {
                r.success = false;
                r.message = 'Appointment does not belong to patient.';
                return new List<MutationResult>{ r };
            }
            sa.Status = 'Canceled';
            update sa;
            r.success = true;
            r.serviceAppointmentId = sa.Id;
            r.message = 'Canceled.';
            return new List<MutationResult>{ r };
        } catch (Exception e) {
            r.success = false;
            r.message = e.getMessage();
            return new List<MutationResult>{ r };
        }
    }
}
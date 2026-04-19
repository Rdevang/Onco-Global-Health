/**
 * Facade for Agentforce local action "Manage Appointment" (single invocable matching planner schema).
 * Delegates to Phase 04 OncoSchedulingCancel / OncoSchedulingReschedule.
 */
public with sharing class OncoAppointmentManager {
    public class ManageRequest {
        @InvocableVariable(label = 'Action Type' description = 'Use Cancel or Reschedule.')
        public String actionType;
        @InvocableVariable(required = true label = 'Appointment ID' description = 'Service Appointment Id.')
        public String appointmentId;
        @InvocableVariable(label = 'New Start Time' description = 'ISO 8601 date/time for Reschedule; omit for Cancel.')
        public String newStartTime;
    }

    public class ManageResult {
        @InvocableVariable public Boolean isSuccess;
        @InvocableVariable public String message;
    }

    @InvocableMethod(
        label = 'Manage Appointment'
        description = 'Cancel or reschedule an existing Service Appointment.'
        category = 'Onco'
    )
    public static List<ManageResult> manageAppointment(List<ManageRequest> requests) {
        ManageResult out = new ManageResult();
        out.isSuccess = false;
        out.message = 'No request';
        if (requests == null || requests.isEmpty()) {
            return new List<ManageResult>{ out };
        }
        ManageRequest req = requests[0];
        if (String.isBlank(req.appointmentId)) {
            out.message = 'Appointment Id is required.';
            return new List<ManageResult>{ out };
        }
        String action = req.actionType != null ? req.actionType.trim().toLowerCase() : '';
        ServiceAppointment sa;
        try {
            sa = [
                SELECT Id, ParentRecordId
                FROM ServiceAppointment
                WHERE Id = :req.appointmentId
                LIMIT 1
            ];
        } catch (Exception e) {
            out.message = 'Appointment not found.';
            return new List<ManageResult>{ out };
        }
        String patientAccountId = sa.ParentRecordId != null ? String.valueOf(sa.ParentRecordId) : null;
        if (String.isBlank(patientAccountId)) {
            out.message = 'Appointment has no patient account.';
            return new List<ManageResult>{ out };
        }

        if (action.contains('cancel')) {
            OncoSchedulingCancel.CancelRequest cr = new OncoSchedulingCancel.CancelRequest();
            cr.serviceAppointmentId = req.appointmentId;
            cr.patientAccountId = patientAccountId;
            List<OncoSchedulingCancel.MutationResult> rows = OncoSchedulingCancel.cancelAppointment(
                new List<OncoSchedulingCancel.CancelRequest>{ cr }
            );
            if (rows != null && !rows.isEmpty()) {
                out.isSuccess = rows[0].success == true;
                out.message = rows[0].message;
            }
            return new List<ManageResult>{ out };
        }
        if (action.contains('reschedule')) {
            if (String.isBlank(req.newStartTime)) {
                out.message = 'New start time is required for reschedule.';
                return new List<ManageResult>{ out };
            }
            Datetime newStart = parseDateTime(req.newStartTime);
            if (newStart == null) {
                out.message = 'Could not parse new start time. Use ISO 8601 (e.g. 2026-05-15T14:30:00.000Z).';
                return new List<ManageResult>{ out };
            }
            OncoSchedulingReschedule.RescheduleRequest rr = new OncoSchedulingReschedule.RescheduleRequest();
            rr.serviceAppointmentId = req.appointmentId;
            rr.patientAccountId = patientAccountId;
            rr.newStartTimeUtc = newStart;
            List<OncoSchedulingReschedule.MutationResult> rows = OncoSchedulingReschedule.rescheduleAppointment(
                new List<OncoSchedulingReschedule.RescheduleRequest>{ rr }
            );
            if (rows != null && !rows.isEmpty()) {
                out.isSuccess = rows[0].success == true;
                out.message = rows[0].message;
            }
            return new List<ManageResult>{ out };
        }
        out.message = 'Action type must be Cancel or Reschedule.';
        return new List<ManageResult>{ out };
    }

    private static Datetime parseDateTime(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        String s = raw.trim();
        if (s.endsWithIgnoreCase('z')) {
            s = s.substring(0, s.length() - 1).trim();
        }
        s = s.replace('T', ' ');
        if (s.length() >= 19) {
            try {
                return Datetime.valueOfGmt(s.substring(0, 19));
            } catch (Exception e) {
                return null;
            }
        }
        return null;
    }
}

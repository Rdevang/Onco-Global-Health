/**
 * Text output for Agentforce planner; wraps OncoSchedulingListAppointments.getMyAppointments.
 */
public without sharing class OncoListAppointmentsAgent {
    public class AgentRequest {
        @InvocableVariable(
            required = true
            label = 'Patient lookup email'
            description = 'Plain email for the patient; no Account Id from the user.'
        )
        public String patientLookupEmail;
        @InvocableVariable(label = 'Include Past' description = 'Include completed/canceled past visits')
        public Boolean includePast;
    }

    public class AgentResult {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String appointmentsText;
        @InvocableVariable public String message;
    }

    @InvocableMethod(
        label = 'List My Appointments'
        description = 'Lists ServiceAppointments for the patient identified by email only.'
        category = 'Onco'
    )
    public static List<AgentResult> listAppointmentsForAgent(List<AgentRequest> requests) {
        AgentResult r = new AgentResult();
        r.success = false;
        r.appointmentsText = '';
        r.message = '';
        if (requests == null || requests.isEmpty()) {
            r.message = 'No request';
            return new List<AgentResult>{ r };
        }
        try {
            OncoSchedulingListAppointments.ListApptsRequest req = new OncoSchedulingListAppointments.ListApptsRequest();
            req.patientLookupEmail = requests[0].patientLookupEmail;
            req.includePast = requests[0].includePast;
            List<List<OncoSchedulingListAppointments.AppointmentRow>> wrapped = OncoSchedulingListAppointments.getMyAppointments(
                new List<OncoSchedulingListAppointments.ListApptsRequest>{ req }
            );
            List<OncoSchedulingListAppointments.AppointmentRow> rows = wrapped != null && !wrapped.isEmpty()
                ? wrapped[0]
                : new List<OncoSchedulingListAppointments.AppointmentRow>();
            List<String> lines = new List<String>();
            for (OncoSchedulingListAppointments.AppointmentRow row : rows) {
                if (row == null) {
                    continue;
                }
                String refLabel = String.isNotBlank(row.appointmentNumber)
                    ? row.appointmentNumber
                    : 'Visit';
                lines.add(
                    '- ' +
                        refLabel +
                        ' | Start: ' +
                        (row.startTime != null ? String.valueOf(row.startTime) : '') +
                        ' | Status: ' +
                        (String.isNotBlank(row.status) ? row.status : '') +
                        ' | Visit type: ' +
                        (String.isNotBlank(row.workTypeName) ? row.workTypeName : '') +
                        (String.isNotBlank(row.territoryName) ? ' | Location: ' + row.territoryName : '')
                );
            }
            r.appointmentsText = String.join(lines, '\n');
            r.success = true;
            r.message = rows.isEmpty() ? 'No appointments found.' : 'Found ' + rows.size() + ' appointment(s).';
            return new List<AgentResult>{ r };
        } catch (Exception e) {
            r.message = e.getMessage();
            return new List<AgentResult>{ r };
        }
    }
}

/**
 * Text output for Agentforce planner; wraps OncoSchedulingGetSlots.getAvailableSlots.
 * Defaults: from = now UTC, to = now + 14 days UTC, timezone Asia/Kolkata for slot labels.
 */
public with sharing class OncoSchedulingSlotsAgent {
    private static final String DEFAULT_WORK_TYPE_NAME = 'Onco New Consult';

    public class AgentRequest {
        @InvocableVariable(required = true label = 'Healthcare Facility Id' description = 'HealthcareFacility Id from Find Facilities.')
        public String healthcareFacilityId;
        @InvocableVariable(required = true label = 'Healthcare Provider Id' description = 'HealthcareProvider Id from Find Providers.')
        public String healthcareProviderId;
        @InvocableVariable(
            label = 'Work Type Id'
            description = 'WorkType Id; omit to use Onco New Consult when present in the org.'
        )
        public String workTypeId;
        @InvocableVariable(label = 'From Time UTC' description = 'ISO 8601 start of search window; omit for now.')
        public String fromTimeUtc;
        @InvocableVariable(label = 'To Time UTC' description = 'ISO 8601 end of search window; omit for now + 14 days.')
        public String toTimeUtc;
        @InvocableVariable(label = 'Timezone' description = 'IANA id for slot generation, default Asia/Kolkata.')
        public String timezoneId;
    }

    public class AgentResult {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String slotsText;
        @InvocableVariable public String message;
    }

    @InvocableMethod(
        label = 'Get Available Appointment Slots'
        description = 'Returns candidate booking times for a facility, provider, and work type.'
        category = 'Onco'
    )
    public static List<AgentResult> getSlotsForAgent(List<AgentRequest> requests) {
        AgentResult r = new AgentResult();
        r.success = false;
        r.slotsText = '';
        r.message = '';
        if (requests == null || requests.isEmpty()) {
            r.message = 'No request';
            return new List<AgentResult>{ r };
        }
        AgentRequest ar = requests[0];
        String wtId = ar.workTypeId;
        if (String.isBlank(wtId)) {
            List<WorkType> wts = [
                SELECT Id
                FROM WorkType
                WHERE Name = :DEFAULT_WORK_TYPE_NAME
                LIMIT 1
            ];
            if (!wts.isEmpty()) {
                wtId = wts[0].Id;
            }
        }
        if (String.isBlank(ar.healthcareFacilityId) || String.isBlank(ar.healthcareProviderId) || String.isBlank(wtId)) {
            r.message = 'Facility Id and Provider Id are required; Work Type Id is required unless Onco New Consult exists.';
            return new List<AgentResult>{ r };
        }
        try {
            Datetime fromUtc = parseDt(ar.fromTimeUtc);
            Datetime toUtc = parseDt(ar.toTimeUtc);
            if (fromUtc == null) {
                fromUtc = System.now();
            }
            if (toUtc == null) {
                toUtc = fromUtc.addDays(14);
            }
            OncoSchedulingGetSlots.GetSlotsRequest req = new OncoSchedulingGetSlots.GetSlotsRequest();
            req.healthcareFacilityId = ar.healthcareFacilityId;
            req.healthcareProviderId = ar.healthcareProviderId;
            req.workTypeId = wtId;
            req.fromTimeUtc = fromUtc;
            req.toTimeUtc = toUtc;
            req.timezoneId = String.isNotBlank(ar.timezoneId) ? ar.timezoneId : 'Asia/Kolkata';
            List<List<OncoSchedulingGetSlots.SlotResult>> wrapped = OncoSchedulingGetSlots.getAvailableSlots(
                new List<OncoSchedulingGetSlots.GetSlotsRequest>{ req }
            );
            List<OncoSchedulingGetSlots.SlotResult> rows = wrapped != null && !wrapped.isEmpty()
                ? wrapped[0]
                : new List<OncoSchedulingGetSlots.SlotResult>();
            List<String> lines = new List<String>();
            for (OncoSchedulingGetSlots.SlotResult row : rows) {
                if (row == null) {
                    continue;
                }
                if (String.isNotBlank(row.message) && row.startTime == null) {
                    lines.add('Note: ' + row.message);
                    continue;
                }
                if (row.startTime != null) {
                    lines.add(
                        '- Start (UTC): ' +
                            String.valueOf(row.startTime) +
                            ' | End (UTC): ' +
                            (row.endTime != null ? String.valueOf(row.endTime) : '') +
                            ' | ' +
                            (String.isNotBlank(row.providerName) ? row.providerName : '')
                    );
                }
            }
            r.slotsText = String.join(lines, '\n');
            r.success = true;
            r.message = rows.isEmpty() ? 'No slots returned.' : 'Slot candidates listed.';
            return new List<AgentResult>{ r };
        } catch (Exception e) {
            r.message = e.getMessage();
            return new List<AgentResult>{ r };
        }
    }

    private static Datetime parseDt(String raw) {
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

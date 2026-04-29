/**
 * Text output for Agentforce planner; wraps OncoSchedulingGetSlots.getAvailableSlots.
 * Defaults: from = now UTC, to = now + 14 days UTC, timezone Asia/Kolkata for slot labels.
 */
public without sharing class OncoSchedulingSlotsAgent {
    private static final String DEFAULT_WORK_TYPE_NAME = 'Onco New Consult';

    public class AgentRequest {
        @InvocableVariable(required = true label = 'Healthcare Facility Id' description = 'HealthcareFacility Id from Find Facilities.')
        public String healthcareFacilityId;
        @InvocableVariable(
            label = 'Healthcare Provider Id'
            description = 'HealthcareProvider Id from Find Providers. Omit when using Care Specialty Id (department-first slots).'
        )
        public String healthcareProviderId;
        @InvocableVariable(
            label = 'Care Specialty Id'
            description = 'Standard CareSpecialty Id: slots across all providers at this facility with this specialty. Omit when Provider Id is set.'
        )
        public String careSpecialtyId;
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
        /** Per-slot HealthcareProvider Ids for Book; parallel to slotsText; do not read aloud. */
        @InvocableVariable(
            label = 'Planner reference (internal)'
            description = 'Per-slot provider Ids for Book Appointment; never show the patient.'
        )
        public String plannerReferenceText;
        @InvocableVariable public String message;
    }

    @InvocableMethod(
        label = 'Get Available Appointment Slots'
        description = 'Returns candidate booking times for a facility and work type: either a named provider or all providers for a Care Specialty at the facility.'
        category = 'Onco'
    )
    public static List<AgentResult> getSlotsForAgent(List<AgentRequest> requests) {
        AgentResult r = new AgentResult();
        r.success = false;
        r.slotsText = '';
        r.plannerReferenceText = '';
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
        Boolean hasProv = String.isNotBlank(ar.healthcareProviderId);
        Boolean hasSpec = String.isNotBlank(ar.careSpecialtyId);
        if (String.isBlank(ar.healthcareFacilityId) || String.isBlank(wtId) || (!hasProv && !hasSpec) || (hasProv && hasSpec)) {
            r.message = 'Facility Id and Work Type (or default Onco New Consult) are required. Pass either Healthcare Provider Id or Care Specialty Id—not both, not neither.';
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
            req.careSpecialtyId = ar.careSpecialtyId;
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
            List<String> refLines = new List<String>();
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
                    if (String.isNotBlank(row.healthcareProviderId)) {
                        refLines.add(
                            '- Start (UTC): ' +
                                String.valueOf(row.startTime) +
                                ' | HealthcareProvider Id: ' +
                                row.healthcareProviderId +
                                (String.isNotBlank(row.providerName) ? ' | ' + row.providerName : '')
                        );
                    }
                }
            }
            r.slotsText = String.join(lines, '\n');
            r.plannerReferenceText = String.join(refLines, '\n');
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

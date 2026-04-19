/**
 * Single-text output for Agentforce planner (avoids complex list output schemas).
 */
public with sharing class OncoDiscoveryFacilitiesAgent {
    public class AgentRequest {
        @InvocableVariable(label = 'City' description = 'City or region to filter (e.g. Mumbai). Leave blank to list facilities.')
        public String city;
    }

    public class AgentResult {
        @InvocableVariable public Boolean success;
        /** Patient-safe lines (name and city only). */
        @InvocableVariable public String facilitiesText;
        /**
         * Lines including HealthcareFacility Id for Get Slots / Book only.
         * Do not surface to the patient.
         */
        @InvocableVariable(
            label = 'Planner reference (internal)'
            description = 'Facility Id lines for tool calls only; never show the patient.'
        )
        public String plannerReferenceText;
        @InvocableVariable public String message;
    }

    @InvocableMethod(
        label = 'Find Cancer Care Facilities'
        description = 'Lists Onco Global HealthcareFacility locations; optional city filter.'
        category = 'Onco'
    )
    public static List<AgentResult> findFacilitiesForAgent(List<AgentRequest> requests) {
        AgentResult r = new AgentResult();
        r.success = false;
        r.facilitiesText = '';
        r.plannerReferenceText = '';
        r.message = '';
        if (requests == null || requests.isEmpty()) {
            r.message = 'No request';
            return new List<AgentResult>{ r };
        }
        try {
            OncoDiscoveryFacilities.FindFacilitiesRequest facReq = new OncoDiscoveryFacilities.FindFacilitiesRequest();
            facReq.city = requests[0].city;
            List<List<OncoDiscoveryFacilities.FacilityRow>> wrapped = OncoDiscoveryFacilities.findFacilities(
                new List<OncoDiscoveryFacilities.FindFacilitiesRequest>{ facReq }
            );
            List<OncoDiscoveryFacilities.FacilityRow> rows = wrapped != null && !wrapped.isEmpty()
                ? wrapped[0]
                : new List<OncoDiscoveryFacilities.FacilityRow>();
            List<String> displayLines = new List<String>();
            List<String> refLines = new List<String>();
            for (OncoDiscoveryFacilities.FacilityRow row : rows) {
                if (row == null) {
                    continue;
                }
                String label = String.isNotBlank(row.name) ? row.name : 'Facility';
                String city = String.isNotBlank(row.city) ? row.city : '';
                displayLines.add('- ' + label + ' | City: ' + city);
                refLines.add(
                    '- ' +
                        label +
                        ' | City: ' +
                        city +
                        ' | Facility Id: ' +
                        (row.facilityId != null ? String.valueOf(row.facilityId) : '')
                );
            }
            r.facilitiesText = String.join(displayLines, '\n');
            r.plannerReferenceText = String.join(refLines, '\n');
            r.success = true;
            r.message = rows.isEmpty() ? 'No facilities found for that filter.' : 'Found ' + rows.size() + ' facility row(s).';
            return new List<AgentResult>{ r };
        } catch (Exception e) {
            r.message = e.getMessage();
            return new List<AgentResult>{ r };
        }
    }
}

/**
 * Text output for Agentforce planner; wraps OncoDiscoverySpecialties.searchSpecialties.
 */
public with sharing class OncoDiscoverySpecialtiesAgent {
    public class AgentRequest {
        @InvocableVariable(label = 'Search Text' description = 'Filter specialty name; leave blank to list all.')
        public String searchText;

        @InvocableVariable(
            label = 'Healthcare Facility Id (optional)'
            description = 'Scope results to specialties actually staffed at this facility. Obtain from Find Cancer Care Facilities plannerReferenceText.'
        )
        public String healthcareFacilityId;

        @InvocableVariable(
            label = 'Facility Name (optional)'
            description = 'If no Id is available yet, a name substring (e.g. "HSR" or "Bengaluru Whitefield"). Only used when it resolves to exactly one facility; otherwise falls back to global catalog.'
        )
        public String facilityName;
    }

    public class AgentResult {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String specialtiesText;
        /** CareSpecialty Id lines for Get Slots (department-first); do not read aloud to the patient. */
        @InvocableVariable(
            label = 'Planner reference (internal)'
            description = 'CareSpecialty Ids for tool calls only; never show the patient.'
        )
        public String plannerReferenceText;
        @InvocableVariable public String message;
    }

    @InvocableMethod(
        label = 'Search Oncology Specialties'
        description = 'Lists CareSpecialty (standard) and HealthcareProviderTaxonomy names for browsing departments/specialties. Pass healthcareFacilityId or facilityName to scope results to the specialties actually staffed at that facility.'
        category = 'Onco'
    )
    public static List<AgentResult> searchSpecialtiesForAgent(List<AgentRequest> requests) {
        AgentResult r = new AgentResult();
        r.success = false;
        r.specialtiesText = '';
        r.plannerReferenceText = '';
        r.message = '';
        if (requests == null || requests.isEmpty()) {
            r.message = 'No request';
            return new List<AgentResult>{ r };
        }
        try {
            OncoDiscoverySpecialties.SearchSpecialtiesRequest req = new OncoDiscoverySpecialties.SearchSpecialtiesRequest();
            req.searchText = requests[0].searchText;
            req.healthcareFacilityId = requests[0].healthcareFacilityId;
            req.facilityName = requests[0].facilityName;
            List<List<OncoDiscoverySpecialties.SpecialtyRow>> wrapped = OncoDiscoverySpecialties.searchSpecialties(
                new List<OncoDiscoverySpecialties.SearchSpecialtiesRequest>{ req }
            );
            List<OncoDiscoverySpecialties.SpecialtyRow> rows = wrapped != null && !wrapped.isEmpty()
                ? wrapped[0]
                : new List<OncoDiscoverySpecialties.SpecialtyRow>();
            String scopedName = null;
            for (OncoDiscoverySpecialties.SpecialtyRow row : rows) {
                if (row != null && String.isNotBlank(row.scopedFacilityName)) {
                    scopedName = row.scopedFacilityName;
                    break;
                }
            }
            List<String> lines = new List<String>();
            List<String> refLines = new List<String>();
            for (OncoDiscoverySpecialties.SpecialtyRow row : rows) {
                if (row == null) {
                    continue;
                }
                String line = '- ' + (String.isNotBlank(row.name) ? row.name : 'Specialty');
                if (String.isNotBlank(row.specialtyType)) {
                    line += ' | Category: ' + row.specialtyType;
                }
                lines.add(line);
                if (String.isNotBlank(row.careSpecialtyId)) {
                    refLines.add(
                        '- ' +
                            (String.isNotBlank(row.name) ? row.name : 'CareSpecialty') +
                            ' | CareSpecialty Id: ' +
                            row.careSpecialtyId
                    );
                }
            }
            r.plannerReferenceText = String.join(refLines, '\n');
            r.specialtiesText = String.join(lines, '\n');
            r.success = true;
            Boolean scopedRequested = String.isNotBlank(requests[0].healthcareFacilityId)
                || String.isNotBlank(requests[0].facilityName);
            if (rows.isEmpty()) {
                r.message = scopedRequested
                    ? 'No active specialties are currently staffed at that facility.'
                    : 'No specialties found.';
            } else if (scopedName != null) {
                r.message = 'Found ' + rows.size() + ' specialty row(s) staffed at ' + scopedName + '.';
            } else {
                r.message = 'Found ' + rows.size() + ' specialty row(s).';
            }
            return new List<AgentResult>{ r };
        } catch (Exception e) {
            r.message = e.getMessage();
            return new List<AgentResult>{ r };
        }
    }
}

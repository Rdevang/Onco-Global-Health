/**
 * Text output for Agentforce planner; wraps OncoDiscoverySpecialties.searchSpecialties.
 */
public with sharing class OncoDiscoverySpecialtiesAgent {
    public class AgentRequest {
        @InvocableVariable(label = 'Search Text' description = 'Filter specialty name; leave blank to list all.')
        public String searchText;
    }

    public class AgentResult {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String specialtiesText;
        @InvocableVariable public String message;
    }

    @InvocableMethod(
        label = 'Search Oncology Specialties'
        description = 'Lists CareSpecialty (standard) and HealthcareProviderTaxonomy names for browsing departments/specialties.'
        category = 'Onco'
    )
    public static List<AgentResult> searchSpecialtiesForAgent(List<AgentRequest> requests) {
        AgentResult r = new AgentResult();
        r.success = false;
        r.specialtiesText = '';
        r.message = '';
        if (requests == null || requests.isEmpty()) {
            r.message = 'No request';
            return new List<AgentResult>{ r };
        }
        try {
            OncoDiscoverySpecialties.SearchSpecialtiesRequest req = new OncoDiscoverySpecialties.SearchSpecialtiesRequest();
            req.searchText = requests[0].searchText;
            List<List<OncoDiscoverySpecialties.SpecialtyRow>> wrapped = OncoDiscoverySpecialties.searchSpecialties(
                new List<OncoDiscoverySpecialties.SearchSpecialtiesRequest>{ req }
            );
            List<OncoDiscoverySpecialties.SpecialtyRow> rows = wrapped != null && !wrapped.isEmpty()
                ? wrapped[0]
                : new List<OncoDiscoverySpecialties.SpecialtyRow>();
            List<String> lines = new List<String>();
            for (OncoDiscoverySpecialties.SpecialtyRow row : rows) {
                if (row == null) {
                    continue;
                }
                String line = '- ' + (String.isNotBlank(row.name) ? row.name : 'Specialty');
                if (String.isNotBlank(row.specialtyType)) {
                    line += ' | Category: ' + row.specialtyType;
                }
                lines.add(line);
            }
            r.specialtiesText = String.join(lines, '\n');
            r.success = true;
            r.message = rows.isEmpty() ? 'No specialties found.' : 'Found ' + rows.size() + ' specialty row(s).';
            return new List<AgentResult>{ r };
        } catch (Exception e) {
            r.message = e.getMessage();
            return new List<AgentResult>{ r };
        }
    }
}

/**
 * Text output for Agentforce planner; wraps OncoDiscoverySpecialties.searchSpecialties.
 */
public without sharing class OncoDiscoverySpecialtiesAgent {
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
            Boolean scopedApplied = scopedName != null;
            String requestedFacilityLabel = String.isNotBlank(requests[0].facilityName)
                ? requests[0].facilityName
                : (String.isNotBlank(requests[0].healthcareFacilityId) ? requests[0].healthcareFacilityId : null);
            String resolvedFromLookup = null;
            if (scopedRequested && !scopedApplied) {
                resolvedFromLookup = resolveFacilityDisplayName(
                    requests[0].healthcareFacilityId,
                    requests[0].facilityName
                );
            }
            Boolean hadSearchText = String.isNotBlank(requests[0].searchText);
            if (rows.isEmpty()) {
                String facilityLabelForMsg = scopedApplied
                    ? scopedName
                    : (String.isNotBlank(resolvedFromLookup) ? resolvedFromLookup : null);
                if (facilityLabelForMsg != null && hadSearchText) {
                    // Empty because of the searchText filter, not because the facility has no staffing.
                    // Do a second unfiltered lookup to tell the planner what the facility actually offers.
                    List<String> alsoStaffed = unfilteredFacilitySpecialtyNames(
                        requests[0].healthcareFacilityId,
                        requests[0].facilityName
                    );
                    String alsoClause = alsoStaffed.isEmpty()
                        ? ' The facility currently has no other active specialties mapped either.'
                        : ' ' + facilityLabelForMsg + ' currently offers: ' + String.join(alsoStaffed, ', ') + '.';
                    r.message = '"' + requests[0].searchText.trim() + '" is not currently available at '
                        + facilityLabelForMsg + '.' + alsoClause;
                } else if (facilityLabelForMsg != null) {
                    r.message = 'No active specialties are currently staffed at ' + facilityLabelForMsg + '.';
                } else if (scopedRequested) {
                    r.message = 'Could not find a facility matching "' + requestedFacilityLabel
                        + '". No specialties to report.';
                } else {
                    r.message = 'No specialties found.';
                }
            } else if (scopedApplied) {
                r.message = 'Found ' + rows.size() + ' specialty row(s) staffed at ' + scopedName + '.';
            } else if (scopedRequested) {
                // Facility filter was requested but did not resolve to exactly one facility.
                // Rows here are the global catalog. Tell the planner explicitly so it can be honest with the user.
                r.message = 'Could not find a facility matching "' + requestedFacilityLabel
                    + '". Listing the full network catalog instead ('
                    + rows.size() + ' row(s)); relay this to the user before presenting the list.';
            } else {
                r.message = 'Found ' + rows.size() + ' specialty row(s).';
            }
            return new List<AgentResult>{ r };
        } catch (Exception e) {
            r.message = e.getMessage();
            return new List<AgentResult>{ r };
        }
    }

    /**
     * Returns specialty names actually staffed at the given facility, WITHOUT any searchText filter.
     * Used to compose honest "X is not available at <facility>, but it offers Y, Z" messages.
     */
    private static List<String> unfilteredFacilitySpecialtyNames(String facilityId, String facilityName) {
        OncoDiscoverySpecialties.SearchSpecialtiesRequest req = new OncoDiscoverySpecialties.SearchSpecialtiesRequest();
        req.healthcareFacilityId = facilityId;
        req.facilityName = facilityName;
        List<List<OncoDiscoverySpecialties.SpecialtyRow>> wrapped = OncoDiscoverySpecialties.searchSpecialties(
            new List<OncoDiscoverySpecialties.SearchSpecialtiesRequest>{ req }
        );
        List<String> names = new List<String>();
        if (wrapped == null || wrapped.isEmpty()) return names;
        for (OncoDiscoverySpecialties.SpecialtyRow row : wrapped[0]) {
            if (row != null && String.isNotBlank(row.name) && String.isNotBlank(row.scopedFacilityId)) {
                names.add(row.name);
            }
        }
        return names;
    }

    /**
     * Returns the facility display name if the given Id or name resolves to exactly one HealthcareFacility,
     * or null otherwise (no match, or ambiguous match).
     */
    private static String resolveFacilityDisplayName(String facilityId, String facilityName) {
        if (String.isNotBlank(facilityId)) {
            try {
                Id fid = Id.valueOf(facilityId.trim());
                List<HealthcareFacility> rows = [SELECT Name FROM HealthcareFacility WHERE Id = :fid LIMIT 1];
                return rows.isEmpty() ? null : rows[0].Name;
            } catch (Exception e) {
                return null;
            }
        }
        if (String.isNotBlank(facilityName)) {
            String likeName = '%' + facilityName.trim() + '%';
            List<HealthcareFacility> rows = [
                SELECT Name FROM HealthcareFacility WHERE Name LIKE :likeName ORDER BY Name LIMIT 2
            ];
            return rows.size() == 1 ? rows[0].Name : null;
        }
        return null;
    }
}

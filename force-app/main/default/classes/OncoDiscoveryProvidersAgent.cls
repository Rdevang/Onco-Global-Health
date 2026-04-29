/**
 * Text output for Agentforce planner; wraps OncoDiscoveryProviders.findProviders.
 */
public without sharing class OncoDiscoveryProvidersAgent {
    public class AgentRequest {
        @InvocableVariable(label = 'Specialty' description = 'e.g. Medical Oncology, Pediatric Oncology')
        public String specialty;
        @InvocableVariable(label = 'Facility Name Contains' description = 'Substring to match facility name')
        public String facilityNameContains;
        @InvocableVariable(label = 'City' description = 'City on facility account (e.g. Mumbai, Bengaluru)')
        public String city;
    }

    public class AgentResult {
        @InvocableVariable public Boolean success;
        /** Patient-safe lines (no record Ids). */
        @InvocableVariable public String providersText;
        /**
         * Lines including HealthcareProvider Id for Get Slots / Book only.
         * Do not surface to the patient.
         */
        @InvocableVariable(
            label = 'Planner reference (internal)'
            description = 'Provider Id lines for tool calls only; never show the patient.'
        )
        public String plannerReferenceText;
        @InvocableVariable public String message;
    }

    @InvocableMethod(
        label = 'Find Oncology Providers'
        description = 'Lists HealthcareProvider doctors; filter by specialty, city, or facility name.'
        category = 'Onco'
    )
    public static List<AgentResult> findProvidersForAgent(List<AgentRequest> requests) {
        AgentResult r = new AgentResult();
        r.success = false;
        r.providersText = '';
        r.plannerReferenceText = '';
        r.message = '';
        if (requests == null || requests.isEmpty()) {
            r.message = 'No request';
            return new List<AgentResult>{ r };
        }
        try {
            OncoDiscoveryProviders.FindProvidersRequest req = new OncoDiscoveryProviders.FindProvidersRequest();
            req.specialty = requests[0].specialty;
            req.facilityNameContains = requests[0].facilityNameContains;
            req.city = requests[0].city;
            List<List<OncoDiscoveryProviders.ProviderRow>> wrapped = OncoDiscoveryProviders.findProviders(
                new List<OncoDiscoveryProviders.FindProvidersRequest>{ req }
            );
            List<OncoDiscoveryProviders.ProviderRow> rows = wrapped != null && !wrapped.isEmpty()
                ? wrapped[0]
                : new List<OncoDiscoveryProviders.ProviderRow>();
            List<String> displayLines = new List<String>();
            List<String> refLines = new List<String>();
            for (OncoDiscoveryProviders.ProviderRow row : rows) {
                if (row == null) {
                    continue;
                }
                String nm = String.isNotBlank(row.name) ? row.name : 'Provider';
                String spec = String.isNotBlank(row.specialtyHint) ? row.specialtyHint : '';
                String fac = String.isNotBlank(row.primaryFacilityName) ? row.primaryFacilityName : '';
                displayLines.add('- ' + nm + ' | Specialty hint: ' + spec + ' | Facility: ' + fac);
                refLines.add(
                    '- ' +
                        nm +
                        ' | Specialty hint: ' +
                        spec +
                        ' | Facility: ' +
                        fac +
                        ' | Provider Id: ' +
                        (row.healthcareProviderId != null ? String.valueOf(row.healthcareProviderId) : '')
                );
            }
            r.providersText = String.join(displayLines, '\n');
            r.plannerReferenceText = String.join(refLines, '\n');
            r.success = true;
            r.message = rows.isEmpty() ? 'No providers match.' : 'Found ' + rows.size() + ' provider(s).';
            return new List<AgentResult>{ r };
        } catch (Exception e) {
            r.message = e.getMessage();
            return new List<AgentResult>{ r };
        }
    }
}

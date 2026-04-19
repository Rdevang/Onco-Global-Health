public with sharing class OncoSchedulingGetSlots {
    public class GetSlotsRequest {
        @InvocableVariable(required = true label = 'Healthcare Facility Id')
        public String healthcareFacilityId;
        @InvocableVariable(required = true label = 'Work Type Id')
        public String workTypeId;
        /**
         * Set when booking a named doctor. Omit when using {@code careSpecialtyId} for department/specialty-first search.
         */
        @InvocableVariable(
            label = 'Healthcare Provider Id'
            description = 'Single provider; omit if Care Specialty Id is set to search all matching providers at the facility.'
        )
        public String healthcareProviderId;
        /**
         * Standard Health Cloud: find slots across every provider at this facility who is linked to this CareSpecialty
         * via HealthcareProviderSpecialty (Practitioner / Contact). Omit when Provider Id is set.
         */
        @InvocableVariable(
            label = 'Care Specialty Id'
            description = 'Department/specialty-first: providers at the facility with this CareSpecialty; omit when Provider Id is set.'
        )
        public String careSpecialtyId;
        @InvocableVariable(required = true label = 'From (UTC)')
        public Datetime fromTimeUtc;
        @InvocableVariable(required = true label = 'To (UTC)')
        public Datetime toTimeUtc;
        @InvocableVariable(label = 'Timezone (e.g. Asia/Kolkata)')
        public String timezoneId;
    }

    public class SlotResult {
        @InvocableVariable public Datetime startTime;
        @InvocableVariable public Datetime endTime;
        @InvocableVariable public String healthcareProviderId;
        @InvocableVariable public String providerName;
        @InvocableVariable public String serviceTerritoryId;
        @InvocableVariable public String message;
    }

    private class SlotSortable implements Comparable {
        Datetime start;
        SlotResult result;
        SlotSortable(Datetime s, SlotResult r) {
            start = s;
            result = r;
        }
        public Integer compareTo(Object other) {
            SlotSortable o = (SlotSortable) other;
            if (start == null && o.start == null) {
                return 0;
            }
            if (start == null) {
                return -1;
            }
            if (o.start == null) {
                return 1;
            }
            if (start > o.start) {
                return 1;
            }
            if (start < o.start) {
                return -1;
            }
            return 0;
        }
    }

    @InvocableMethod(
        label = 'Get Available Slots'
        description = 'Returns candidate slots for a facility and work type. Pass either Healthcare Provider Id or Care Specialty Id (not both).'
        category = 'Onco'
    )
    public static List<List<SlotResult>> getAvailableSlots(List<GetSlotsRequest> requests) {
        List<List<SlotResult>> wrap = new List<List<SlotResult>>();
        if (requests == null || requests.isEmpty()) {
            wrap.add(new List<SlotResult>());
            return wrap;
        }
        GetSlotsRequest req = requests[0];
        List<SlotResult> out = new List<SlotResult>();

        if (String.isBlank(req.healthcareFacilityId) || String.isBlank(req.workTypeId) || req.fromTimeUtc == null || req.toTimeUtc == null) {
            wrap.add(errorRow('Missing required inputs (facility, work type, from/to).'));
            return wrap;
        }

        Boolean hasProvider = String.isNotBlank(req.healthcareProviderId);
        Boolean hasSpecialty = String.isNotBlank(req.careSpecialtyId);
        if (!hasProvider && !hasSpecialty) {
            wrap.add(errorRow('Provide Healthcare Provider Id or Care Specialty Id.'));
            return wrap;
        }
        if (hasProvider && hasSpecialty) {
            // Prefer explicit provider (named doctor).
            hasSpecialty = false;
        }

        Id facId = req.healthcareFacilityId;
        Id wtId = req.workTypeId;
        Id territoryId = OncoSchedulerGateway.getTerritoryIdForFacility(facId);
        if (territoryId == null) {
            wrap.add(errorRow('No ServiceTerritory found for facility (check Onco seed naming).'));
            return wrap;
        }
        Decimal durDec = OncoSchedulerGateway.getWorkTypeDurationMinutes(wtId);
        Integer dur = durDec.intValue();
        String tz = String.isNotBlank(req.timezoneId) ? req.timezoneId : 'Asia/Kolkata';

        if (hasProvider) {
            out = slotsForSingleProvider(territoryId, req.healthcareProviderId, dur, tz, req.fromTimeUtc, req.toTimeUtc, 24);
            wrap.add(out);
            return wrap;
        }

        List<HealthcareProvider> providers = providersAtFacilityForCareSpecialty(facId, req.careSpecialtyId);
        if (providers.isEmpty()) {
            wrap.add(errorRow('No providers at this facility for the given Care Specialty.'));
            return wrap;
        }

        Integer maxTotal = 24;
        for (HealthcareProvider hp : providers) {
            if (out.size() >= maxTotal) {
                break;
            }
            Integer room = maxTotal - out.size();
            List<SlotResult> part = slotsForSingleProvider(
                territoryId,
                hp.Id,
                dur,
                tz,
                req.fromTimeUtc,
                req.toTimeUtc,
                room
            );
            out.addAll(part);
        }

        List<SlotSortable> sortMe = new List<SlotSortable>();
        for (SlotResult sr : out) {
            if (sr != null && sr.startTime != null) {
                sortMe.add(new SlotSortable(sr.startTime, sr));
            }
        }
        sortMe.sort();
        List<SlotResult> sorted = new List<SlotResult>();
        for (SlotSortable ss : sortMe) {
            sorted.add(ss.result);
        }
        wrap.add(sorted);
        return wrap;
    }

    private static List<SlotResult> errorRow(String msg) {
        SlotResult err = new SlotResult();
        err.message = msg;
        return new List<SlotResult>{ err };
    }

    /**
     * Providers who practice at the facility AND have HealthcareProviderSpecialty for the CareSpecialty (via Contact).
     */
    private static List<HealthcareProvider> providersAtFacilityForCareSpecialty(Id facilityId, String careSpecialtyId) {
        if (facilityId == null || String.isBlank(careSpecialtyId)) {
            return new List<HealthcareProvider>();
        }
        Id specId = (Id) careSpecialtyId;
        Set<Id> atFacility = new Set<Id>();
        for (HealthcarePractitionerFacility hpf : [
            SELECT HealthcareProviderId
            FROM HealthcarePractitionerFacility
            WHERE HealthcareFacilityId = :facilityId AND IsActive = true
        ]) {
            atFacility.add(hpf.HealthcareProviderId);
        }
        if (atFacility.isEmpty()) {
            return new List<HealthcareProvider>();
        }
        Set<Id> practitionerContacts = new Set<Id>();
        for (HealthcareProviderSpecialty hps : [
            SELECT PractitionerId
            FROM HealthcareProviderSpecialty
            WHERE SpecialtyId = :specId AND IsActive = true AND PractitionerId != null
        ]) {
            practitionerContacts.add(hps.PractitionerId);
        }
        if (practitionerContacts.isEmpty()) {
            return new List<HealthcareProvider>();
        }
        return [
            SELECT Id, Name
            FROM HealthcareProvider
            WHERE Id IN :atFacility AND PractitionerId IN :practitionerContacts AND Name LIKE 'Dr.%'
            ORDER BY Name
        ];
    }

    private static List<SlotResult> slotsForSingleProvider(
        Id territoryId,
        String healthcareProviderId,
        Integer dur,
        String tz,
        Datetime fromUtc,
        Datetime toUtc,
        Integer maxSlots
    ) {
        List<SlotResult> out = new List<SlotResult>();
        Id providerId = healthcareProviderId;
        Id resourceId = OncoSchedulerGateway.getServiceResourceIdForProvider(providerId);
        if (resourceId == null) {
            SlotResult err = new SlotResult();
            err.message = 'No active ServiceResource for provider.';
            out.add(err);
            return out;
        }

        List<Datetime> candidates = OncoSchedulerGateway.generateSlots(fromUtc, toUtc, dur, tz);
        Set<Datetime> busy = new Set<Datetime>();
        for (ServiceAppointment sa : [
            SELECT SchedStartTime
            FROM ServiceAppointment
            WHERE
                ServiceTerritoryId = :territoryId
                AND Status NOT IN ('Canceled', 'Completed')
                AND SchedStartTime >= :fromUtc
                AND SchedStartTime < :toUtc
                AND Id IN (
                    SELECT ServiceAppointmentId
                    FROM AssignedResource
                    WHERE ServiceResourceId = :resourceId
                )
        ]) {
            busy.add(sa.SchedStartTime);
        }

        HealthcareProvider hp = [SELECT Id, Name FROM HealthcareProvider WHERE Id = :providerId LIMIT 1];

        Integer cap = maxSlots != null && maxSlots > 0 ? maxSlots : 24;
        for (Datetime st : candidates) {
            if (busy.contains(st)) {
                continue;
            }
            SlotResult s = new SlotResult();
            s.startTime = st;
            s.endTime = st.addMinutes(dur);
            s.serviceTerritoryId = territoryId;
            s.healthcareProviderId = hp.Id;
            s.providerName = hp.Name;
            out.add(s);
            if (out.size() >= cap) {
                break;
            }
        }
        return out;
    }
}

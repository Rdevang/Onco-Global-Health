public with sharing class OncoSchedulingGetSlots {
    public class GetSlotsRequest {
        @InvocableVariable(required=true label='Healthcare Facility Id')
        public String healthcareFacilityId;
        @InvocableVariable(required=true label='Work Type Id')
        public String workTypeId;
        @InvocableVariable(required=true label='Healthcare Provider Id')
        public String healthcareProviderId;
        @InvocableVariable(required=true label='From (UTC)')
        public Datetime fromTimeUtc;
        @InvocableVariable(required=true label='To (UTC)')
        public Datetime toTimeUtc;
        @InvocableVariable(label='Timezone (e.g. Asia/Kolkata)')
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

    @InvocableMethod(
        label='Get Available Slots'
        description='Returns candidate appointment slots for a facility, work type, and provider.'
        category='Onco'
    )
    public static List<List<SlotResult>> getAvailableSlots(List<GetSlotsRequest> requests) {
        List<List<SlotResult>> wrap = new List<List<SlotResult>>();
        if (requests == null || requests.isEmpty()) {
            wrap.add(new List<SlotResult>());
            return wrap;
        }
        GetSlotsRequest req = requests[0];
        List<SlotResult> out = new List<SlotResult>();
        if (String.isBlank(req.healthcareFacilityId) || String.isBlank(req.workTypeId) || req.fromTimeUtc == null
            || req.toTimeUtc == null || String.isBlank(req.healthcareProviderId)) {
            SlotResult err = new SlotResult();
            err.message = 'Missing required inputs (facility, provider, work type, from/to).';
            wrap.add(new List<SlotResult>{ err });
            return wrap;
        }
        Id facId = req.healthcareFacilityId;
        Id wtId = req.workTypeId;
        Id territoryId = OncoSchedulerGateway.getTerritoryIdForFacility(facId);
        if (territoryId == null) {
            SlotResult err = new SlotResult();
            err.message = 'No ServiceTerritory found for facility (check Onco seed naming).';
            wrap.add(new List<SlotResult>{ err });
            return wrap;
        }
        Decimal durDec = OncoSchedulerGateway.getWorkTypeDurationMinutes(wtId);
        Integer dur = durDec.intValue();
        String tz = String.isNotBlank(req.timezoneId) ? req.timezoneId : 'Asia/Kolkata';

        Id providerId = req.healthcareProviderId;
        Id resourceId = OncoSchedulerGateway.getServiceResourceIdForProvider(providerId);
        if (resourceId == null) {
            SlotResult err = new SlotResult();
            err.message = 'No active ServiceResource for provider.';
            wrap.add(new List<SlotResult>{ err });
            return wrap;
        }

        List<Datetime> candidates = OncoSchedulerGateway.generateSlots(req.fromTimeUtc, req.toTimeUtc, dur, tz);
        Set<Datetime> busy = new Set<Datetime>();
        for (ServiceAppointment sa : [
            SELECT SchedStartTime
            FROM ServiceAppointment
            WHERE
                ServiceTerritoryId = :territoryId
                AND Status NOT IN ('Canceled', 'Completed')
                AND SchedStartTime >= :req.fromTimeUtc
                AND SchedStartTime < :req.toTimeUtc
                AND Id IN (
                    SELECT ServiceAppointmentId
                    FROM AssignedResource
                    WHERE ServiceResourceId = :resourceId
                )
        ]) {
            busy.add(sa.SchedStartTime);
        }

        HealthcareProvider hp = [SELECT Id, Name FROM HealthcareProvider WHERE Id = :providerId LIMIT 1];

        Integer maxSlots = 24;
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
            if (out.size() >= maxSlots) {
                break;
            }
        }
        wrap.add(out);
        return wrap;
    }
}
// Prints candidate slots from OncoSchedulingGetSlots (same logic as the agent "Get Available Appointment Slots").
// Usage: sf apex run --file scripts/apex/query_available_slots.apex -o <orgAlias>

HealthcareFacility fac = [
    SELECT Id, Name
    FROM HealthcareFacility
    WHERE Name = 'Onco Global - Mumbai Andheri'
    LIMIT 1
];
HealthcareProvider hp = [
    SELECT Id, Name
    FROM HealthcareProvider
    WHERE Name = 'Dr. Arjun Mehta'
    LIMIT 1
];
WorkType wt = [SELECT Id, Name FROM WorkType WHERE Name = 'Onco New Consult' LIMIT 1];

Datetime fromUtc = Datetime.now().addDays(1);
Datetime toUtc = fromUtc.addDays(14);

OncoSchedulingGetSlots.GetSlotsRequest req = new OncoSchedulingGetSlots.GetSlotsRequest();
req.healthcareFacilityId = fac.Id;
req.healthcareProviderId = hp.Id;
req.workTypeId = wt.Id;
req.fromTimeUtc = fromUtc;
req.toTimeUtc = toUtc;
req.timezoneId = 'Asia/Kolkata';

List<List<OncoSchedulingGetSlots.SlotResult>> wrapped = OncoSchedulingGetSlots.getAvailableSlots(
    new List<OncoSchedulingGetSlots.GetSlotsRequest>{ req }
);
List<OncoSchedulingGetSlots.SlotResult> rows = wrapped[0];

System.debug('Facility: ' + fac.Name + ' (' + fac.Id + ')');
System.debug('Provider: ' + hp.Name + ' (' + hp.Id + ')');
System.debug('WorkType: ' + wt.Name + ' (' + wt.Id + ')');
System.debug('Window (UTC): ' + fromUtc + ' .. ' + toUtc);
System.debug('Slot count: ' + rows.size());
for (OncoSchedulingGetSlots.SlotResult s : rows) {
    if (s == null || s.startTime == null) {
        System.debug('Note: ' + (s != null ? s.message : 'null row'));
        continue;
    }
    System.debug(
        '  ' + s.startTime + ' UTC -> ' + s.endTime + ' | ' + s.providerName
    );
}

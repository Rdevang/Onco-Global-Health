/**
 * Phase 02 - Onco Global seed data.
 *
 * Idempotent: matches existing rows by Name convention (all seeded rows are
 * prefixed "Onco ..." / "Dr. ..." so repeated runs skip or update in place).
 *
 * Run: sf apex run --file scripts/apex/seed_onco_data.apex --target-org Healthcloud
 */

// ---------------------------------------------------------------------------
// 0. Config
// ---------------------------------------------------------------------------
String ONCO_PARENT = 'Onco Global Cancer Care';
String TZ = 'Asia/Kolkata';

List<List<String>> FACILITIES = new List<List<String>>{
    new List<String>{ 'Mumbai',    'Onco Global - Mumbai Andheri' },
    new List<String>{ 'Mumbai',    'Onco Global - Mumbai Powai' },
    new List<String>{ 'Bengaluru', 'Onco Global - Bengaluru Whitefield' },
    new List<String>{ 'Bengaluru', 'Onco Global - Bengaluru HSR' },
    new List<String>{ 'Delhi',     'Onco Global - Delhi Saket' },
    new List<String>{ 'Delhi',     'Onco Global - Delhi Dwarka' },
    new List<String>{ 'Hyderabad', 'Onco Global - Hyderabad Banjara' },
    new List<String>{ 'Chennai',   'Onco Global - Chennai Anna Nagar' },
    new List<String>{ 'Pune',      'Onco Global - Pune Baner' },
    new List<String>{ 'Kolkata',   'Onco Global - Kolkata Salt Lake' }
};

List<String> SPECIALTIES = new List<String>{
    'Medical Oncology',
    'Surgical Oncology',
    'Radiation Oncology',
    'Pediatric Oncology',
    'Gynecologic Oncology',
    'Hemato-Oncology',
    'Palliative Care'
};

// Provider seed: { firstName, lastName, specialty, facilityName }
List<List<String>> PROVIDERS = new List<List<String>>{
    new List<String>{ 'Arjun',   'Mehta',       'Medical Oncology',    'Onco Global - Mumbai Andheri' },
    new List<String>{ 'Priya',   'Kapoor',      'Medical Oncology',    'Onco Global - Mumbai Powai' },
    new List<String>{ 'Rohan',   'Iyer',        'Medical Oncology',    'Onco Global - Bengaluru Whitefield' },
    new List<String>{ 'Sneha',   'Nair',        'Medical Oncology',    'Onco Global - Delhi Saket' },
    new List<String>{ 'Vikram',  'Sharma',      'Surgical Oncology',   'Onco Global - Mumbai Andheri' },
    new List<String>{ 'Ananya',  'Joshi',       'Surgical Oncology',   'Onco Global - Bengaluru HSR' },
    new List<String>{ 'Kabir',   'Rao',         'Surgical Oncology',   'Onco Global - Hyderabad Banjara' },
    new List<String>{ 'Ishita',  'Banerjee',    'Surgical Oncology',   'Onco Global - Kolkata Salt Lake' },
    new List<String>{ 'Neel',    'Patel',       'Radiation Oncology',  'Onco Global - Mumbai Powai' },
    new List<String>{ 'Meera',   'Saxena',      'Radiation Oncology',  'Onco Global - Delhi Dwarka' },
    new List<String>{ 'Aarav',   'Krishnan',    'Radiation Oncology',  'Onco Global - Chennai Anna Nagar' },
    new List<String>{ 'Divya',   'Reddy',       'Radiation Oncology',  'Onco Global - Hyderabad Banjara' },
    new List<String>{ 'Siddharth','Gupta',      'Pediatric Oncology',  'Onco Global - Bengaluru Whitefield' },
    new List<String>{ 'Kavya',   'Menon',       'Pediatric Oncology',  'Onco Global - Delhi Saket' },
    new List<String>{ 'Rahul',   'Das',         'Pediatric Oncology',  'Onco Global - Kolkata Salt Lake' },
    new List<String>{ 'Tanvi',   'Chatterjee',  'Pediatric Oncology',  'Onco Global - Pune Baner' },
    new List<String>{ 'Aryan',   'Kulkarni',    'Gynecologic Oncology','Onco Global - Pune Baner' },
    new List<String>{ 'Riya',    'Desai',       'Gynecologic Oncology','Onco Global - Mumbai Andheri' },
    new List<String>{ 'Aditi',   'Malhotra',    'Gynecologic Oncology','Onco Global - Delhi Saket' },
    new List<String>{ 'Karan',   'Verma',       'Gynecologic Oncology','Onco Global - Bengaluru HSR' },
    new List<String>{ 'Saanvi',  'Bhat',        'Hemato-Oncology',     'Onco Global - Bengaluru Whitefield' },
    new List<String>{ 'Dev',     'Pillai',      'Hemato-Oncology',     'Onco Global - Chennai Anna Nagar' },
    new List<String>{ 'Ira',     'Sen',         'Hemato-Oncology',     'Onco Global - Kolkata Salt Lake' },
    new List<String>{ 'Yash',    'Trivedi',     'Hemato-Oncology',     'Onco Global - Hyderabad Banjara' },
    new List<String>{ 'Nisha',   'Shetty',      'Palliative Care',     'Onco Global - Mumbai Powai' },
    new List<String>{ 'Manav',   'Raman',       'Palliative Care',     'Onco Global - Delhi Dwarka' },
    new List<String>{ 'Anika',   'Ghosh',       'Palliative Care',     'Onco Global - Pune Baner' },
    new List<String>{ 'Rudra',   'Subramanian', 'Palliative Care',     'Onco Global - Chennai Anna Nagar' },
    new List<String>{ 'Tara',    'Hegde',       'Medical Oncology',    'Onco Global - Hyderabad Banjara' },
    new List<String>{ 'Vivaan',  'Mathur',      'Surgical Oncology',   'Onco Global - Pune Baner' }
};

// Work types (global, linked to all WorkTypeGroups via WorkTypeGroupMember)
// { name, estimatedMinutes }
List<List<String>> WORK_TYPES = new List<List<String>>{
    new List<String>{ 'Onco New Consult',    '30' },
    new List<String>{ 'Onco Follow-up',      '15' },
    new List<String>{ 'Onco Chemo Review',   '45' }
};

Boolean personAccountsEnabled = Schema.SObjectType.Account.fields.getMap().containsKey('ispersonaccount');
System.debug('[Seed] Person Accounts enabled: ' + personAccountsEnabled);

// Shared DML options: allow saves through Duplicate Rules (duplicates are fine for seed data)
Database.DMLOptions dmlAllowDupes = new Database.DMLOptions();
dmlAllowDupes.DuplicateRuleHeader.AllowSave = true;
dmlAllowDupes.DuplicateRuleHeader.RunAsCurrentUser = true;

// ---------------------------------------------------------------------------
// 1. Parent Account for Onco Global
// ---------------------------------------------------------------------------
List<Account> parents = [SELECT Id, Name FROM Account WHERE Name = :ONCO_PARENT LIMIT 1];
Account parent;
if (parents.isEmpty()) {
    parent = new Account(Name = ONCO_PARENT, Description = 'Onco Global parent holding (seed)');
    insert parent;
    System.debug('[Seed] Inserted parent Account ' + parent.Id);
} else {
    parent = parents[0];
    System.debug('[Seed] Found parent Account ' + parent.Id);
}

// ---------------------------------------------------------------------------
// 2. Facility Accounts + HealthcareFacility
// ---------------------------------------------------------------------------
Map<String, Id> facilityAccountByName = new Map<String, Id>();
for (Account a : [
    SELECT Id, Name FROM Account WHERE Name LIKE 'Onco Global - %'
]) {
    facilityAccountByName.put(a.Name, a.Id);
}

List<Account> toInsertAccounts = new List<Account>();
for (List<String> row : FACILITIES) {
    String city = row[0], name = row[1];
    if (!facilityAccountByName.containsKey(name)) {
        toInsertAccounts.add(new Account(
            Name = name,
            ParentId = parent.Id,
            BillingCity = city,
            BillingCountry = 'India',
            Description = 'Onco Global facility (seed)'
        ));
    }
}
if (!toInsertAccounts.isEmpty()) {
    Database.insert(toInsertAccounts, dmlAllowDupes);
    for (Account a : toInsertAccounts) facilityAccountByName.put(a.Name, a.Id);
    System.debug('[Seed] Inserted facility Accounts: ' + toInsertAccounts.size());
}

Map<String, Id> facilityByName = new Map<String, Id>();
for (HealthcareFacility f : [
    SELECT Id, Name FROM HealthcareFacility WHERE Name LIKE 'Onco Global - %'
]) {
    facilityByName.put(f.Name, f.Id);
}
List<HealthcareFacility> toInsertFacilities = new List<HealthcareFacility>();
for (List<String> row : FACILITIES) {
    String name = row[1];
    if (!facilityByName.containsKey(name)) {
        toInsertFacilities.add(new HealthcareFacility(
            Name = name,
            AccountId = facilityAccountByName.get(name),
            SourceSystem = 'SEED',
            SourceSystemIdentifier = name
        ));
    }
}
if (!toInsertFacilities.isEmpty()) {
    insert toInsertFacilities;
    for (HealthcareFacility f : toInsertFacilities) facilityByName.put(f.Name, f.Id);
    System.debug('[Seed] Inserted HealthcareFacilities: ' + toInsertFacilities.size());
}

// ---------------------------------------------------------------------------
// 3. Specialty taxonomy
// ---------------------------------------------------------------------------
Map<String, Id> taxonomyByName = new Map<String, Id>();
for (HealthcareProviderTaxonomy t : [
    SELECT Id, Name FROM HealthcareProviderTaxonomy WHERE Name IN :SPECIALTIES
]) {
    taxonomyByName.put(t.Name, t.Id);
}
List<HealthcareProviderTaxonomy> toInsertTax = new List<HealthcareProviderTaxonomy>();
for (String s : SPECIALTIES) {
    if (!taxonomyByName.containsKey(s)) {
        toInsertTax.add(new HealthcareProviderTaxonomy(Name = s));
    }
}
if (!toInsertTax.isEmpty()) {
    insert toInsertTax;
    for (HealthcareProviderTaxonomy t : toInsertTax) taxonomyByName.put(t.Name, t.Id);
    System.debug('[Seed] Inserted HealthcareProviderTaxonomy: ' + toInsertTax.size());
}

// ---------------------------------------------------------------------------
// 4. Doctor Contacts + HealthcareProvider
// ---------------------------------------------------------------------------
Map<String, Id> contactByName = new Map<String, Id>();
for (Contact c : [
    SELECT Id, Name FROM Contact WHERE LastName LIKE 'Dr.%' OR FirstName LIKE 'Dr.%' LIMIT 0
]) { /* placeholder to appease compiler */ }

// Match on "Dr. First Last" full name convention via Name field
Set<String> doctorFullNames = new Set<String>();
for (List<String> p : PROVIDERS) {
    doctorFullNames.add('Dr. ' + p[0] + ' ' + p[1]);
}
for (Contact c : [
    SELECT Id, Name FROM Contact WHERE Name IN :doctorFullNames
]) {
    contactByName.put(c.Name, c.Id);
}

List<Contact> toInsertContacts = new List<Contact>();
for (List<String> p : PROVIDERS) {
    String full = 'Dr. ' + p[0] + ' ' + p[1];
    if (!contactByName.containsKey(full)) {
        toInsertContacts.add(new Contact(
            FirstName = 'Dr. ' + p[0],
            LastName = p[1],
            Title = p[2] + ' Consultant',
            Description = 'Onco Global oncologist (seed)'
        ));
    }
}
if (!toInsertContacts.isEmpty()) {
    Database.insert(toInsertContacts, dmlAllowDupes);
    for (Contact c : toInsertContacts) contactByName.put(c.Name, c.Id);
    System.debug('[Seed] Inserted doctor Contacts: ' + toInsertContacts.size());
}

Map<String, Id> providerByName = new Map<String, Id>();
for (HealthcareProvider hp : [
    SELECT Id, Name FROM HealthcareProvider WHERE Name IN :doctorFullNames
]) {
    providerByName.put(hp.Name, hp.Id);
}
List<HealthcareProvider> toInsertProviders = new List<HealthcareProvider>();
for (List<String> p : PROVIDERS) {
    String full = 'Dr. ' + p[0] + ' ' + p[1];
    if (!providerByName.containsKey(full)) {
        toInsertProviders.add(new HealthcareProvider(
            Name = full,
            PractitionerId = contactByName.get(full)
        ));
    }
}
if (!toInsertProviders.isEmpty()) {
    insert toInsertProviders;
    for (HealthcareProvider hp : toInsertProviders) providerByName.put(hp.Name, hp.Id);
    System.debug('[Seed] Inserted HealthcareProviders: ' + toInsertProviders.size());
}

// ---------------------------------------------------------------------------
// 5. HealthcarePractitionerFacility links
// ---------------------------------------------------------------------------
Set<String> existingHpfKeys = new Set<String>();
for (HealthcarePractitionerFacility hpf : [
    SELECT Id, HealthcareProviderId, HealthcareFacilityId
    FROM HealthcarePractitionerFacility
    WHERE HealthcareProviderId IN :providerByName.values()
]) {
    existingHpfKeys.add(hpf.HealthcareProviderId + '|' + hpf.HealthcareFacilityId);
}
List<HealthcarePractitionerFacility> toInsertHpf = new List<HealthcarePractitionerFacility>();
for (List<String> p : PROVIDERS) {
    String full = 'Dr. ' + p[0] + ' ' + p[1];
    Id provId = providerByName.get(full);
    Id facId = facilityByName.get(p[3]);
    if (provId == null || facId == null) continue;
    String key = provId + '|' + facId;
    if (!existingHpfKeys.contains(key)) {
        toInsertHpf.add(new HealthcarePractitionerFacility(
            Name = full + ' @ ' + p[3],
            HealthcareProviderId = provId,
            HealthcareFacilityId = facId,
            IsPrimaryFacility = true,
            IsActive = true,
            EffectiveFrom = Date.today().addMonths(-6)
        ));
        existingHpfKeys.add(key);
    }
}
if (!toInsertHpf.isEmpty()) {
    insert toInsertHpf;
    System.debug('[Seed] Inserted HealthcarePractitionerFacility: ' + toInsertHpf.size());
}

// ---------------------------------------------------------------------------
// 5a. Practitioner Contact Title (specialty) — aligns Practitioner.Title with seed for discovery
// ---------------------------------------------------------------------------
Map<String, String> titleByDoctorName = new Map<String, String>();
for (List<String> p : PROVIDERS) {
    titleByDoctorName.put('Dr. ' + p[0] + ' ' + p[1], p[2] + ' Consultant');
}
List<Contact> contactTitlePatch = new List<Contact>();
for (Contact c : [SELECT Id, Name, Title FROM Contact WHERE Name IN :titleByDoctorName.keySet()]) {
    String wantTitle = titleByDoctorName.get(c.Name);
    if (wantTitle != null && c.Title != wantTitle) {
        c.Title = wantTitle;
        contactTitlePatch.add(c);
    }
}
if (!contactTitlePatch.isEmpty()) {
    update contactTitlePatch;
    System.debug('[Seed] Updated Contact Title for practitioners: ' + contactTitlePatch.size());
}

// ---------------------------------------------------------------------------
// 5b. Provider ↔ specialty (HealthcareProviderTaxonomy rows per provider for OncoDiscoveryProviders)
// ---------------------------------------------------------------------------
Set<String> hptLinkKeys = new Set<String>();
for (HealthcareProviderTaxonomy ex : [
    SELECT HealthcareProviderId, Name
    FROM HealthcareProviderTaxonomy
    WHERE HealthcareProviderId IN :providerByName.values()
]) {
    hptLinkKeys.add(String.valueOf(ex.HealthcareProviderId) + '|' + ex.Name);
}
List<HealthcareProviderTaxonomy> toInsertHptLink = new List<HealthcareProviderTaxonomy>();
for (List<String> p : PROVIDERS) {
    String full = 'Dr. ' + p[0] + ' ' + p[1];
    Id provId = providerByName.get(full);
    if (provId == null) {
        continue;
    }
    String specName = p[2];
    String k = String.valueOf(provId) + '|' + specName;
    if (hptLinkKeys.contains(k)) {
        continue;
    }
    toInsertHptLink.add(new HealthcareProviderTaxonomy(
        Name = specName,
        HealthcareProviderId = provId,
        IsActive = true,
        IsPrimaryTaxonomy = true
    ));
    hptLinkKeys.add(k);
}
if (!toInsertHptLink.isEmpty()) {
    insert toInsertHptLink;
    System.debug('[Seed] Inserted provider HealthcareProviderTaxonomy links: ' + toInsertHptLink.size());
}

// ---------------------------------------------------------------------------
// 6. OperatingHours + TimeSlots per facility (Mon-Sat 09:00-18:00 IST)
// ---------------------------------------------------------------------------
Map<String, Id> ohByName = new Map<String, Id>();
for (OperatingHours oh : [
    SELECT Id, Name FROM OperatingHours WHERE Name LIKE 'Onco OH - %'
]) {
    ohByName.put(oh.Name, oh.Id);
}
List<OperatingHours> toInsertOh = new List<OperatingHours>();
for (List<String> row : FACILITIES) {
    String ohName = 'Onco OH - ' + row[1];
    if (!ohByName.containsKey(ohName)) {
        toInsertOh.add(new OperatingHours(Name = ohName, TimeZone = TZ));
    }
}
if (!toInsertOh.isEmpty()) {
    insert toInsertOh;
    for (OperatingHours oh : toInsertOh) ohByName.put(oh.Name, oh.Id);
    System.debug('[Seed] Inserted OperatingHours: ' + toInsertOh.size());
}

// TimeSlots: idempotent by OperatingHoursId
Set<Id> ohIdsWithSlots = new Set<Id>();
for (AggregateResult ar : [
    SELECT OperatingHoursId oh, COUNT(Id) c
    FROM TimeSlot
    WHERE OperatingHoursId IN :ohByName.values()
    GROUP BY OperatingHoursId
]) {
    if ((Integer) ar.get('c') > 0) ohIdsWithSlots.add((Id) ar.get('oh'));
}
List<String> DAYS = new List<String>{ 'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday' };
List<TimeSlot> toInsertSlots = new List<TimeSlot>();
for (Id ohId : ohByName.values()) {
    if (ohIdsWithSlots.contains(ohId)) continue;
    for (String d : DAYS) {
        toInsertSlots.add(new TimeSlot(
            OperatingHoursId = ohId,
            DayOfWeek = d,
            StartTime = Time.newInstance(9, 0, 0, 0),
            EndTime   = Time.newInstance(18, 0, 0, 0),
            Type = 'Normal'
        ));
    }
}
if (!toInsertSlots.isEmpty()) {
    insert toInsertSlots;
    System.debug('[Seed] Inserted TimeSlots: ' + toInsertSlots.size());
}

// ---------------------------------------------------------------------------
// 7. ServiceTerritory per facility
// ---------------------------------------------------------------------------
Map<String, Id> territoryByName = new Map<String, Id>();
for (ServiceTerritory st : [
    SELECT Id, Name FROM ServiceTerritory WHERE Name LIKE 'Onco Territory - %'
]) {
    territoryByName.put(st.Name, st.Id);
}
List<ServiceTerritory> toInsertTerritories = new List<ServiceTerritory>();
for (List<String> row : FACILITIES) {
    String tName = 'Onco Territory - ' + row[1];
    if (!territoryByName.containsKey(tName)) {
        toInsertTerritories.add(new ServiceTerritory(
            Name = tName,
            OperatingHoursId = ohByName.get('Onco OH - ' + row[1]),
            IsActive = true
        ));
    }
}
if (!toInsertTerritories.isEmpty()) {
    insert toInsertTerritories;
    for (ServiceTerritory st : toInsertTerritories) territoryByName.put(st.Name, st.Id);
    System.debug('[Seed] Inserted ServiceTerritories: ' + toInsertTerritories.size());
}

// ---------------------------------------------------------------------------
// 8. ServiceResource per provider (typed as Agent to represent a consulting doctor)
// ---------------------------------------------------------------------------
Map<String, Id> resourceByName = new Map<String, Id>();
for (ServiceResource sr : [
    SELECT Id, Name FROM ServiceResource WHERE Name IN :doctorFullNames
]) {
    resourceByName.put(sr.Name, sr.Id);
}
// ServiceResource design for seed data:
//   * Create ONE user-backed base ServiceResource ("Onco Seed Base Resource") on the
//     running user.
//   * For each doctor, create a ServiceCrew + ServiceCrewMember linking the base
//     resource to that crew, then create the doctor's ServiceResource pointing at
//     the crew. This works around the "1 ServiceResource per User" constraint and
//     avoids provisioning real per-doctor users in the seed script.
// In production, replace the crew indirection with a real community user per doctor
// and set ServiceResource.RelatedRecordId directly.
Id runningUserId = UserInfo.getUserId();

ServiceResource baseResource;
List<ServiceResource> baseExisting = [
    SELECT Id, Name FROM ServiceResource WHERE RelatedRecordId = :runningUserId LIMIT 1
];
if (baseExisting.isEmpty()) {
    baseResource = new ServiceResource(
        Name = 'Onco Seed Base Resource',
        IsActive = true,
        ResourceType = 'T',
        RelatedRecordId = runningUserId
    );
    insert baseResource;
    System.debug('[Seed] Inserted base ServiceResource ' + baseResource.Id);
} else {
    baseResource = baseExisting[0];
    System.debug('[Seed] Reusing ServiceResource backed by running user: ' + baseResource.Id + ' (' + baseResource.Name + ')');
}

Map<String, Id> crewByName = new Map<String, Id>();
Set<String> crewNames = new Set<String>();
for (List<String> p : PROVIDERS) crewNames.add('Onco Crew - Dr. ' + p[0] + ' ' + p[1]);
for (ServiceCrew sc : [SELECT Id, Name FROM ServiceCrew WHERE Name IN :crewNames]) {
    crewByName.put(sc.Name, sc.Id);
}
List<ServiceCrew> toInsertCrews = new List<ServiceCrew>();
for (List<String> p : PROVIDERS) {
    String cn = 'Onco Crew - Dr. ' + p[0] + ' ' + p[1];
    if (!crewByName.containsKey(cn)) {
        toInsertCrews.add(new ServiceCrew(Name = cn, CrewSize = 1));
    }
}
if (!toInsertCrews.isEmpty()) {
    insert toInsertCrews;
    for (ServiceCrew sc : toInsertCrews) crewByName.put(sc.Name, sc.Id);
    System.debug('[Seed] Inserted ServiceCrews: ' + toInsertCrews.size());
}

// Add base resource as a member of every crew (one member per crew is enough to activate)
Set<Id> crewsWithMember = new Set<Id>();
for (ServiceCrewMember scm : [
    SELECT Id, ServiceCrewId FROM ServiceCrewMember WHERE ServiceCrewId IN :crewByName.values()
]) {
    crewsWithMember.add(scm.ServiceCrewId);
}
List<ServiceCrewMember> toInsertMembers = new List<ServiceCrewMember>();
for (Id crewId : crewByName.values()) {
    if (!crewsWithMember.contains(crewId)) {
        toInsertMembers.add(new ServiceCrewMember(
            ServiceCrewId = crewId,
            ServiceResourceId = baseResource.Id,
            StartDate = Date.today().addMonths(-3)
        ));
    }
}
if (!toInsertMembers.isEmpty()) {
    insert toInsertMembers;
    System.debug('[Seed] Inserted ServiceCrewMembers: ' + toInsertMembers.size());
}

List<ServiceResource> toInsertResources = new List<ServiceResource>();
for (List<String> p : PROVIDERS) {
    String full = 'Dr. ' + p[0] + ' ' + p[1];
    String cn = 'Onco Crew - ' + full;
    if (!resourceByName.containsKey(full)) {
        toInsertResources.add(new ServiceResource(
            Name = full,
            IsActive = true,
            ResourceType = 'C',
            ServiceCrewId = crewByName.get(cn)
        ));
    }
}
if (!toInsertResources.isEmpty()) {
    insert toInsertResources;
    for (ServiceResource sr : toInsertResources) resourceByName.put(sr.Name, sr.Id);
    System.debug('[Seed] Inserted ServiceResources: ' + toInsertResources.size());
}

// ---------------------------------------------------------------------------
// 9. ServiceTerritoryMember linking each resource to its primary territory
// ---------------------------------------------------------------------------
Set<String> existingStmKeys = new Set<String>();
for (ServiceTerritoryMember stm : [
    SELECT Id, ServiceResourceId, ServiceTerritoryId
    FROM ServiceTerritoryMember
    WHERE ServiceResourceId IN :resourceByName.values()
]) {
    existingStmKeys.add(stm.ServiceResourceId + '|' + stm.ServiceTerritoryId);
}
List<ServiceTerritoryMember> toInsertStm = new List<ServiceTerritoryMember>();
for (List<String> p : PROVIDERS) {
    String full = 'Dr. ' + p[0] + ' ' + p[1];
    Id rid = resourceByName.get(full);
    Id tid = territoryByName.get('Onco Territory - ' + p[3]);
    if (rid == null || tid == null) continue;
    String key = rid + '|' + tid;
    if (!existingStmKeys.contains(key)) {
        toInsertStm.add(new ServiceTerritoryMember(
            ServiceResourceId = rid,
            ServiceTerritoryId = tid,
            EffectiveStartDate = Date.today().addMonths(-3),
            TerritoryType = 'P'
        ));
        existingStmKeys.add(key);
    }
}
if (!toInsertStm.isEmpty()) {
    insert toInsertStm;
    System.debug('[Seed] Inserted ServiceTerritoryMembers: ' + toInsertStm.size());
}

// ---------------------------------------------------------------------------
// 10. WorkTypeGroup per specialty + WorkType + WorkTypeGroupMember
// ---------------------------------------------------------------------------
Map<String, Id> wtgByName = new Map<String, Id>();
Set<String> wtgNames = new Set<String>();
for (String s : SPECIALTIES) wtgNames.add('Onco ' + s);
for (WorkTypeGroup wtg : [
    SELECT Id, Name FROM WorkTypeGroup WHERE Name IN :wtgNames
]) {
    wtgByName.put(wtg.Name, wtg.Id);
}
List<WorkTypeGroup> toInsertWtg = new List<WorkTypeGroup>();
for (String s : SPECIALTIES) {
    String n = 'Onco ' + s;
    if (!wtgByName.containsKey(n)) {
        toInsertWtg.add(new WorkTypeGroup(Name = n, IsActive = true));
    }
}
if (!toInsertWtg.isEmpty()) {
    insert toInsertWtg;
    for (WorkTypeGroup wtg : toInsertWtg) wtgByName.put(wtg.Name, wtg.Id);
    System.debug('[Seed] Inserted WorkTypeGroups: ' + toInsertWtg.size());
}

Map<String, Id> wtByName = new Map<String, Id>();
Set<String> wtNames = new Set<String>();
for (List<String> w : WORK_TYPES) wtNames.add(w[0]);
for (WorkType wt : [SELECT Id, Name FROM WorkType WHERE Name IN :wtNames]) {
    wtByName.put(wt.Name, wt.Id);
}
List<WorkType> toInsertWt = new List<WorkType>();
for (List<String> w : WORK_TYPES) {
    if (!wtByName.containsKey(w[0])) {
        toInsertWt.add(new WorkType(
            Name = w[0],
            EstimatedDuration = Decimal.valueOf(w[1]),
            DurationType = 'Minutes',
            ShouldAutoCreateSvcAppt = false
        ));
    }
}
if (!toInsertWt.isEmpty()) {
    insert toInsertWt;
    for (WorkType wt : toInsertWt) wtByName.put(wt.Name, wt.Id);
    System.debug('[Seed] Inserted WorkTypes: ' + toInsertWt.size());
}

Set<String> existingWtgmKeys = new Set<String>();
for (WorkTypeGroupMember m : [
    SELECT Id, WorkTypeId, WorkTypeGroupId
    FROM WorkTypeGroupMember
    WHERE WorkTypeGroupId IN :wtgByName.values()
]) {
    existingWtgmKeys.add(m.WorkTypeId + '|' + m.WorkTypeGroupId);
}
List<WorkTypeGroupMember> toInsertWtgm = new List<WorkTypeGroupMember>();
for (Id wtId : wtByName.values()) {
    for (Id wtgId : wtgByName.values()) {
        String key = wtId + '|' + wtgId;
        if (!existingWtgmKeys.contains(key)) {
            toInsertWtgm.add(new WorkTypeGroupMember(
                WorkTypeId = wtId,
                WorkTypeGroupId = wtgId
            ));
            existingWtgmKeys.add(key);
        }
    }
}
if (!toInsertWtgm.isEmpty()) {
    insert toInsertWtgm;
    System.debug('[Seed] Inserted WorkTypeGroupMembers: ' + toInsertWtgm.size());
}

// ---------------------------------------------------------------------------
// 11. Sample patient (Priya Sharma)
// ---------------------------------------------------------------------------
Id patientAccountId;
Id patientContactId;
String patientEmail = 'priya.sharma@example.com';
if (personAccountsEnabled) {
    List<Account> existing = Database.query(
        'SELECT Id, PersonContactId FROM Account WHERE PersonEmail = :patientEmail AND IsPersonAccount = true LIMIT 1'
    );
    if (existing.isEmpty()) {
        // Discover a PersonAccount record type
        Id paRtId;
        for (RecordType rt : [
            SELECT Id, DeveloperName FROM RecordType
            WHERE SobjectType = 'Account' AND IsPersonType = true AND IsActive = true LIMIT 1
        ]) { paRtId = rt.Id; }
        SObject pa = Schema.getGlobalDescribe().get('Account').newSObject();
        pa.put('FirstName', 'Priya');
        pa.put('LastName', 'Sharma');
        pa.put('PersonEmail', patientEmail);
        pa.put('PersonMobilePhone', '+919000000001');
        pa.put('Description', 'Onco Global seed patient');
        if (paRtId != null) pa.put('RecordTypeId', paRtId);
        Database.insert(pa, dmlAllowDupes);
        patientAccountId = (Id) pa.get('Id');
        patientContactId = (Id) pa.get('PersonContactId');
        if (patientContactId == null) {
            Account reread = [SELECT PersonContactId FROM Account WHERE Id = :patientAccountId LIMIT 1];
            patientContactId = reread.PersonContactId;
        }
        System.debug('[Seed] Inserted Person Account patient ' + patientAccountId);
    } else {
        patientAccountId = existing[0].Id;
        patientContactId = (Id) existing[0].get('PersonContactId');
        System.debug('[Seed] Found Person Account patient ' + patientAccountId);
    }
} else {
    List<Contact> cs = [
        SELECT Id, AccountId FROM Contact WHERE Email = :patientEmail LIMIT 1
    ];
    if (cs.isEmpty()) {
        Account pa = new Account(Name = 'Priya Sharma (Patient)', Description = 'Onco Global seed patient');
        Database.insert(pa, dmlAllowDupes);
        Contact c = new Contact(
            FirstName = 'Priya', LastName = 'Sharma', Email = patientEmail,
            MobilePhone = '+919000000001', AccountId = pa.Id
        );
        Database.insert(c, dmlAllowDupes);
        patientAccountId = pa.Id;
        patientContactId = c.Id;
        System.debug('[Seed] Inserted business patient ' + patientAccountId);
    } else {
        patientContactId = cs[0].Id;
        patientAccountId = cs[0].AccountId;
    }
}

// ---------------------------------------------------------------------------
// 12. ServiceAppointments (one past, one upcoming)
// ---------------------------------------------------------------------------
// Use Dr. Arjun Mehta (Medical Oncology, Mumbai Andheri) as the seeded doctor
Id docResourceId = resourceByName.get('Dr. Arjun Mehta');
Id docFacilityTerritoryId = territoryByName.get('Onco Territory - Onco Global - Mumbai Andheri');
Id newConsultWtId = wtByName.get('Onco New Consult');

List<ServiceAppointment> existingAppts = [
    SELECT Id, SchedStartTime, Subject FROM ServiceAppointment
    WHERE ParentRecordId = :patientAccountId AND Subject LIKE 'Onco seed%'
];

if (existingAppts.size() < 2 && docResourceId != null && docFacilityTerritoryId != null) {
    Datetime pastStart = Datetime.now().addDays(-14).addHours(-Datetime.now().hour()).addMinutes(-Datetime.now().minute()).addSeconds(-Datetime.now().second()).addHours(10);
    Datetime futureStart = Datetime.now().addDays(7).addHours(-Datetime.now().hour()).addMinutes(-Datetime.now().minute()).addSeconds(-Datetime.now().second()).addHours(11);

    List<ServiceAppointment> toInsertAppts = new List<ServiceAppointment>();
    toInsertAppts.add(new ServiceAppointment(
        ParentRecordId = patientAccountId,
        ContactId = patientContactId,
        WorkTypeId = newConsultWtId,
        ServiceTerritoryId = docFacilityTerritoryId,
        EarliestStartTime = pastStart.addDays(-1),
        DueDate = pastStart.addDays(1),
        SchedStartTime = pastStart,
        SchedEndTime = pastStart.addMinutes(30),
        Status = 'Completed',
        Subject = 'Onco seed - past consult',
        Description = 'Onco seed - past consult'
    ));
    toInsertAppts.add(new ServiceAppointment(
        ParentRecordId = patientAccountId,
        ContactId = patientContactId,
        WorkTypeId = newConsultWtId,
        ServiceTerritoryId = docFacilityTerritoryId,
        EarliestStartTime = futureStart.addHours(-2),
        DueDate = futureStart.addHours(2),
        SchedStartTime = futureStart,
        SchedEndTime = futureStart.addMinutes(30),
        Status = 'Scheduled',
        Subject = 'Onco seed - upcoming consult',
        Description = 'Onco seed - upcoming consult'
    ));
    insert toInsertAppts;
    List<AssignedResource> toInsertAr = new List<AssignedResource>();
    for (ServiceAppointment sa : toInsertAppts) {
        toInsertAr.add(new AssignedResource(
            ServiceAppointmentId = sa.Id,
            ServiceResourceId = docResourceId
        ));
    }
    insert toInsertAr;
    System.debug('[Seed] Inserted seed ServiceAppointments: ' + toInsertAppts.size());
} else {
    System.debug('[Seed] ServiceAppointments already present or missing prerequisites');
}

// ---------------------------------------------------------------------------
// 13. Summary
// ---------------------------------------------------------------------------
System.debug('[Seed] Summary counts:');
System.debug('  Accounts (facility): ' + [SELECT COUNT() FROM Account WHERE Name LIKE 'Onco Global - %']);
System.debug('  HealthcareFacility : ' + [SELECT COUNT() FROM HealthcareFacility WHERE Name LIKE 'Onco Global - %']);
System.debug('  Taxonomy           : ' + [SELECT COUNT() FROM HealthcareProviderTaxonomy WHERE Name IN :SPECIALTIES]);
System.debug('  HealthcareProvider : ' + [SELECT COUNT() FROM HealthcareProvider WHERE Name IN :doctorFullNames]);
System.debug('  HpPractitionerFac  : ' + [SELECT COUNT() FROM HealthcarePractitionerFacility WHERE HealthcareProviderId IN :providerByName.values()]);
System.debug('  OperatingHours     : ' + [SELECT COUNT() FROM OperatingHours WHERE Name LIKE 'Onco OH - %']);
System.debug('  TimeSlot           : ' + [SELECT COUNT() FROM TimeSlot WHERE OperatingHoursId IN :ohByName.values()]);
System.debug('  ServiceTerritory   : ' + [SELECT COUNT() FROM ServiceTerritory WHERE Name LIKE 'Onco Territory - %']);
System.debug('  ServiceResource    : ' + [SELECT COUNT() FROM ServiceResource WHERE Name IN :doctorFullNames]);
System.debug('  ServTerritoryMember: ' + [SELECT COUNT() FROM ServiceTerritoryMember WHERE ServiceResourceId IN :resourceByName.values()]);
System.debug('  WorkTypeGroup      : ' + [SELECT COUNT() FROM WorkTypeGroup WHERE Name IN :wtgNames]);
System.debug('  WorkType           : ' + [SELECT COUNT() FROM WorkType WHERE Name IN :wtNames]);
System.debug('  ServiceAppointment : ' + [SELECT COUNT() FROM ServiceAppointment WHERE Subject LIKE 'Onco seed%']);
System.debug('[Seed] DONE');

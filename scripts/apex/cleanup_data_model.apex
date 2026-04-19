/**
 * Post-fix cleanup for Onco Health Cloud demo data.
 *
 * Run AFTER scripts/apex/fix_data_model_setup.apex. Idempotent.
 *
 * 1.  Link the 8 Hemato-Oncology / Palliative-Care HealthcareProvider rows to their
 *     "Dr. <first> <last>" Contact, so their existing HealthcarePractitionerFacility rows
 *     get a real PractitionerId.
 * 2.  Delete orphan HealthcarePractitionerFacility rows that have no HealthcareProviderId
 *     (left-overs from the original seed that linked anchor Contacts to legacy facilities).
 * 3.  Delete orphan HealthcareProviderTaxonomy rows that have a null HealthcareProviderId.
 * 4.  Delete the 6 legacy "Dr. EPIC / Dr. User / Dr. Integration / Kokilaben"
 *     HealthcareProvider rows. They have no HPF / HPS / HPT references today.
 * 5.  Delete the 4 anchor-only HealthcareProvider rows (Dr. Rajesh Iyer, Dr. Sunita Verma,
 *     Dr. Kavita Reddy, Dr. Priyanka Nair). They have no ServiceResource so they can never
 *     be booked; the 22 PROVIDERS list already covers each specialty >= 4 times.
 * 6.  Delete the 5 anchor-only HealthcareProviderSpecialty seed rows (Rajesh Iyer,
 *     Sunita Verma, Arjun Mehta, Kavita Reddy, Priyanka Nair) whose Contacts are no longer
 *     referenced by any HealthcareProvider after step 5.
 * 7.  Delete the 11 legacy HealthcareFacility rows ("kokilaben", 5 "Onco Global <city>",
 *     5 "Main Wing" variants) that have no matching ServiceTerritory. No HPF rows reference
 *     them any more after step 2.
 * 8.  Delete the 5 legacy ServiceTerritoryMember rows (Dr. OrgFarm EPIC, Dr. Integration
 *     User, Dr. Insights Integration, Dr. B2BMA Integration, Dr. SalesforceIQ Integration)
 *     and the 5 legacy ServiceTerritory rows they belong to.
 * 9.  Mark the 5 canonical CareSpecialty rows as Active and delete the 10 duplicate
 *     CareSpecialty rows (none are referenced by HealthcareProviderSpecialty after the
 *     initial fix script ran).
 *
 * Usage:
 *   sf apex run --file scripts/apex/cleanup_data_model.apex -o <alias>
 */

// ---------- 1. Link Hemato/Palliative HealthcareProviders to their Contacts ----------
List<List<String>> EXTRA_PROVIDERS = new List<List<String>>{
    new List<String>{ 'Saanvi', 'Bhat' },
    new List<String>{ 'Dev', 'Pillai' },
    new List<String>{ 'Ira', 'Sen' },
    new List<String>{ 'Yash', 'Trivedi' },
    new List<String>{ 'Nisha', 'Shetty' },
    new List<String>{ 'Manav', 'Raman' },
    new List<String>{ 'Anika', 'Ghosh' },
    new List<String>{ 'Rudra', 'Subramanian' }
};

Set<String> extraDocNames = new Set<String>();
for (List<String> p : EXTRA_PROVIDERS) {
    extraDocNames.add('Dr. ' + p[0] + ' ' + p[1]);
}

Map<String, Id> extraContactByName = new Map<String, Id>();
for (Contact c : [SELECT Id, Name FROM Contact WHERE Name IN :extraDocNames]) {
    extraContactByName.put(c.Name, c.Id);
}

List<HealthcareProvider> hpExtraUpdates = new List<HealthcareProvider>();
for (HealthcareProvider hp : [
    SELECT Id, Name, PractitionerId
    FROM HealthcareProvider
    WHERE Name IN :extraDocNames
]) {
    Id cId = extraContactByName.get(hp.Name);
    if (cId != null && hp.PractitionerId != cId) {
        hpExtraUpdates.add(new HealthcareProvider(Id = hp.Id, PractitionerId = cId));
    }
}
if (!hpExtraUpdates.isEmpty()) {
    update hpExtraUpdates;
    System.debug('[Cleanup] Hemato/Palliative HealthcareProvider.PractitionerId updated: ' + hpExtraUpdates.size());
}

// Backfill HPF.PractitionerId for the newly-linked HPs.
Map<Id, Id> practitionerByHp = new Map<Id, Id>();
for (HealthcareProvider hp : [
    SELECT Id, PractitionerId FROM HealthcareProvider WHERE PractitionerId != null
]) {
    practitionerByHp.put(hp.Id, hp.PractitionerId);
}
List<HealthcarePractitionerFacility> hpfBackfill = new List<HealthcarePractitionerFacility>();
for (HealthcarePractitionerFacility row : [
    SELECT Id, HealthcareProviderId, PractitionerId
    FROM HealthcarePractitionerFacility
    WHERE PractitionerId = null AND HealthcareProviderId != null
]) {
    Id pId = practitionerByHp.get(row.HealthcareProviderId);
    if (pId != null) {
        hpfBackfill.add(new HealthcarePractitionerFacility(Id = row.Id, PractitionerId = pId));
    }
}
if (!hpfBackfill.isEmpty()) {
    update hpfBackfill;
    System.debug('[Cleanup] HPF.PractitionerId backfilled (extra): ' + hpfBackfill.size());
}

// ---------- 2. Delete orphan HPF rows (null HealthcareProviderId) ----------
List<HealthcarePractitionerFacility> orphanHpf = [
    SELECT Id FROM HealthcarePractitionerFacility WHERE HealthcareProviderId = null
];
if (!orphanHpf.isEmpty()) {
    delete orphanHpf;
    System.debug('[Cleanup] Orphan HPF deleted: ' + orphanHpf.size());
}

// ---------- 3. Delete orphan HealthcareProviderTaxonomy rows ----------
List<HealthcareProviderTaxonomy> orphanHpt = [
    SELECT Id FROM HealthcareProviderTaxonomy WHERE HealthcareProviderId = null
];
if (!orphanHpt.isEmpty()) {
    delete orphanHpt;
    System.debug('[Cleanup] Orphan HPT deleted: ' + orphanHpt.size());
}

// ---------- 4. Delete legacy HealthcareProvider rows ----------
List<HealthcareProvider> legacyHps = [
    SELECT Id, Name
    FROM HealthcareProvider
    WHERE Name LIKE 'Dr. EPIC%'
        OR Name LIKE 'Dr. Integration%'
        OR Name LIKE 'Dr. User%'
        OR Name = 'Kokilaben'
];
if (!legacyHps.isEmpty()) {
    // Defensive: clear any HPF/HPT rows that still point at them.
    List<HealthcarePractitionerFacility> legacyHpHpfs = [
        SELECT Id FROM HealthcarePractitionerFacility WHERE HealthcareProviderId IN :legacyHps
    ];
    if (!legacyHpHpfs.isEmpty()) {
        delete legacyHpHpfs;
    }
    List<HealthcareProviderTaxonomy> legacyHpHpts = [
        SELECT Id FROM HealthcareProviderTaxonomy WHERE HealthcareProviderId IN :legacyHps
    ];
    if (!legacyHpHpts.isEmpty()) {
        delete legacyHpHpts;
    }
    delete legacyHps;
    System.debug('[Cleanup] Legacy HealthcareProvider rows deleted: ' + legacyHps.size());
}

// ---------- 5. Delete anchor-only HealthcareProvider rows ----------
Set<String> anchorHpNames = new Set<String>{
    'Dr. Rajesh Iyer', 'Dr. Sunita Verma', 'Dr. Kavita Reddy', 'Dr. Priyanka Nair'
};
List<HealthcareProvider> anchorHps = [
    SELECT Id, Name FROM HealthcareProvider WHERE Name IN :anchorHpNames
];
if (!anchorHps.isEmpty()) {
    List<HealthcarePractitionerFacility> anchorHpfs = [
        SELECT Id FROM HealthcarePractitionerFacility WHERE HealthcareProviderId IN :anchorHps
    ];
    if (!anchorHpfs.isEmpty()) {
        delete anchorHpfs;
    }
    List<HealthcareProviderTaxonomy> anchorHpts = [
        SELECT Id FROM HealthcareProviderTaxonomy WHERE HealthcareProviderId IN :anchorHps
    ];
    if (!anchorHpts.isEmpty()) {
        delete anchorHpts;
    }
    delete anchorHps;
    System.debug('[Cleanup] Anchor-only HealthcareProvider rows deleted: ' + anchorHps.size());
}

// ---------- 6. Delete orphan anchor HealthcareProviderSpecialty rows ----------
// After step 5, the anchor Contacts (Rajesh Iyer / Sunita Verma / Arjun Mehta / Kavita Reddy / Priyanka Nair)
// are no longer referenced by any HealthcareProvider. Their HPS rows are dead.
Set<String> anchorContactNames = new Set<String>{
    'Rajesh Iyer', 'Sunita Verma', 'Arjun Mehta', 'Kavita Reddy', 'Priyanka Nair'
};
Set<Id> anchorContactIds = new Set<Id>();
for (Contact c : [SELECT Id FROM Contact WHERE Name IN :anchorContactNames]) {
    anchorContactIds.add(c.Id);
}
// Exclude any anchor name that also happens to be a "Dr. <name>" Contact used by
// the active PROVIDERS list (paranoia: "Arjun Mehta" appears in both rosters).
Set<Id> activePractitionerIds = new Set<Id>();
for (HealthcareProvider hp : [
    SELECT PractitionerId FROM HealthcareProvider
    WHERE Name LIKE 'Dr.%' AND PractitionerId != null
]) {
    activePractitionerIds.add(hp.PractitionerId);
}
Set<Id> safeAnchorContactIds = new Set<Id>();
for (Id cId : anchorContactIds) {
    if (!activePractitionerIds.contains(cId)) {
        safeAnchorContactIds.add(cId);
    }
}
if (!safeAnchorContactIds.isEmpty()) {
    List<HealthcareProviderSpecialty> deadHps = [
        SELECT Id FROM HealthcareProviderSpecialty WHERE PractitionerId IN :safeAnchorContactIds
    ];
    if (!deadHps.isEmpty()) {
        delete deadHps;
        System.debug('[Cleanup] Dead anchor HPS rows deleted: ' + deadHps.size());
    }
}

// ---------- 7. Delete legacy HealthcareFacility rows ----------
Set<String> legacyFacNames = new Set<String>{
    'kokilaben',
    'Onco Global Jaipur',
    'Onco Global Mumbai Central',
    'Onco Global Delhi North',
    'Onco Global Bangalore',
    'Onco Global Chennai',
    'Onco Global Mumbai Central Main Wing',
    'Onco Global Delhi South Main Wing',
    'Onco Global Bangalore Koramangala Main Wing',
    'Onco Global Chennai Guindy Main Wing',
    'Onco Global Hyderabad Banjara Hills Main Wing'
};
List<HealthcareFacility> legacyFacilities = [
    SELECT Id, Name FROM HealthcareFacility WHERE Name IN :legacyFacNames
];
if (!legacyFacilities.isEmpty()) {
    // Defensive: clear any remaining HPF rows that still point at them.
    List<HealthcarePractitionerFacility> hpfOnLegacy = [
        SELECT Id FROM HealthcarePractitionerFacility WHERE HealthcareFacilityId IN :legacyFacilities
    ];
    if (!hpfOnLegacy.isEmpty()) {
        delete hpfOnLegacy;
    }
    try {
        delete legacyFacilities;
        System.debug('[Cleanup] Legacy HealthcareFacility rows deleted: ' + legacyFacilities.size());
    } catch (DmlException e) {
        System.debug('[Cleanup] Could not delete some legacy facilities: ' + e.getMessage());
    }
}

// ---------- 8. Delete legacy ServiceTerritoryMember + ServiceTerritory ----------
Set<String> legacyTerritoryNames = new Set<String>{
    'Onco Global Mumbai Central',
    'Onco Global Delhi South',
    'Onco Global Bangalore Koramangala',
    'Onco Global Chennai Guindy',
    'Onco Global Hyderabad Banjara Hills'
};
List<ServiceTerritory> legacyTerritories = [
    SELECT Id, Name FROM ServiceTerritory WHERE Name IN :legacyTerritoryNames
];
if (!legacyTerritories.isEmpty()) {
    List<ServiceTerritoryMember> legacyStms = [
        SELECT Id FROM ServiceTerritoryMember WHERE ServiceTerritoryId IN :legacyTerritories
    ];
    if (!legacyStms.isEmpty()) {
        delete legacyStms;
        System.debug('[Cleanup] Legacy STM deleted: ' + legacyStms.size());
    }
    try {
        delete legacyTerritories;
        System.debug('[Cleanup] Legacy ServiceTerritory deleted: ' + legacyTerritories.size());
    } catch (DmlException e) {
        System.debug('[Cleanup] Could not delete some legacy territories: ' + e.getMessage());
    }
}

// ---------- 9. Canonicalize CareSpecialty ----------
Set<String> canonicalSpecNames = new Set<String>{
    'Medical Oncology','Surgical Oncology','Radiation Oncology','Pediatric Oncology','Gynecologic Oncology'
};
Map<String, CareSpecialty> canonicalSpecByName = new Map<String, CareSpecialty>();
List<CareSpecialty> allSpecs = [
    SELECT Id, Name, IsActive, CreatedDate
    FROM CareSpecialty
    WHERE Name IN :canonicalSpecNames
    ORDER BY Name, CreatedDate ASC
];
for (CareSpecialty cs : allSpecs) {
    if (!canonicalSpecByName.containsKey(cs.Name)) {
        canonicalSpecByName.put(cs.Name, cs);
    }
}
List<CareSpecialty> activateUpdates = new List<CareSpecialty>();
for (CareSpecialty cs : canonicalSpecByName.values()) {
    if (cs.IsActive != true) {
        activateUpdates.add(new CareSpecialty(Id = cs.Id, IsActive = true));
    }
}
if (!activateUpdates.isEmpty()) {
    update activateUpdates;
    System.debug('[Cleanup] Canonical CareSpecialty rows activated: ' + activateUpdates.size());
}

Set<Id> canonicalIds = new Set<Id>();
for (CareSpecialty cs : canonicalSpecByName.values()) {
    canonicalIds.add(cs.Id);
}
// Only delete duplicates that are NOT referenced by any HealthcareProviderSpecialty.
Set<Id> referencedSpecialtyIds = new Set<Id>();
for (HealthcareProviderSpecialty hps : [
    SELECT SpecialtyId FROM HealthcareProviderSpecialty WHERE SpecialtyId != null
]) {
    referencedSpecialtyIds.add(hps.SpecialtyId);
}
List<CareSpecialty> duplicatesToDelete = new List<CareSpecialty>();
for (CareSpecialty cs : allSpecs) {
    if (!canonicalIds.contains(cs.Id) && !referencedSpecialtyIds.contains(cs.Id)) {
        duplicatesToDelete.add(new CareSpecialty(Id = cs.Id));
    }
}
if (!duplicatesToDelete.isEmpty()) {
    try {
        delete duplicatesToDelete;
        System.debug('[Cleanup] Duplicate CareSpecialty rows deleted: ' + duplicatesToDelete.size());
    } catch (DmlException e) {
        System.debug('[Cleanup] Could not delete CareSpecialty duplicates: ' + e.getMessage());
    }
}

System.debug('[Cleanup] DONE');

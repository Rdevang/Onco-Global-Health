/**
 * Fixes the Onco Health Cloud demo data so department-first scheduling works end-to-end.
 *
 * 1. Link each "Dr. <first> <last>" HealthcareProvider to the matching "Dr. <first> <last>" Contact
 *    (HealthcareProvider.PractitionerId).
 * 2. Upsert HealthcareProviderSpecialty rows (Practitioner -> canonical CareSpecialty) for the 5
 *    Onco specialties (Medical, Surgical, Radiation, Pediatric, Gynecologic).
 * 3. Backfill HealthcarePractitionerFacility.PractitionerId from HealthcareProvider.PractitionerId
 *    wherever it is null but a HealthcareProviderId is present.
 * 4. Populate PersonEmail on the two person-account patients that are missing it.
 *
 * Idempotent: safe to re-run.
 *
 * Usage:
 *   sf apex run --file scripts/apex/fix_data_model_setup.apex -o <alias>
 */

// ---------- 0. Inputs ----------
List<List<String>> PROVIDERS = new List<List<String>>{
    new List<String>{ 'Arjun', 'Mehta', 'Medical Oncology' },
    new List<String>{ 'Priya', 'Kapoor', 'Medical Oncology' },
    new List<String>{ 'Rohan', 'Iyer', 'Medical Oncology' },
    new List<String>{ 'Sneha', 'Nair', 'Medical Oncology' },
    new List<String>{ 'Tara', 'Hegde', 'Medical Oncology' },
    new List<String>{ 'Vikram', 'Sharma', 'Surgical Oncology' },
    new List<String>{ 'Ananya', 'Joshi', 'Surgical Oncology' },
    new List<String>{ 'Kabir', 'Rao', 'Surgical Oncology' },
    new List<String>{ 'Ishita', 'Banerjee', 'Surgical Oncology' },
    new List<String>{ 'Vivaan', 'Mathur', 'Surgical Oncology' },
    new List<String>{ 'Neel', 'Patel', 'Radiation Oncology' },
    new List<String>{ 'Meera', 'Saxena', 'Radiation Oncology' },
    new List<String>{ 'Aarav', 'Krishnan', 'Radiation Oncology' },
    new List<String>{ 'Divya', 'Reddy', 'Radiation Oncology' },
    new List<String>{ 'Siddharth', 'Gupta', 'Pediatric Oncology' },
    new List<String>{ 'Kavya', 'Menon', 'Pediatric Oncology' },
    new List<String>{ 'Rahul', 'Das', 'Pediatric Oncology' },
    new List<String>{ 'Tanvi', 'Chatterjee', 'Pediatric Oncology' },
    new List<String>{ 'Aryan', 'Kulkarni', 'Gynecologic Oncology' },
    new List<String>{ 'Riya', 'Desai', 'Gynecologic Oncology' },
    new List<String>{ 'Aditi', 'Malhotra', 'Gynecologic Oncology' },
    new List<String>{ 'Karan', 'Verma', 'Gynecologic Oncology' }
};

// Canonical CareSpecialty picks (first CreatedDate per Name). Discovery dedupes on name anyway,
// but we want HealthcareProviderSpecialty rows to reference a single consistent Id per specialty.
Map<String, Id> canonicalSpecialtyByName = new Map<String, Id>();
for (CareSpecialty cs : [
    SELECT Id, Name FROM CareSpecialty
    WHERE Name IN ('Medical Oncology','Surgical Oncology','Radiation Oncology','Pediatric Oncology','Gynecologic Oncology')
    ORDER BY Name, CreatedDate ASC
]) {
    if (!canonicalSpecialtyByName.containsKey(cs.Name)) {
        canonicalSpecialtyByName.put(cs.Name, cs.Id);
    }
}
System.debug('[Fix] Canonical specialty map: ' + canonicalSpecialtyByName);

// ---------- 1. HealthcareProvider.PractitionerId ----------
Set<String> docNames = new Set<String>();
for (List<String> p : PROVIDERS) {
    docNames.add('Dr. ' + p[0] + ' ' + p[1]);
}

Map<String, Id> contactByName = new Map<String, Id>();
for (Contact c : [SELECT Id, Name FROM Contact WHERE Name IN :docNames]) {
    contactByName.put(c.Name, c.Id);
}

Map<String, HealthcareProvider> hpByName = new Map<String, HealthcareProvider>();
for (HealthcareProvider hp : [SELECT Id, Name, PractitionerId FROM HealthcareProvider WHERE Name IN :docNames]) {
    hpByName.put(hp.Name, hp);
}

List<HealthcareProvider> hpUpdates = new List<HealthcareProvider>();
for (List<String> p : PROVIDERS) {
    String full = 'Dr. ' + p[0] + ' ' + p[1];
    Id cId = contactByName.get(full);
    HealthcareProvider hp = hpByName.get(full);
    if (cId == null || hp == null) {
        System.debug('[Fix] Skipping - missing Contact or HealthcareProvider for ' + full);
        continue;
    }
    if (hp.PractitionerId != cId) {
        hp.PractitionerId = cId;
        hpUpdates.add(hp);
    }
}
if (!hpUpdates.isEmpty()) {
    update hpUpdates;
    System.debug('[Fix] HealthcareProvider.PractitionerId updated: ' + hpUpdates.size());
}

// ---------- 2. HealthcareProviderSpecialty ----------
Set<Id> pracIds = new Set<Id>();
for (Id cId : contactByName.values()) {
    pracIds.add(cId);
}
Set<String> existingHpsKeys = new Set<String>();
for (HealthcareProviderSpecialty hps : [
    SELECT Id, PractitionerId, SpecialtyId FROM HealthcareProviderSpecialty
    WHERE PractitionerId IN :pracIds
]) {
    existingHpsKeys.add(String.valueOf(hps.PractitionerId) + '|' + String.valueOf(hps.SpecialtyId));
}

List<HealthcareProviderSpecialty> hpsToInsert = new List<HealthcareProviderSpecialty>();
for (List<String> p : PROVIDERS) {
    String full = 'Dr. ' + p[0] + ' ' + p[1];
    String specName = p[2];
    Id cId = contactByName.get(full);
    Id sId = canonicalSpecialtyByName.get(specName);
    if (cId == null || sId == null) {
        continue;
    }
    String key = String.valueOf(cId) + '|' + String.valueOf(sId);
    if (existingHpsKeys.contains(key)) {
        continue;
    }
    hpsToInsert.add(new HealthcareProviderSpecialty(
        Name = full + ' - ' + specName,
        PractitionerId = cId,
        SpecialtyId = sId,
        IsActive = true,
        IsPrimarySpecialty = true
    ));
    existingHpsKeys.add(key);
}
if (!hpsToInsert.isEmpty()) {
    insert hpsToInsert;
    System.debug('[Fix] HealthcareProviderSpecialty inserted: ' + hpsToInsert.size());
}

// ---------- 3. HealthcarePractitionerFacility backfill ----------
Map<Id, Id> practitionerByHp = new Map<Id, Id>();
for (HealthcareProvider hp : [
    SELECT Id, PractitionerId FROM HealthcareProvider
    WHERE PractitionerId != null
]) {
    practitionerByHp.put(hp.Id, hp.PractitionerId);
}

List<HealthcarePractitionerFacility> hpfUpdates = new List<HealthcarePractitionerFacility>();
for (HealthcarePractitionerFacility row : [
    SELECT Id, HealthcareProviderId, PractitionerId
    FROM HealthcarePractitionerFacility
    WHERE PractitionerId = null AND HealthcareProviderId != null
]) {
    Id pId = practitionerByHp.get(row.HealthcareProviderId);
    if (pId != null) {
        row.PractitionerId = pId;
        hpfUpdates.add(row);
    }
}
if (!hpfUpdates.isEmpty()) {
    update hpfUpdates;
    System.debug('[Fix] HealthcarePractitionerFacility.PractitionerId backfilled: ' + hpfUpdates.size());
}

// ---------- 4. Person Account email backfill ----------
List<Account> emailUpdates = new List<Account>();
for (Account src : [
    SELECT Id, FirstName, LastName, Name, PersonEmail
    FROM Account
    WHERE IsPersonAccount = true AND PersonEmail = null
]) {
    String base = (String.isNotBlank(src.FirstName) ? src.FirstName : '') +
                  (String.isNotBlank(src.LastName) ? '.' + src.LastName : src.Name);
    String email = base.trim().toLowerCase().replaceAll('[^a-z0-9.]', '') + '@example.com';
    if (email.startsWith('.')) { email = email.substring(1); }
    if (String.isBlank(email) || email == '@example.com') {
        continue;
    }
    emailUpdates.add(new Account(Id = src.Id, PersonEmail = email));
}
if (!emailUpdates.isEmpty()) {
    update emailUpdates;
    System.debug('[Fix] Person Accounts PersonEmail backfilled: ' + emailUpdates.size());
}

System.debug('[Fix] DONE');

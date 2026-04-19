/**
 * Patch Contact.Title and HealthcareProviderTaxonomy links for OncoDiscoveryProviders.
 * Run after seed: sf apex run --file scripts/apex/patch_provider_specialty_discovery.apex -o <alias>
 */
List<List<String>> PROVIDERS = new List<List<String>>{
    new List<String>{ 'Arjun', 'Mehta', 'Medical Oncology', 'Onco Global - Mumbai Andheri' },
    new List<String>{ 'Priya', 'Kapoor', 'Medical Oncology', 'Onco Global - Mumbai Powai' },
    new List<String>{ 'Rohan', 'Iyer', 'Medical Oncology', 'Onco Global - Bengaluru Whitefield' },
    new List<String>{ 'Sneha', 'Nair', 'Medical Oncology', 'Onco Global - Delhi Saket' },
    new List<String>{ 'Vikram', 'Sharma', 'Surgical Oncology', 'Onco Global - Mumbai Andheri' },
    new List<String>{ 'Ananya', 'Joshi', 'Surgical Oncology', 'Onco Global - Bengaluru HSR' },
    new List<String>{ 'Kabir', 'Rao', 'Surgical Oncology', 'Onco Global - Hyderabad Banjara' },
    new List<String>{ 'Ishita', 'Banerjee', 'Surgical Oncology', 'Onco Global - Kolkata Salt Lake' },
    new List<String>{ 'Neel', 'Patel', 'Radiation Oncology', 'Onco Global - Mumbai Powai' },
    new List<String>{ 'Meera', 'Saxena', 'Radiation Oncology', 'Onco Global - Delhi Dwarka' },
    new List<String>{ 'Aarav', 'Krishnan', 'Radiation Oncology', 'Onco Global - Chennai Anna Nagar' },
    new List<String>{ 'Divya', 'Reddy', 'Radiation Oncology', 'Onco Global - Hyderabad Banjara' },
    new List<String>{ 'Siddharth', 'Gupta', 'Pediatric Oncology', 'Onco Global - Bengaluru Whitefield' },
    new List<String>{ 'Kavya', 'Menon', 'Pediatric Oncology', 'Onco Global - Delhi Saket' },
    new List<String>{ 'Rahul', 'Das', 'Pediatric Oncology', 'Onco Global - Kolkata Salt Lake' },
    new List<String>{ 'Tanvi', 'Chatterjee', 'Pediatric Oncology', 'Onco Global - Pune Baner' },
    new List<String>{ 'Aryan', 'Kulkarni', 'Gynecologic Oncology', 'Onco Global - Pune Baner' },
    new List<String>{ 'Riya', 'Desai', 'Gynecologic Oncology', 'Onco Global - Mumbai Andheri' },
    new List<String>{ 'Aditi', 'Malhotra', 'Gynecologic Oncology', 'Onco Global - Delhi Saket' },
    new List<String>{ 'Karan', 'Verma', 'Gynecologic Oncology', 'Onco Global - Bengaluru HSR' },
    new List<String>{ 'Saanvi', 'Bhat', 'Hemato-Oncology', 'Onco Global - Bengaluru Whitefield' },
    new List<String>{ 'Dev', 'Pillai', 'Hemato-Oncology', 'Onco Global - Chennai Anna Nagar' },
    new List<String>{ 'Ira', 'Sen', 'Hemato-Oncology', 'Onco Global - Kolkata Salt Lake' },
    new List<String>{ 'Yash', 'Trivedi', 'Hemato-Oncology', 'Onco Global - Hyderabad Banjara' },
    new List<String>{ 'Nisha', 'Shetty', 'Palliative Care', 'Onco Global - Mumbai Powai' },
    new List<String>{ 'Manav', 'Raman', 'Palliative Care', 'Onco Global - Delhi Dwarka' },
    new List<String>{ 'Anika', 'Ghosh', 'Palliative Care', 'Onco Global - Pune Baner' },
    new List<String>{ 'Rudra', 'Subramanian', 'Palliative Care', 'Onco Global - Chennai Anna Nagar' },
    new List<String>{ 'Tara', 'Hegde', 'Medical Oncology', 'Onco Global - Hyderabad Banjara' },
    new List<String>{ 'Vivaan', 'Mathur', 'Surgical Oncology', 'Onco Global - Pune Baner' }
};
Set<String> doctorFullNames = new Set<String>();
Map<String, String> titleByDoctorName = new Map<String, String>();
for (List<String> p : PROVIDERS) {
    String full = 'Dr. ' + p[0] + ' ' + p[1];
    doctorFullNames.add(full);
    titleByDoctorName.put(full, p[2] + ' Consultant');
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
    System.debug('[Patch] Updated Contact Title: ' + contactTitlePatch.size());
}
Map<String, Id> providerByName = new Map<String, Id>();
for (HealthcareProvider hp : [SELECT Id, Name FROM HealthcareProvider WHERE Name IN :doctorFullNames]) {
    providerByName.put(hp.Name, hp.Id);
}
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
    toInsertHptLink.add(
        new HealthcareProviderTaxonomy(
            Name = specName,
            HealthcareProviderId = provId,
            IsActive = true,
            IsPrimaryTaxonomy = true
        )
    );
    hptLinkKeys.add(k);
}
if (!toInsertHptLink.isEmpty()) {
    insert toInsertHptLink;
    System.debug('[Patch] Inserted HealthcareProviderTaxonomy links: ' + toInsertHptLink.size());
}
System.debug('[Patch] DONE');

public without sharing class OncoDiscoveryProviders {
    /** Strip trailing parenthetical notes so LIKE matches CareSpecialty/Title (e.g. "Medical Oncology (new consult)"). */
    private static String normalizeSpecialtyToken(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        String s = raw.trim();
        Integer open = s.indexOf('(');
        if (open > 0) {
            s = s.substring(0, open).trim();
        }
        return String.isBlank(s) ? null : s;
    }

    private static List<String> tokenizeFacilityFilter(String raw) {
        List<String> tokens = new List<String>();
        if (String.isBlank(raw)) {
            return tokens;
        }
        String s = raw.replace('\u2013', '-').replace('\u2014', '-');
        s = s.replaceAll('(?i)\\s+or\\s+', ',');
        for (String part : s.split('[,/;]')) {
            String t = part != null ? part.trim() : '';
            if (t.length() > 0) {
                tokens.add(t);
            }
        }
        return tokens;
    }

    private static Boolean tokenMatchesFacilityName(String facilityName, String token) {
        if (String.isBlank(facilityName) || String.isBlank(token)) {
            return false;
        }
        String n = facilityName.trim();
        String t = token.trim();
        if (n.containsIgnoreCase(t)) {
            return true;
        }
        if (t.length() >= 4 && t.containsIgnoreCase(n)) {
            return true;
        }
        return false;
    }

    /** Match if any token matches any facility (handles "Whitefield or HSR" and long pasted names). */
    private static Boolean facilityFilterMatches(String facilityFilter, List<String> facilityNames) {
        if (String.isBlank(facilityFilter)) {
            return true;
        }
        if (facilityNames == null || facilityNames.isEmpty()) {
            return false;
        }
        List<String> tokens = tokenizeFacilityFilter(facilityFilter);
        if (tokens.isEmpty()) {
            return true;
        }
        for (String fn : facilityNames) {
            if (String.isBlank(fn)) {
                continue;
            }
            for (String tok : tokens) {
                if (tokenMatchesFacilityName(fn, tok)) {
                    return true;
                }
                for (String w : tok.split('\\s+')) {
                    String w2 = w.replaceAll('[.,;:()]', '');
                    if (w2.length() >= 3 && tokenMatchesFacilityName(fn, w2)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    public class FindProvidersRequest {
        @InvocableVariable(
            label='Department or specialty'
            description='Matches CareSpecialty name or Practitioner.Title (e.g. Gynecologic Oncology, Pediatrics).'
        )
        public String specialty;
        @InvocableVariable(label='Facility Name Contains')
        public String facilityNameContains;
        @InvocableVariable(label='City')
        public String city;
    }
    public class ProviderRow {
        @InvocableVariable public Id healthcareProviderId;
        @InvocableVariable public String name;
        @InvocableVariable public String primaryFacilityName;
        @InvocableVariable public String specialtyHint;
    }

    @InvocableMethod(
        label='Find Providers'
        description='Finds HealthcareProvider rows; filters by Practitioner.Title and standard CareSpecialty via HealthcareProviderSpecialty (department/specialty browse).'
        category='Onco'
    )
    public static List<List<ProviderRow>> findProviders(List<FindProvidersRequest> requests) {
        FindProvidersRequest req = (requests != null && !requests.isEmpty()) ? requests[0] : new FindProvidersRequest();
        String spec = normalizeSpecialtyToken(String.isNotBlank(req.specialty) ? req.specialty.trim() : null);
        String fac = String.isNotBlank(req.facilityNameContains) ? req.facilityNameContains.trim() : null;
        String city = String.isNotBlank(req.city) ? req.city.trim() : null;

        Set<Id> inCity = null;
        if (city != null) {
            // Build a forgiving city filter: try the full string plus each 3+ char token.
            // Match on Account.BillingCity (e.g. "Mumbai") OR HealthcareFacility.Name
            // (e.g. "Onco Global - Mumbai Andheri") so planner inputs like
            // "Mumbai hospitals", "Mumbai, India", or "Mumbai Andheri" still resolve.
            Set<String> tokens = new Set<String>();
            tokens.add(city);
            for (String w : city.split('[\\s,/;]+')) {
                String w2 = w == null ? '' : w.replaceAll('[.,;:()]', '').trim();
                if (w2.length() >= 3) {
                    tokens.add(w2);
                }
            }
            inCity = new Set<Id>();
            for (String tok : tokens) {
                String likePattern = '%' + tok + '%';
                for (HealthcarePractitionerFacility hpf : [
                    SELECT HealthcareProviderId
                    FROM HealthcarePractitionerFacility
                    WHERE
                        IsActive = true
                        AND (
                            HealthcareFacility.Account.BillingCity LIKE :likePattern
                            OR HealthcareFacility.Name LIKE :likePattern
                        )
                ]) {
                    inCity.add(hpf.HealthcareProviderId);
                }
            }
        }

        List<HealthcareProvider> rows;
        if (spec != null) {
            // Planner often passes long paraphrases ("oncologists specializing in Medical Oncology").
            // Build a token set: full string plus each clinically-meaningful word so LIKE can hit
            // Practitioner.Title / CareSpecialty.Name on any substring.
            Set<String> specialtyTokens = new Set<String>();
            specialtyTokens.add(spec);
            Set<String> stopwords = new Set<String>{
                'who', 'the', 'for', 'and', 'with', 'doctor', 'doctors', 'dr',
                'specialist', 'specialists', 'specializing', 'specialty',
                'department', 'care', 'in', 'at', 'of', 'an', 'any'
            };
            for (String w : spec.split('\\s+')) {
                String w2 = w == null ? '' : w.replaceAll('[.,;:()]', '').trim();
                if (w2.length() >= 4 && !stopwords.contains(w2.toLowerCase())) {
                    specialtyTokens.add(w2);
                }
            }
            Set<Id> bySpecialty = new Set<Id>();
            Set<Id> contactIdsFromCareSpecialty = new Set<Id>();
            for (String tok : specialtyTokens) {
                String likeSpec = '%' + tok + '%';
                for (HealthcareProvider hpTitle : [
                    SELECT Id
                    FROM HealthcareProvider
                    WHERE Name LIKE 'Dr.%' AND Practitioner.Title LIKE :likeSpec
                ]) {
                    bySpecialty.add(hpTitle.Id);
                }
                for (HealthcareProviderSpecialty hps : [
                    SELECT PractitionerId
                    FROM HealthcareProviderSpecialty
                    WHERE
                        IsActive = true
                        AND PractitionerId != null
                        AND SpecialtyId IN (
                            SELECT Id
                            FROM CareSpecialty
                            WHERE Name LIKE :likeSpec
                        )
                ]) {
                    contactIdsFromCareSpecialty.add(hps.PractitionerId);
                }
            }
            if (!contactIdsFromCareSpecialty.isEmpty()) {
                for (HealthcareProvider hpCs : [
                    SELECT Id
                    FROM HealthcareProvider
                    WHERE Name LIKE 'Dr.%' AND PractitionerId IN :contactIdsFromCareSpecialty
                ]) {
                    bySpecialty.add(hpCs.Id);
                }
            }
            if (bySpecialty.isEmpty()) {
                rows = new List<HealthcareProvider>();
            } else {
                rows = [
                    SELECT
                        Id,
                        Name,
                        PractitionerId,
                        Practitioner.Title,
                        (
                            SELECT HealthcareFacility.Name
                            FROM HealthcarePractitionerFacilities
                            WHERE IsActive = true
                            ORDER BY IsPrimaryFacility DESC NULLS LAST
                        )
                    FROM HealthcareProvider
                    WHERE Name LIKE 'Dr.%' AND Id IN :bySpecialty
                    ORDER BY Name
                    LIMIT 80
                ];
            }
        } else {
            rows = [
                SELECT
                    Id,
                    Name,
                    PractitionerId,
                    Practitioner.Title,
                    (
                        SELECT HealthcareFacility.Name
                        FROM HealthcarePractitionerFacilities
                        WHERE IsActive = true
                        ORDER BY IsPrimaryFacility DESC NULLS LAST
                    )
                FROM HealthcareProvider
                WHERE Name LIKE 'Dr.%'
                ORDER BY Name
                LIMIT 80
            ];
        }

        Set<Id> practitionerContactIds = new Set<Id>();
        for (HealthcareProvider hp : rows) {
            if (hp.PractitionerId != null) {
                practitionerContactIds.add(hp.PractitionerId);
            }
        }
        Map<Id, String> careSpecialtyNameByContact = new Map<Id, String>();
        if (!practitionerContactIds.isEmpty()) {
            for (HealthcareProviderSpecialty hpsHint : [
                SELECT PractitionerId, Specialty.Name, IsPrimarySpecialty
                FROM HealthcareProviderSpecialty
                WHERE IsActive = true AND PractitionerId IN :practitionerContactIds
                ORDER BY IsPrimarySpecialty DESC NULLS LAST
            ]) {
                if (!careSpecialtyNameByContact.containsKey(hpsHint.PractitionerId)) {
                    careSpecialtyNameByContact.put(hpsHint.PractitionerId, hpsHint.Specialty.Name);
                }
            }
        }

        List<ProviderRow> out = new List<ProviderRow>();
        for (HealthcareProvider hp : rows) {
            if (inCity != null && !inCity.contains(hp.Id)) {
                continue;
            }
            List<String> allFacilityNames = new List<String>();
            if (hp.HealthcarePractitionerFacilities != null) {
                for (HealthcarePractitionerFacility hpf : hp.HealthcarePractitionerFacilities) {
                    if (hpf.HealthcareFacility != null && String.isNotBlank(hpf.HealthcareFacility.Name)) {
                        allFacilityNames.add(hpf.HealthcareFacility.Name);
                    }
                }
            }
            String pfName = allFacilityNames.isEmpty() ? null : allFacilityNames[0];
            if (fac != null && !facilityFilterMatches(fac, allFacilityNames)) {
                continue;
            }
            ProviderRow r = new ProviderRow();
            r.healthcareProviderId = hp.Id;
            r.name = hp.Name;
            r.primaryFacilityName = pfName;
            String titleHint = hp.Practitioner != null ? hp.Practitioner.Title : null;
            String careSpecHint = hp.PractitionerId != null
                ? careSpecialtyNameByContact.get(hp.PractitionerId)
                : null;
            r.specialtyHint = String.isNotBlank(titleHint)
                ? titleHint
                : careSpecHint;
            out.add(r);
        }
        return new List<List<ProviderRow>>{ out };
    }
}
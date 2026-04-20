public without sharing class OncoDiscoverySpecialties {
    public class SearchSpecialtiesRequest {
        @InvocableVariable(label='Search Text')
        public String searchText;

        /**
         * Optional HealthcareFacility Id. When set (or when facilityName resolves to exactly
         * one facility), the result is scoped to CareSpecialty rows that are actually staffed
         * by active practitioners at that facility. Taxonomy rows are suppressed in this mode
         * so the patient only sees specialties they can actually book there.
         */
        @InvocableVariable(label='Healthcare Facility Id (optional)')
        public String healthcareFacilityId;

        /**
         * Optional facility name substring (case-insensitive). Used when the caller has not
         * yet resolved the Id. Ignored if healthcareFacilityId is provided.
         */
        @InvocableVariable(label='Facility Name (optional)')
        public String facilityName;
    }
    public class SpecialtyRow {
        @InvocableVariable public String name;
        @InvocableVariable public String shortDescription;
        /** CareSpecialty.SpecialtyType when row comes from CareSpecialty; taxonomy rows leave this blank. */
        @InvocableVariable public String specialtyType;
        /** Populated for CareSpecialty rows; pass to Get Available Slots as careSpecialtyId for department-first slots. */
        @InvocableVariable public String careSpecialtyId;
        /** When facility scope was applied, the resolved HealthcareFacility Id and display name. */
        @InvocableVariable public String scopedFacilityId;
        @InvocableVariable public String scopedFacilityName;
    }

    @InvocableMethod(
        label='Search Specialties'
        description='Lists CareSpecialty (standard department/specialty catalog) and HealthcareProviderTaxonomy names for browsing. When healthcareFacilityId or facilityName is provided, results are scoped to specialties actually staffed by active practitioners at that facility.'
        category='Onco'
    )
    public static List<List<SpecialtyRow>> searchSpecialties(List<SearchSpecialtiesRequest> requests) {
        String q = requests != null && !requests.isEmpty() ? requests[0].searchText : null;
        String facilityId = requests != null && !requests.isEmpty() ? requests[0].healthcareFacilityId : null;
        String facilityName = requests != null && !requests.isEmpty() ? requests[0].facilityName : null;

        Id resolvedFacilityId = null;
        String resolvedFacilityName = null;
        if (String.isNotBlank(facilityId)) {
            try {
                resolvedFacilityId = Id.valueOf(facilityId.trim());
            } catch (Exception e) {
                resolvedFacilityId = null;
            }
        }
        if (resolvedFacilityId == null && String.isNotBlank(facilityName)) {
            String likeName = '%' + facilityName.trim() + '%';
            List<HealthcareFacility> fRows = [
                SELECT Id, Name FROM HealthcareFacility
                WHERE Name LIKE :likeName
                ORDER BY Name
                LIMIT 2
            ];
            if (fRows.size() == 1) {
                resolvedFacilityId = fRows[0].Id;
                resolvedFacilityName = fRows[0].Name;
            }
        }
        if (resolvedFacilityId != null && resolvedFacilityName == null) {
            List<HealthcareFacility> fRows = [SELECT Name FROM HealthcareFacility WHERE Id = :resolvedFacilityId LIMIT 1];
            if (!fRows.isEmpty()) resolvedFacilityName = fRows[0].Name;
        }

        Set<String> seenLower = new Set<String>();
        List<SpecialtyRow> out = new List<SpecialtyRow>();

        if (resolvedFacilityId != null) {
            Set<Id> practitionerIds = new Set<Id>();
            for (HealthcarePractitionerFacility hpf : [
                SELECT PractitionerId
                FROM HealthcarePractitionerFacility
                WHERE HealthcareFacilityId = :resolvedFacilityId AND IsActive = TRUE
            ]) {
                if (hpf.PractitionerId != null) practitionerIds.add(hpf.PractitionerId);
            }
            if (practitionerIds.isEmpty()) {
                return new List<List<SpecialtyRow>>{ out };
            }
            List<String> likeCandidates = buildLikeCandidates(q);
            Map<Id, HealthcareProviderSpecialty> hpsById = new Map<Id, HealthcareProviderSpecialty>();
            if (likeCandidates.isEmpty()) {
                for (HealthcareProviderSpecialty hps : [
                    SELECT SpecialtyId, Specialty.Name, Specialty.SpecialtyCode, Specialty.SpecialtyType,
                           IsPrimarySpecialty
                    FROM HealthcareProviderSpecialty
                    WHERE IsActive = TRUE
                      AND PractitionerId IN :practitionerIds
                    ORDER BY Specialty.Name
                    LIMIT 200
                ]) {
                    hpsById.put(hps.Id, hps);
                }
            } else {
                for (String likeVal : likeCandidates) {
                    for (HealthcareProviderSpecialty hps : [
                        SELECT SpecialtyId, Specialty.Name, Specialty.SpecialtyCode, Specialty.SpecialtyType,
                               IsPrimarySpecialty
                        FROM HealthcareProviderSpecialty
                        WHERE IsActive = TRUE
                          AND PractitionerId IN :practitionerIds
                          AND Specialty.Name LIKE :likeVal
                        ORDER BY Specialty.Name
                        LIMIT 200
                    ]) {
                        hpsById.put(hps.Id, hps);
                    }
                }
            }
            List<HealthcareProviderSpecialty> hpsRows = new List<HealthcareProviderSpecialty>(hpsById.values());
            hpsRows.sort(new HpsByNameComparator());
            for (HealthcareProviderSpecialty hps : hpsRows) {
                if (hps == null || hps.Specialty == null || String.isBlank(hps.Specialty.Name)) continue;
                String key = hps.Specialty.Name.toLowerCase();
                if (seenLower.contains(key)) continue;
                seenLower.add(key);
                SpecialtyRow s = new SpecialtyRow();
                s.name = hps.Specialty.Name;
                s.careSpecialtyId = hps.SpecialtyId != null ? String.valueOf(hps.SpecialtyId) : null;
                s.specialtyType = hps.Specialty.SpecialtyType;
                String code = String.isNotBlank(hps.Specialty.SpecialtyCode) ? ' Code: ' + hps.Specialty.SpecialtyCode : '';
                String st = String.isNotBlank(hps.Specialty.SpecialtyType) ? ' Category: ' + hps.Specialty.SpecialtyType : '';
                s.shortDescription = 'Staffed at ' + resolvedFacilityName + '.' + st + code;
                s.scopedFacilityId = String.valueOf(resolvedFacilityId);
                s.scopedFacilityName = resolvedFacilityName;
                out.add(s);
            }
            return new List<List<SpecialtyRow>>{ out };
        }

        List<CareSpecialty> careRows = new List<CareSpecialty>();
        if (String.isBlank(q)) {
            careRows = [
                SELECT Id, Name, SpecialtyCode, SpecialtyType
                FROM CareSpecialty
                ORDER BY Name
                LIMIT 50
            ];
        } else {
            Map<Id, CareSpecialty> careById = new Map<Id, CareSpecialty>();
            for (String likeVal : buildLikeCandidates(q)) {
                for (CareSpecialty cs : [
                    SELECT Id, Name, SpecialtyCode, SpecialtyType
                    FROM CareSpecialty
                    WHERE Name LIKE :likeVal
                    ORDER BY Name
                    LIMIT 50
                ]) {
                    careById.put(cs.Id, cs);
                }
            }
            careRows = new List<CareSpecialty>(careById.values());
            careRows.sort(new CareSpecialtyByNameComparator());
        }
        for (CareSpecialty cs : careRows) {
            if (cs == null || String.isBlank(cs.Name)) {
                continue;
            }
            String key = cs.Name.toLowerCase();
            if (seenLower.contains(key)) {
                continue;
            }
            seenLower.add(key);
            SpecialtyRow s = new SpecialtyRow();
            s.name = cs.Name;
            s.careSpecialtyId = cs.Id != null ? String.valueOf(cs.Id) : null;
            s.specialtyType = cs.SpecialtyType;
            String code = String.isNotBlank(cs.SpecialtyCode) ? ' Code: ' + cs.SpecialtyCode : '';
            String st = String.isNotBlank(cs.SpecialtyType) ? ' Category: ' + cs.SpecialtyType : '';
            s.shortDescription = 'Care specialty at Onco Global.' + st + code;
            out.add(s);
        }

        List<HealthcareProviderTaxonomy> taxRows = new List<HealthcareProviderTaxonomy>();
        if (String.isBlank(q)) {
            taxRows = [
                SELECT Name
                FROM HealthcareProviderTaxonomy
                ORDER BY Name
                LIMIT 50
            ];
        } else {
            Map<Id, HealthcareProviderTaxonomy> taxById = new Map<Id, HealthcareProviderTaxonomy>();
            for (String likeVal : buildLikeCandidates(q)) {
                for (HealthcareProviderTaxonomy t : [
                    SELECT Id, Name
                    FROM HealthcareProviderTaxonomy
                    WHERE Name LIKE :likeVal
                    ORDER BY Name
                    LIMIT 50
                ]) {
                    taxById.put(t.Id, t);
                }
            }
            taxRows = new List<HealthcareProviderTaxonomy>(taxById.values());
            taxRows.sort(new TaxByNameComparator());
        }
        for (HealthcareProviderTaxonomy t : taxRows) {
            if (t == null || String.isBlank(t.Name)) {
                continue;
            }
            String key = t.Name.toLowerCase();
            if (seenLower.contains(key)) {
                continue;
            }
            seenLower.add(key);
            SpecialtyRow s = new SpecialtyRow();
            s.name = t.Name;
            s.shortDescription = 'Clinical taxonomy / program area at Onco Global: ' + t.Name + '.';
            out.add(s);
        }

        return new List<List<SpecialtyRow>>{ out };
    }

    /**
     * Builds one or more LIKE patterns for a user-supplied search term, accounting for common
     * British/American spelling variants so queries like &quot;paediatric oncology&quot; still match
     * a CareSpecialty stored as &quot;Pediatric Oncology&quot; (and vice versa). Returns an empty list
     * when the input is blank.
     */
    @TestVisible
    private static List<String> buildLikeCandidates(String raw) {
        List<String> out = new List<String>();
        if (String.isBlank(raw)) return out;
        String trimmed = raw.trim();
        Set<String> variants = new Set<String>();
        variants.add(trimmed);
        // Bidirectional spelling swaps. Apply both directions on each pass.
        Map<String, String> brToAm = new Map<String, String>{
            'paediatric' => 'pediatric',
            'paediatrics' => 'pediatrics',
            'oesophageal' => 'esophageal',
            'haematology' => 'hematology',
            'haemato' => 'hemato',
            'haematological' => 'hematological',
            'gynaecology' => 'gynecology',
            'gynaecologic' => 'gynecologic',
            'gynae' => 'gyn',
            'orthopaedic' => 'orthopedic',
            'anaesthesia' => 'anesthesia',
            'tumour' => 'tumor',
            'foetal' => 'fetal',
            'oestrogen' => 'estrogen'
        };
        List<String> toInspect = new List<String>(variants);
        for (String v : toInspect) {
            String lower = v.toLowerCase();
            for (String br : brToAm.keySet()) {
                String am = brToAm.get(br);
                if (lower.contains(br)) {
                    variants.add(replaceCaseInsensitive(v, br, am));
                }
                if (lower.contains(am)) {
                    variants.add(replaceCaseInsensitive(v, am, br));
                }
            }
        }
        for (String v : variants) {
            if (String.isNotBlank(v)) {
                out.add('%' + v + '%');
            }
        }
        return out;
    }

    private static String replaceCaseInsensitive(String input, String needle, String replacement) {
        if (String.isBlank(input) || String.isBlank(needle)) return input;
        // Needles and replacements in this class are plain alphabetic words, so no regex escaping is required.
        return input.replaceAll('(?i)' + needle, replacement);
    }

    public class HpsByNameComparator implements System.Comparator<HealthcareProviderSpecialty> {
        public Integer compare(HealthcareProviderSpecialty a, HealthcareProviderSpecialty b) {
            String an = (a != null && a.Specialty != null && a.Specialty.Name != null) ? a.Specialty.Name : '';
            String bn = (b != null && b.Specialty != null && b.Specialty.Name != null) ? b.Specialty.Name : '';
            return an.compareTo(bn);
        }
    }

    public class CareSpecialtyByNameComparator implements System.Comparator<CareSpecialty> {
        public Integer compare(CareSpecialty a, CareSpecialty b) {
            String an = (a != null && a.Name != null) ? a.Name : '';
            String bn = (b != null && b.Name != null) ? b.Name : '';
            return an.compareTo(bn);
        }
    }

    public class TaxByNameComparator implements System.Comparator<HealthcareProviderTaxonomy> {
        public Integer compare(HealthcareProviderTaxonomy a, HealthcareProviderTaxonomy b) {
            String an = (a != null && a.Name != null) ? a.Name : '';
            String bn = (b != null && b.Name != null) ? b.Name : '';
            return an.compareTo(bn);
        }
    }
}

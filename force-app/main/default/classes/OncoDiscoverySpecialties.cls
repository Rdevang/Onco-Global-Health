public with sharing class OncoDiscoverySpecialties {
    public class SearchSpecialtiesRequest {
        @InvocableVariable(label='Search Text')
        public String searchText;
    }
    public class SpecialtyRow {
        @InvocableVariable public String name;
        @InvocableVariable public String shortDescription;
        /** CareSpecialty.SpecialtyType when row comes from CareSpecialty; taxonomy rows leave this blank. */
        @InvocableVariable public String specialtyType;
        /** Populated for CareSpecialty rows; pass to Get Available Slots as careSpecialtyId for department-first slots. */
        @InvocableVariable public String careSpecialtyId;
    }

    @InvocableMethod(
        label='Search Specialties'
        description='Lists CareSpecialty (standard department/specialty catalog) and HealthcareProviderTaxonomy names for browsing.'
        category='Onco'
    )
    public static List<List<SpecialtyRow>> searchSpecialties(List<SearchSpecialtiesRequest> requests) {
        String q = requests != null && !requests.isEmpty() ? requests[0].searchText : null;
        Set<String> seenLower = new Set<String>();
        List<SpecialtyRow> out = new List<SpecialtyRow>();

        List<CareSpecialty> careRows;
        if (String.isBlank(q)) {
            careRows = [
                SELECT Id, Name, SpecialtyCode, SpecialtyType
                FROM CareSpecialty
                ORDER BY Name
                LIMIT 50
            ];
        } else {
            String likeVal = '%' + q + '%';
            careRows = [
                SELECT Id, Name, SpecialtyCode, SpecialtyType
                FROM CareSpecialty
                WHERE Name LIKE :likeVal
                ORDER BY Name
                LIMIT 50
            ];
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

        List<HealthcareProviderTaxonomy> taxRows;
        if (String.isBlank(q)) {
            taxRows = [
                SELECT Name
                FROM HealthcareProviderTaxonomy
                ORDER BY Name
                LIMIT 50
            ];
        } else {
            String likeVal = '%' + q + '%';
            taxRows = [
                SELECT Name
                FROM HealthcareProviderTaxonomy
                WHERE Name LIKE :likeVal
                ORDER BY Name
                LIMIT 50
            ];
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
}
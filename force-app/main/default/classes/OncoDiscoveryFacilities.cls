public without sharing class OncoDiscoveryFacilities {
    public class FindFacilitiesRequest {
        @InvocableVariable(label='City')
        public String city;
    }
    public class FacilityRow {
        @InvocableVariable public Id facilityId;
        @InvocableVariable public String name;
        @InvocableVariable public String city;
        @InvocableVariable public String accountId;
    }

    @InvocableMethod(
        label='Find Facilities'
        description='Finds HealthcareFacility rows; optional city filter on Account.BillingCity.'
        category='Onco'
    )
    public static List<List<FacilityRow>> findFacilities(List<FindFacilitiesRequest> requests) {
        String city = requests != null && !requests.isEmpty() ? requests[0].city : null;
        List<HealthcareFacility> rows;
        if (String.isBlank(city)) {
            rows = [
                SELECT Id, Name, AccountId, Account.BillingCity
                FROM HealthcareFacility
                WHERE Name LIKE 'Onco Global - %'
                ORDER BY Name
                LIMIT 50
            ];
        } else {
            String c = '%' + city.trim() + '%';
            rows = [
                SELECT Id, Name, AccountId, Account.BillingCity
                FROM HealthcareFacility
                WHERE Name LIKE 'Onco Global - %' AND Account.BillingCity LIKE :c
                ORDER BY Name
                LIMIT 50
            ];
        }
        List<FacilityRow> out = new List<FacilityRow>();
        for (HealthcareFacility f : rows) {
            FacilityRow r = new FacilityRow();
            r.facilityId = f.Id;
            r.name = f.Name;
            r.city = f.Account != null ? f.Account.BillingCity : null;
            r.accountId = f.AccountId;
            out.add(r);
        }
        return new List<List<FacilityRow>>{ out };
    }
}
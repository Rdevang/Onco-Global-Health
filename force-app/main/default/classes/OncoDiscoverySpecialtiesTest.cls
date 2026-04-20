@IsTest
private class OncoDiscoverySpecialtiesTest {

    @TestSetup
    static void setup() {
        CareSpecialty csA = new CareSpecialty(Name = 'Test Medical Oncology', SpecialtyCode = 'TMED');
        CareSpecialty csB = new CareSpecialty(Name = 'Test Radiation Oncology', SpecialtyCode = 'TRAD');
        CareSpecialty csC = new CareSpecialty(Name = 'Test Surgical Oncology', SpecialtyCode = 'TSUR');
        insert new List<CareSpecialty>{ csA, csB, csC };

        Account facAccount = new Account(Name = 'Test Onco Facility Alpha Account');
        insert facAccount;
        HealthcareFacility fac = new HealthcareFacility(
            Name = 'Test Onco Facility Alpha',
            AccountId = facAccount.Id
        );
        insert fac;

        Contact practA = new Contact(FirstName = 'Test', LastName = 'PractitionerA');
        Contact practB = new Contact(FirstName = 'Test', LastName = 'PractitionerB');
        Contact practUnrelated = new Contact(FirstName = 'Test', LastName = 'PractitionerUnrelated');
        insert new List<Contact>{ practA, practB, practUnrelated };

        HealthcarePractitionerFacility hpfA = new HealthcarePractitionerFacility(
            Name = 'Test HPF A',
            HealthcareFacilityId = fac.Id,
            PractitionerId = practA.Id,
            IsActive = true
        );
        HealthcarePractitionerFacility hpfB = new HealthcarePractitionerFacility(
            Name = 'Test HPF B',
            HealthcareFacilityId = fac.Id,
            PractitionerId = practB.Id,
            IsActive = true
        );
        insert new List<HealthcarePractitionerFacility>{ hpfA, hpfB };

        insert new List<HealthcareProviderSpecialty>{
            new HealthcareProviderSpecialty(
                Name = 'HPS A-Medical',
                PractitionerId = practA.Id,
                SpecialtyId = csA.Id,
                IsActive = true,
                IsPrimarySpecialty = true
            ),
            new HealthcareProviderSpecialty(
                Name = 'HPS B-Radiation',
                PractitionerId = practB.Id,
                SpecialtyId = csB.Id,
                IsActive = true,
                IsPrimarySpecialty = true
            ),
            new HealthcareProviderSpecialty(
                Name = 'HPS Unrelated-Surgical',
                PractitionerId = practUnrelated.Id,
                SpecialtyId = csC.Id,
                IsActive = true,
                IsPrimarySpecialty = true
            )
        };
    }

    @IsTest
    static void globalSearch_returnsAllCatalog() {
        OncoDiscoverySpecialties.SearchSpecialtiesRequest req = new OncoDiscoverySpecialties.SearchSpecialtiesRequest();

        Test.startTest();
        List<List<OncoDiscoverySpecialties.SpecialtyRow>> out =
            OncoDiscoverySpecialties.searchSpecialties(new List<OncoDiscoverySpecialties.SearchSpecialtiesRequest>{ req });
        Test.stopTest();

        Set<String> names = new Set<String>();
        for (OncoDiscoverySpecialties.SpecialtyRow r : out[0]) names.add(r.name);
        System.assert(names.contains('Test Medical Oncology'), 'Global list should include Medical');
        System.assert(names.contains('Test Radiation Oncology'), 'Global list should include Radiation');
        System.assert(names.contains('Test Surgical Oncology'), 'Global list should include Surgical (unrelated practitioner)');
    }

    @IsTest
    static void facilityFilterById_returnsOnlyStaffedSpecialties() {
        HealthcareFacility fac = [SELECT Id, Name FROM HealthcareFacility WHERE Name = 'Test Onco Facility Alpha' LIMIT 1];

        OncoDiscoverySpecialties.SearchSpecialtiesRequest req = new OncoDiscoverySpecialties.SearchSpecialtiesRequest();
        req.healthcareFacilityId = fac.Id;

        Test.startTest();
        List<List<OncoDiscoverySpecialties.SpecialtyRow>> out =
            OncoDiscoverySpecialties.searchSpecialties(new List<OncoDiscoverySpecialties.SearchSpecialtiesRequest>{ req });
        Test.stopTest();

        Set<String> names = new Set<String>();
        for (OncoDiscoverySpecialties.SpecialtyRow r : out[0]) {
            names.add(r.name);
            System.assertEquals(fac.Id, r.scopedFacilityId, 'Row should carry scoped facility Id');
            System.assertEquals(fac.Name, r.scopedFacilityName, 'Row should carry scoped facility name');
            System.assert(r.shortDescription.contains('Staffed at'), 'Description should cite staffing');
        }
        System.assertEquals(2, out[0].size(), 'Only two specialties are staffed at this facility');
        System.assert(names.contains('Test Medical Oncology'));
        System.assert(names.contains('Test Radiation Oncology'));
        System.assert(!names.contains('Test Surgical Oncology'),
            'Surgical is only on an unrelated practitioner and must be suppressed');
    }

    @IsTest
    static void facilityFilterByName_resolvesUniqueMatch() {
        OncoDiscoverySpecialties.SearchSpecialtiesRequest req = new OncoDiscoverySpecialties.SearchSpecialtiesRequest();
        req.facilityName = 'Test Onco Facility Alpha';

        List<List<OncoDiscoverySpecialties.SpecialtyRow>> out =
            OncoDiscoverySpecialties.searchSpecialties(new List<OncoDiscoverySpecialties.SearchSpecialtiesRequest>{ req });

        Set<String> names = new Set<String>();
        for (OncoDiscoverySpecialties.SpecialtyRow r : out[0]) names.add(r.name);
        System.assertEquals(2, out[0].size());
        System.assert(names.contains('Test Medical Oncology'));
        System.assert(names.contains('Test Radiation Oncology'));
    }

    @IsTest
    static void facilityFilterByName_noMatchFallsBackToGlobal() {
        OncoDiscoverySpecialties.SearchSpecialtiesRequest req = new OncoDiscoverySpecialties.SearchSpecialtiesRequest();
        req.facilityName = 'Facility That Definitely Does Not Exist XYZ';

        List<List<OncoDiscoverySpecialties.SpecialtyRow>> out =
            OncoDiscoverySpecialties.searchSpecialties(new List<OncoDiscoverySpecialties.SearchSpecialtiesRequest>{ req });

        Set<String> names = new Set<String>();
        for (OncoDiscoverySpecialties.SpecialtyRow r : out[0]) names.add(r.name);
        System.assert(names.contains('Test Surgical Oncology'),
            'Unresolved facility name should fall back to the global catalog');
    }

    @IsTest
    static void agentFacade_searchTextMissAtFacility_listsWhatIsOffered() {
        HealthcareFacility fac = [SELECT Id, Name FROM HealthcareFacility WHERE Name = 'Test Onco Facility Alpha' LIMIT 1];
        OncoDiscoverySpecialtiesAgent.AgentRequest a = new OncoDiscoverySpecialtiesAgent.AgentRequest();
        a.healthcareFacilityId = fac.Id;
        a.searchText = 'Test Surgical Oncology'; // mapped only to the unrelated practitioner, NOT at this facility

        List<OncoDiscoverySpecialtiesAgent.AgentResult> out =
            OncoDiscoverySpecialtiesAgent.searchSpecialtiesForAgent(
                new List<OncoDiscoverySpecialtiesAgent.AgentRequest>{ a }
            );

        System.assertEquals(true, out[0].success);
        System.assert(out[0].message.contains('"Test Surgical Oncology" is not currently available at'),
            'Message should name the missing specialty: ' + out[0].message);
        System.assert(out[0].message.contains('Test Onco Facility Alpha'),
            'Message should name the facility: ' + out[0].message);
        System.assert(
            out[0].message.contains('Test Medical Oncology')
                && out[0].message.contains('Test Radiation Oncology'),
            'Message should list the specialties actually offered at the facility: ' + out[0].message
        );
    }

    @IsTest
    static void agentFacade_resolvedFacilityButNoStaffing_doesNotFalseNegative() {
        // Facility exists but has no practitioners mapped -> tool returns empty rows
        // but we must NOT tell the planner "facility does not exist".
        Account emptyAcct = new Account(Name = 'Empty Onco Facility Account');
        insert emptyAcct;
        HealthcareFacility emptyFac = new HealthcareFacility(
            Name = 'Empty Onco Facility ZZZ',
            AccountId = emptyAcct.Id
        );
        insert emptyFac;

        OncoDiscoverySpecialtiesAgent.AgentRequest a = new OncoDiscoverySpecialtiesAgent.AgentRequest();
        a.healthcareFacilityId = emptyFac.Id;

        List<OncoDiscoverySpecialtiesAgent.AgentResult> out =
            OncoDiscoverySpecialtiesAgent.searchSpecialtiesForAgent(
                new List<OncoDiscoverySpecialtiesAgent.AgentRequest>{ a }
            );

        System.assertEquals(true, out[0].success);
        System.assert(out[0].message.contains('Empty Onco Facility ZZZ'),
            'Message should cite the resolved facility name: ' + out[0].message);
        System.assert(
            out[0].message.contains('No active specialties are currently staffed'),
            'Message should signal empty staffing, not missing facility: ' + out[0].message
        );
        System.assert(
            !out[0].message.contains('Could not find'),
            'Must NOT claim facility is missing when it resolved: ' + out[0].message
        );
    }

    @IsTest
    static void agentFacade_unresolvedFacilityIsCalledOut() {
        OncoDiscoverySpecialtiesAgent.AgentRequest a = new OncoDiscoverySpecialtiesAgent.AgentRequest();
        a.facilityName = 'Facility That Definitely Does Not Exist XYZ';

        List<OncoDiscoverySpecialtiesAgent.AgentResult> out =
            OncoDiscoverySpecialtiesAgent.searchSpecialtiesForAgent(
                new List<OncoDiscoverySpecialtiesAgent.AgentRequest>{ a }
            );

        System.assertEquals(true, out[0].success);
        System.assert(out[0].message.contains('Could not find a facility'),
            'Message should signal unresolved facility: ' + out[0].message);
        System.assert(out[0].message.contains('Facility That Definitely Does Not Exist XYZ'),
            'Message should echo the unresolved name: ' + out[0].message);
    }

    @IsTest
    static void agentFacade_scopedMessageMentionsFacility() {
        HealthcareFacility fac = [SELECT Id, Name FROM HealthcareFacility WHERE Name = 'Test Onco Facility Alpha' LIMIT 1];
        OncoDiscoverySpecialtiesAgent.AgentRequest a = new OncoDiscoverySpecialtiesAgent.AgentRequest();
        a.healthcareFacilityId = fac.Id;

        List<OncoDiscoverySpecialtiesAgent.AgentResult> out =
            OncoDiscoverySpecialtiesAgent.searchSpecialtiesForAgent(
                new List<OncoDiscoverySpecialtiesAgent.AgentRequest>{ a }
            );

        System.assertEquals(true, out[0].success);
        System.assert(out[0].message.contains('Test Onco Facility Alpha'),
            'Agent message should mention the scoped facility');
        System.assert(out[0].specialtiesText.contains('Test Medical Oncology'));
        System.assert(!out[0].specialtiesText.contains('Test Surgical Oncology'));
    }
}

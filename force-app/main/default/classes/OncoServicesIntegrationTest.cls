/**
 * Integration tests against Onco seed data in the org (run after scripts/apex/seed_onco_data.apex).
 */
@IsTest(SeeAllData=true)
private class OncoServicesIntegrationTest {
    @IsTest
    static void discovery_specialties_notEmpty() {
        List<List<OncoDiscoverySpecialties.SpecialtyRow>> rows = OncoDiscoverySpecialties.searchSpecialties(
            new List<OncoDiscoverySpecialties.SearchSpecialtiesRequest>{ new OncoDiscoverySpecialties.SearchSpecialtiesRequest() }
        );
        System.assert(!rows[0].isEmpty());
    }

    @IsTest
    static void discovery_facilities_mumbai() {
        OncoDiscoveryFacilities.FindFacilitiesRequest req = new OncoDiscoveryFacilities.FindFacilitiesRequest();
        req.city = 'Mumbai';
        List<List<OncoDiscoveryFacilities.FacilityRow>> rows = OncoDiscoveryFacilities.findFacilities(
            new List<OncoDiscoveryFacilities.FindFacilitiesRequest>{ req }
        );
        System.assert(!rows[0].isEmpty());
    }

    @IsTest
    static void getSlots_arjun_mumbai() {
        HealthcareFacility fac = [SELECT Id FROM HealthcareFacility WHERE Name = 'Onco Global - Mumbai Andheri' LIMIT 1];
        HealthcareProvider hp = [SELECT Id FROM HealthcareProvider WHERE Name = 'Dr. Arjun Mehta' LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType WHERE Name = 'Onco New Consult' LIMIT 1];
        Datetime fromUtc = Datetime.now().addDays(1);
        Datetime toUtc = fromUtc.addDays(7);
        OncoSchedulingGetSlots.GetSlotsRequest req = new OncoSchedulingGetSlots.GetSlotsRequest();
        req.healthcareFacilityId = fac.Id;
        req.healthcareProviderId = hp.Id;
        req.workTypeId = wt.Id;
        req.fromTimeUtc = fromUtc;
        req.toTimeUtc = toUtc;
        req.timezoneId = 'Asia/Kolkata';
        List<List<OncoSchedulingGetSlots.SlotResult>> out = OncoSchedulingGetSlots.getAvailableSlots(
            new List<OncoSchedulingGetSlots.GetSlotsRequest>{ req }
        );
        System.assert(!out[0].isEmpty(), 'Expected slots');
    }

    @IsTest
    static void knowledge_search() {
        OncoKnowledgeService.SearchRequest req = new OncoKnowledgeService.SearchRequest();
        req.queryText = 'pediatric';
        req.maxResults = 5;
        List<List<OncoKnowledgeService.ArticleHit>> hits = OncoKnowledgeService.searchKnowledge(
            new List<OncoKnowledgeService.SearchRequest>{ req }
        );
        System.assertNotEquals(null, hits);
        System.assertNotEquals(null, hits[0]);
        // SOSL in tests may return zero rows depending on indexing; method is still exercised.
    }

    @IsTest
    static void notification_stub() {
        List<OncoNotificationService.NotifyResult> r = OncoNotificationService.sendReminder(
            new List<OncoNotificationService.NotifyRequest>{ new OncoNotificationService.NotifyRequest() }
        );
        System.assertEquals(false, r[0].success);
    }

    @IsTest
    static void book_reschedule_cancel_list_priya() {
        Account patient = [
            SELECT Id, PersonContactId
            FROM Account
            WHERE IsPersonAccount = true AND PersonEmail = 'priya.sharma@example.com'
            LIMIT 1
        ];
        HealthcareFacility fac = [SELECT Id FROM HealthcareFacility WHERE Name = 'Onco Global - Mumbai Andheri' LIMIT 1];
        HealthcareProvider hp = [SELECT Id FROM HealthcareProvider WHERE Name = 'Dr. Arjun Mehta' LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType WHERE Name = 'Onco New Consult' LIMIT 1];

        OncoSchedulingBook.BookAppointmentRequest br = new OncoSchedulingBook.BookAppointmentRequest();
        br.patientLookupEmail = 'priya.sharma@example.com';
        br.healthcareFacilityId = fac.Id;
        br.healthcareProviderId = hp.Id;
        br.workTypeId = wt.Id;
        Datetime bookStart = Datetime.now().addDays(21).addHours(3);
        br.startTimeUtc = bookStart.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');

        List<OncoSchedulingBook.MutationResult> bookOut = OncoSchedulingBook.bookAppointment(
            new List<OncoSchedulingBook.BookAppointmentRequest>{ br }
        );
        System.assertEquals(true, bookOut[0].success, bookOut[0].message);
        String apptNum = bookOut[0].appointmentNumber;
        System.assertNotEquals(null, apptNum, 'Appointment number should be returned');

        OncoAppointmentManager.ManageRequest rescheduleReq = new OncoAppointmentManager.ManageRequest();
        rescheduleReq.actionType = 'Reschedule';
        rescheduleReq.appointmentNumber = apptNum;
        rescheduleReq.patientLookupEmail = 'priya.sharma@example.com';
        rescheduleReq.newStartTime = bookStart.addHours(2).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
        List<OncoAppointmentManager.ManageResult> resOut = OncoAppointmentManager.manageAppointment(
            new List<OncoAppointmentManager.ManageRequest>{ rescheduleReq }
        );
        System.assertEquals(true, resOut[0].isSuccess, resOut[0].message);

        OncoSchedulingListAppointments.ListApptsRequest lr = new OncoSchedulingListAppointments.ListApptsRequest();
        lr.patientLookupEmail = 'priya.sharma@example.com';
        lr.includePast = true;
        List<List<OncoSchedulingListAppointments.AppointmentRow>> listOut = OncoSchedulingListAppointments.getMyAppointments(
            new List<OncoSchedulingListAppointments.ListApptsRequest>{ lr }
        );
        System.assert(!listOut[0].isEmpty());

        OncoAppointmentManager.ManageRequest cancelReq = new OncoAppointmentManager.ManageRequest();
        cancelReq.actionType = 'Cancel';
        cancelReq.appointmentNumber = apptNum;
        cancelReq.patientLookupEmail = 'priya.sharma@example.com';
        List<OncoAppointmentManager.ManageResult> canOut = OncoAppointmentManager.manageAppointment(
            new List<OncoAppointmentManager.ManageRequest>{ cancelReq }
        );
        System.assertEquals(true, canOut[0].isSuccess, canOut[0].message);
    }

    @IsTest
    static void book_via_lookup_email_and_default_worktype() {
        HealthcareFacility fac = [SELECT Id FROM HealthcareFacility WHERE Name = 'Onco Global - Mumbai Andheri' LIMIT 1];
        HealthcareProvider hp = [SELECT Id FROM HealthcareProvider WHERE Name = 'Dr. Arjun Mehta' LIMIT 1];

        OncoSchedulingBook.BookAppointmentRequest br = new OncoSchedulingBook.BookAppointmentRequest();
        br.patientLookupEmail = 'priya.sharma@example.com';
        br.healthcareFacilityId = fac.Id;
        br.healthcareProviderId = hp.Id;
        br.startTimeUtc = Datetime.now().addDays(22).addHours(3).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');

        List<OncoSchedulingBook.MutationResult> bookOut = OncoSchedulingBook.bookAppointment(
            new List<OncoSchedulingBook.BookAppointmentRequest>{ br }
        );
        System.assertEquals(true, bookOut[0].success, bookOut[0].message);

        OncoAppointmentManager.ManageRequest cancelReq = new OncoAppointmentManager.ManageRequest();
        cancelReq.actionType = 'Cancel';
        cancelReq.appointmentNumber = bookOut[0].appointmentNumber;
        cancelReq.patientLookupEmail = 'priya.sharma@example.com';
        List<OncoAppointmentManager.ManageResult> canOut = OncoAppointmentManager.manageAppointment(
            new List<OncoAppointmentManager.ManageRequest>{ cancelReq }
        );
        System.assertEquals(true, canOut[0].isSuccess, canOut[0].message);
    }

    @IsTest
    static void discovery_providers_bengaluru_medical_oncology() {
        OncoDiscoveryProviders.FindProvidersRequest req = new OncoDiscoveryProviders.FindProvidersRequest();
        req.city = 'Bengaluru';
        req.specialty = 'Medical Oncology';
        List<List<OncoDiscoveryProviders.ProviderRow>> rows = OncoDiscoveryProviders.findProviders(
            new List<OncoDiscoveryProviders.FindProvidersRequest>{ req }
        );
        System.assert(!rows[0].isEmpty(), 'Seed should link Medical Oncology providers in Bengaluru');
    }
}
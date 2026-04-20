@IsTest
private class OncoPatientRegisterTest {

    @IsTest
    static void register_rejectsMissingConsent() {
        OncoPatientRegister.RegisterRequest req = new OncoPatientRegister.RegisterRequest();
        req.firstName = 'Nia';
        req.lastName  = 'Sharma';
        req.email     = 'nia.sharma.test@example.com';
        req.consentToContact = false;

        Test.startTest();
        List<OncoPatientRegister.RegisterResult> out =
            OncoPatientRegister.registerPatient(new List<OncoPatientRegister.RegisterRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, out.size());
        System.assertEquals(false, out[0].success, 'Consent is required');
        System.assert(out[0].message.toLowerCase().contains('consent'), 'Message should reference consent');
    }

    @IsTest
    static void register_rejectsInvalidEmail() {
        OncoPatientRegister.RegisterRequest req = new OncoPatientRegister.RegisterRequest();
        req.firstName = 'Nia';
        req.lastName  = 'Sharma';
        req.email     = 'not-an-email';
        req.consentToContact = true;

        List<OncoPatientRegister.RegisterResult> out =
            OncoPatientRegister.registerPatient(new List<OncoPatientRegister.RegisterRequest>{ req });

        System.assertEquals(false, out[0].success);
        System.assert(out[0].message.toLowerCase().contains('valid'), 'Message should flag invalid email');
    }

    @IsTest
    static void register_rejectsMissingName() {
        OncoPatientRegister.RegisterRequest req = new OncoPatientRegister.RegisterRequest();
        req.firstName = '';
        req.lastName  = 'Sharma';
        req.email     = 'nia.sharma.test@example.com';
        req.consentToContact = true;

        List<OncoPatientRegister.RegisterResult> out =
            OncoPatientRegister.registerPatient(new List<OncoPatientRegister.RegisterRequest>{ req });

        System.assertEquals(false, out[0].success);
    }

    @IsTest
    static void register_createsNewPersonAccount() {
        String email = 'newpatient.test.' + String.valueOf(Crypto.getRandomInteger()).substring(0, 6) + '@example.com';

        OncoPatientRegister.RegisterRequest req = new OncoPatientRegister.RegisterRequest();
        req.firstName   = 'Ava';
        req.lastName    = 'Test-Patient';
        req.email       = email;
        req.mobilePhone = '+14155550111';
        req.city        = 'Mumbai';
        req.dateOfBirth = '1988-05-04';
        req.consentToContact = true;

        Test.startTest();
        List<OncoPatientRegister.RegisterResult> out =
            OncoPatientRegister.registerPatient(new List<OncoPatientRegister.RegisterRequest>{ req });
        Test.stopTest();

        System.assertEquals(true, out[0].success, out[0].message);
        System.assertEquals(false, out[0].wasAlreadyRegistered);
        System.assertEquals(email, out[0].registeredEmail);
        System.assert(out[0].patientDisplayName.contains('Ava'));

        List<Account> created = [
            SELECT Id, FirstName, LastName, PersonEmail, PersonBirthdate, IsPersonAccount
            FROM Account WHERE PersonEmail = :email
        ];
        System.assertEquals(1, created.size(), 'Exactly one Person Account should be created');
        System.assertEquals(true, created[0].IsPersonAccount);
        System.assertEquals('Ava', created[0].FirstName);
        System.assertEquals(Date.newInstance(1988, 5, 4), created[0].PersonBirthdate);
    }

    @IsTest
    static void register_isIdempotentForExistingEmail() {
        String email = 'dup.test.' + String.valueOf(Crypto.getRandomInteger()).substring(0, 6) + '@example.com';

        OncoPatientRegister.RegisterRequest first = new OncoPatientRegister.RegisterRequest();
        first.firstName = 'Dup';
        first.lastName  = 'Patient';
        first.email     = email;
        first.consentToContact = true;
        OncoPatientRegister.registerPatient(new List<OncoPatientRegister.RegisterRequest>{ first });

        OncoPatientRegister.RegisterRequest again = new OncoPatientRegister.RegisterRequest();
        again.firstName = 'Dup';
        again.lastName  = 'Patient';
        again.email     = email;
        again.consentToContact = true;

        Test.startTest();
        List<OncoPatientRegister.RegisterResult> out =
            OncoPatientRegister.registerPatient(new List<OncoPatientRegister.RegisterRequest>{ again });
        Test.stopTest();

        System.assertEquals(true, out[0].success);
        System.assertEquals(true, out[0].wasAlreadyRegistered, 'Second call should short-circuit');
        System.assertEquals(email, out[0].registeredEmail);
        System.assertEquals(1, [SELECT COUNT() FROM Account WHERE PersonEmail = :email],
            'No duplicate Person Account should be created');
    }

    @IsTest
    static void helpers_cover_edge_cases() {
        System.assertEquals(null, OncoPatientRegister.trimOrNull(null));
        System.assertEquals(null, OncoPatientRegister.trimOrNull('   '));
        System.assertEquals('x', OncoPatientRegister.trimOrNull('  x  '));
        System.assertEquals(false, OncoPatientRegister.isLikelyEmail(null));
        System.assertEquals(false, OncoPatientRegister.isLikelyEmail('no-at-sign'));
        System.assertEquals(true,  OncoPatientRegister.isLikelyEmail('a@b.co'));
        System.assertEquals(null, OncoPatientRegister.parseDateOrNull('not-a-date'));
        System.assertEquals(Date.newInstance(2020, 1, 1), OncoPatientRegister.parseDateOrNull('2020-01-01'));
        System.assertEquals('A B', OncoPatientRegister.displayName(' A ', ' B '));
        System.assertEquals('B', OncoPatientRegister.displayName(null, 'B'));
        System.assertEquals('A', OncoPatientRegister.displayName('A', null));
    }
}

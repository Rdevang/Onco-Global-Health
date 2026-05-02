@IsTest
private class OncoEmailServiceTest {

    @IsTest
    static void greetingFor_handlesNullAndBlank() {
        OncoEmailService.EmailContext blank = new OncoEmailService.EmailContext();
        System.assertEquals('Hello,', OncoEmailService.greetingFor(blank));
        System.assertEquals('Hello,', OncoEmailService.greetingFor(null));

        OncoEmailService.EmailContext named = new OncoEmailService.EmailContext();
        named.patientFirstName = '  Ava  ';
        System.assertEquals('Hello Ava,', OncoEmailService.greetingFor(named));
    }

    @IsTest
    static void escape_replacesHtmlMetaCharacters() {
        System.assertEquals('', OncoEmailService.escape(null));
        String escaped = OncoEmailService.escape('<a href="x">A&B\'s</a>');
        System.assert(escaped.contains('&lt;a'));
        System.assert(escaped.contains('&amp;B'));
        System.assert(escaped.contains('&#39;s'));
        System.assert(escaped.contains('&quot;x&quot;'));
    }

    @IsTest
    static void formatWhen_handlesNullAndBadTimezone() {
        System.assertEquals('the scheduled time', OncoEmailService.formatWhen(null, 'Asia/Kolkata'));
        Datetime sample = Datetime.newInstanceGmt(2026, 6, 1, 10, 0, 0);
        String s1 = OncoEmailService.formatWhen(sample, 'Asia/Kolkata');
        System.assert(String.isNotBlank(s1));
        // Bogus timezone falls back to GMT representation without throwing.
        String s2 = OncoEmailService.formatWhen(sample, 'Not/A_Zone');
        System.assert(String.isNotBlank(s2));
    }

    @IsTest
    static void sendPatientWelcome_skipsWhenEmailMissing() {
        OncoEmailService.EmailContext ctx = new OncoEmailService.EmailContext();
        ctx.patientFirstName = 'Ava';
        // No email -> immediate false, no send invocation
        Boolean ok = OncoEmailService.sendPatientWelcome(ctx);
        System.assertEquals(false, ok);
        System.assertEquals(false, OncoEmailService.sendPatientWelcome(null));
    }

    @IsTest
    static void sendPatientWelcome_invokesEmailApi() {
        OncoEmailService.EmailContext ctx = new OncoEmailService.EmailContext();
        ctx.patientFirstName = 'Ava';
        ctx.patientLastName = 'Tester';
        ctx.patientEmail = 'ava.tester+welcome@example.com';

        Test.startTest();
        Boolean ok = OncoEmailService.sendPatientWelcome(ctx);
        Integer invocationsInside = Limits.getEmailInvocations();
        Test.stopTest();

        System.assert(ok, 'Welcome email should be accepted by the platform');
        System.assert(invocationsInside >= 1, 'Email API should have been invoked');
    }

    @IsTest
    static void sendBookingConfirmation_invokesEmailApi() {
        OncoEmailService.EmailContext ctx = baseContext();
        Test.startTest();
        Boolean ok = OncoEmailService.sendBookingConfirmation(ctx);
        Test.stopTest();
        System.assert(ok);
    }

    @IsTest
    static void sendRescheduleNotice_invokesEmailApi() {
        OncoEmailService.EmailContext ctx = baseContext();
        Test.startTest();
        Boolean ok = OncoEmailService.sendRescheduleNotice(ctx);
        Test.stopTest();
        System.assert(ok);
    }

    @IsTest
    static void sendCancellationNotice_invokesEmailApi() {
        OncoEmailService.EmailContext ctx = baseContext();
        Test.startTest();
        Boolean ok = OncoEmailService.sendCancellationNotice(ctx);
        Test.stopTest();
        System.assert(ok);
    }

    @IsTest
    static void sendReminders_invokeEmailApi() {
        OncoEmailService.EmailContext ctx = baseContext();
        Test.startTest();
        Boolean ok24 = OncoEmailService.sendReminder24h(ctx);
        Boolean ok4  = OncoEmailService.sendReminder4h(ctx);
        Test.stopTest();
        System.assert(ok24);
        System.assert(ok4);
    }

    @IsTest
    static void buildContextsForAppointments_emptyInputReturnsEmptyMap() {
        Map<Id, OncoEmailService.EmailContext> out =
            OncoEmailService.buildContextsForAppointments(null);
        System.assertEquals(0, out.size());
        out = OncoEmailService.buildContextsForAppointments(new Set<Id>());
        System.assertEquals(0, out.size());
    }

    private static OncoEmailService.EmailContext baseContext() {
        OncoEmailService.EmailContext ctx = new OncoEmailService.EmailContext();
        ctx.patientFirstName = 'Ava';
        ctx.patientLastName = 'Tester';
        ctx.patientEmail = 'ava.tester+appt@example.com';
        ctx.appointmentNumber = 'SA-TEST-001';
        ctx.appointmentStartUtc = Datetime.now().addDays(1).addHours(2);
        ctx.appointmentTimeZone = 'Asia/Kolkata';
        ctx.facilityName = 'Onco Global - Test Facility';
        ctx.providerName = 'Dr. Test Provider';
        return ctx;
    }
}

@IsTest
private class OncoSchedulingBookTest {
    @IsTest
    static void normalize_plain_email() {
        System.assertEquals('a@b.co', OncoSchedulingBook.normalizePatientLookupEmail(' a@b.co '));
    }

    @IsTest
    static void normalize_json_recipientId() {
        String j = '{"recipientId":"meera.iyer@example.com","subject":"x"}';
        System.assertEquals('meera.iyer@example.com', OncoSchedulingBook.normalizePatientLookupEmail(j));
    }

    @IsTest
    static void normalize_multiline_json_like_planner() {
        String payload =
            '{\n' +
            '  "recipientId" : "meera.iyer@example.com",\n' +
            '  "subject" : "New Patient Appointment Booking",\n' +
            '  "body" : "Booking a new patient appointment for Meera Iyer with Dr. Arjun Mehta at Onco Global - Mumbai Andheri."\n' +
            '}';
        System.assertEquals('meera.iyer@example.com', OncoSchedulingBook.normalizePatientLookupEmail(payload));
    }

    @IsTest
    static void normalize_finds_email_in_noise() {
        System.assertEquals(
            'meera.iyer@example.com',
            OncoSchedulingBook.normalizePatientLookupEmail('recipientId=meera.iyer@example.com, subject=x')
        );
    }
}

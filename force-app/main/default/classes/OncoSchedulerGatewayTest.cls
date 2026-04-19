@IsTest
private class OncoSchedulerGatewayTest {
    @IsTest
    static void generateSlots_weekday_respectsNineToFive() {
        // Monday 2026-04-20 04:00 UTC ~ varies; use fixed GMT window spanning one business day in IST
        Datetime fromUtc = Datetime.newInstanceGmt(2026, 4, 20, 3, 30, 0);
        Datetime toUtc = Datetime.newInstanceGmt(2026, 4, 20, 15, 0, 0);
        List<Datetime> slots = OncoSchedulerGateway.generateSlots(fromUtc, toUtc, 30, 'Asia/Kolkata');
        System.assert(!slots.isEmpty(), 'Expected slots in window');
    }

    @IsTest
    static void getDuration_defaults() {
        System.assertEquals(30, OncoSchedulerGateway.getWorkTypeDurationMinutes(null).intValue());
    }
}
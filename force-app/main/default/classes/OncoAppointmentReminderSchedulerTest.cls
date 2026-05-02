/**
 * Lightweight tests for OncoAppointmentReminderScheduler.
 *
 * The scheduler depends on ServiceAppointment + Person Account data that is
 * cumbersome to bootstrap inside a unit test (Person Account record types,
 * ServiceTerritory, OperatingHours, etc.). We exercise:
 *   - the Schedulable.execute path so a CronTrigger row is created
 *   - the Database.QueryLocator on an org with no qualifying rows so the
 *     batch finishes cleanly
 *
 * Functional coverage of the email send path is provided by
 * OncoEmailServiceTest, which validates the public send methods directly.
 */
@IsTest
private class OncoAppointmentReminderSchedulerTest {

    @IsTest
    static void schedulable_execute_enqueuesBatch() {
        Test.startTest();
        String cron = '0 0 0 ? * * 2099'; // far-future single fire
        Id jobId = System.schedule(
            'Onco Reminder Test ' + String.valueOf(Crypto.getRandomInteger()).substring(0, 6),
            cron,
            new OncoAppointmentReminderScheduler()
        );
        System.assertNotEquals(null, jobId);
        Test.stopTest();

        List<CronTrigger> ct = [SELECT Id, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, ct.size());
    }

    @IsTest
    static void batch_runs_with_no_qualifying_rows() {
        // No appointments meeting the reminder window are guaranteed in a
        // brand-new test context, so the batch should complete with zero work.
        Test.startTest();
        Id batchId = Database.executeBatch(new OncoAppointmentReminderScheduler(), 50);
        Test.stopTest();
        System.assertNotEquals(null, batchId);
    }
}

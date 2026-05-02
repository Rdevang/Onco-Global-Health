/**
 * Schedulable + Batchable Apex that runs on a recurring cadence (recommended
 * every hour) and emails patients two reminders before each appointment:
 *   - 1 day (24 hours) prior
 *   - 4 hours prior
 *
 * Idempotency is enforced via two checkbox fields on ServiceAppointment:
 *   - Reminder_24h_Sent__c
 *   - Reminder_4h_Sent__c
 * Once a reminder is sent the corresponding flag is flipped, so re-runs of
 * the scheduler will not double-send.
 *
 * Scheduling
 * ----------
 * Run anonymous Apex once after deploy:
 *   String cron = '0 0 * * * ?'; // top of every hour
 *   System.schedule('Onco Appointment Reminders', cron, new OncoAppointmentReminderScheduler());
 *
 * Or chain to fire every 30 minutes by scheduling two jobs at minute 0 and 30.
 */
public without sharing class OncoAppointmentReminderScheduler
    implements Schedulable, Database.Batchable<SObject>, Database.Stateful {

    /**
     * Tolerance window applied around each reminder offset. We look for
     * appointments whose start falls within (offset - WINDOW, offset + WINDOW)
     * from now so that an hourly run will catch every appointment exactly
     * once. With a 60-minute window and an hourly cadence this is safe.
     */
    @TestVisible
    private static final Integer WINDOW_MINUTES = 60;

    /** Tracks counts across the batch chain for logging. */
    public Integer sent24h = 0;
    public Integer sent4h = 0;

    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 50);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Datetime now = Datetime.now();
        Datetime lower24 = now.addMinutes(24 * 60 - WINDOW_MINUTES);
        Datetime upper24 = now.addMinutes(24 * 60 + WINDOW_MINUTES);
        Datetime lower4  = now.addMinutes(4 * 60 - WINDOW_MINUTES);
        Datetime upper4  = now.addMinutes(4 * 60 + WINDOW_MINUTES);

        return Database.getQueryLocator([
            SELECT Id, AppointmentNumber, SchedStartTime, TimeZone, Status,
                   ParentRecordId, ServiceTerritoryId,
                   Reminder_24h_Sent__c, Reminder_4h_Sent__c
            FROM ServiceAppointment
            WHERE Status NOT IN ('Canceled', 'Completed')
              AND (
                    (Reminder_24h_Sent__c = false AND SchedStartTime >= :lower24 AND SchedStartTime <= :upper24)
                 OR (Reminder_4h_Sent__c  = false AND SchedStartTime >= :lower4  AND SchedStartTime <= :upper4)
              )
        ]);
    }

    public void execute(Database.BatchableContext bc, List<ServiceAppointment> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }
        Datetime now = Datetime.now();
        Long oneDayMs = 24L * 60L * 60L * 1000L;
        Long fourHourMs = 4L * 60L * 60L * 1000L;
        Long windowMs = WINDOW_MINUTES * 60L * 1000L;

        Set<Id> ids = new Set<Id>();
        for (ServiceAppointment sa : scope) {
            ids.add(sa.Id);
        }
        Map<Id, OncoEmailService.EmailContext> ctxById =
            OncoEmailService.buildContextsForAppointments(ids);

        List<ServiceAppointment> toUpdate = new List<ServiceAppointment>();
        for (ServiceAppointment sa : scope) {
            if (sa.SchedStartTime == null) {
                continue;
            }
            Long deltaMs = sa.SchedStartTime.getTime() - now.getTime();
            OncoEmailService.EmailContext ctx = ctxById.get(sa.Id);
            if (ctx == null || String.isBlank(ctx.patientEmail)) {
                continue;
            }

            Boolean updated = false;
            ServiceAppointment patch = new ServiceAppointment(Id = sa.Id);

            if (sa.Reminder_24h_Sent__c != true
                && Math.abs(deltaMs - oneDayMs) <= windowMs) {
                Boolean ok = OncoEmailService.sendReminder24h(ctx);
                if (ok) {
                    patch.Reminder_24h_Sent__c = true;
                    sent24h++;
                    updated = true;
                }
            }
            if (sa.Reminder_4h_Sent__c != true
                && Math.abs(deltaMs - fourHourMs) <= windowMs) {
                Boolean ok = OncoEmailService.sendReminder4h(ctx);
                if (ok) {
                    patch.Reminder_4h_Sent__c = true;
                    sent4h++;
                    updated = true;
                }
            }
            if (updated) {
                toUpdate.add(patch);
            }
        }

        if (!toUpdate.isEmpty()) {
            Database.update(toUpdate, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'OncoAppointmentReminderScheduler finish: sent24h=' + sent24h + ', sent4h=' + sent4h);
    }
}

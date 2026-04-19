/**
 * Second demo Person Account (not Priya) for patientLookupEmail tests.
 * Idempotent: skips if PersonEmail already exists.
 *
 * Run: sf apex run --file scripts/apex/seed_second_person_patient.apex -o Healthcloud
 */
Database.DMLOptions dmlAllowDupes = new Database.DMLOptions();
dmlAllowDupes.DuplicateRuleHeader.AllowSave = true;
dmlAllowDupes.DuplicateRuleHeader.RunAsCurrentUser = true;

String patientEmail = 'arjun.kapoor@example.com';
if (!Schema.SObjectType.Account.fields.getMap().containsKey('ispersonaccount')) {
    System.debug('[seed_second_person_patient] Person Accounts not enabled; skip.');
} else {
    List<Account> existing = [
        SELECT Id, PersonContactId
        FROM Account
        WHERE PersonEmail = :patientEmail AND IsPersonAccount = TRUE
        LIMIT 1
    ];
    if (!existing.isEmpty()) {
        System.debug('[seed_second_person_patient] Already exists: ' + existing[0].Id);
    } else {
        Id paRtId;
        for (RecordType rt : [
            SELECT Id
            FROM RecordType
            WHERE SobjectType = 'Account' AND IsPersonType = TRUE AND IsActive = TRUE
            LIMIT 1
        ]) {
            paRtId = rt.Id;
        }
        Account pa = new Account();
        pa.FirstName = 'Arjun';
        pa.LastName = 'Kapoor';
        pa.PersonEmail = patientEmail;
        pa.PersonMobilePhone = '+919000000002';
        pa.Description = 'Onco Global demo patient (non-Priya)';
        if (paRtId != null) {
            pa.RecordTypeId = paRtId;
        }
        Database.SaveResult sr = Database.insert(pa, dmlAllowDupes);
        if (sr.isSuccess()) {
            System.debug('[seed_second_person_patient] Inserted Account ' + sr.getId());
        } else {
            for (Database.Error err : sr.getErrors()) {
                System.debug('[seed_second_person_patient] ERROR: ' + err.getMessage());
            }
        }
    }
}

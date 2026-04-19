/**
 * Inserts up to 20 demo Person Accounts (realistic Indian names, emails, +91 phones).
 * Idempotent: skips any PersonEmail that already exists.
 *
 * Run: sf apex run --file scripts/apex/seed_twenty_person_patients.apex -o Healthcloud
 */
Database.DMLOptions dmlAllowDupes = new Database.DMLOptions();
dmlAllowDupes.DuplicateRuleHeader.AllowSave = true;
dmlAllowDupes.DuplicateRuleHeader.RunAsCurrentUser = true;

// { FirstName, LastName, PersonEmail, PersonMobilePhone }
List<List<String>> rows = new List<List<String>>{
    new List<String>{ 'Arjun', 'Kapoor', 'arjun.kapoor@example.com', '+919812340001' },
    new List<String>{ 'Meera', 'Iyer', 'meera.iyer@example.com', '+919812340002' },
    new List<String>{ 'Rohit', 'Menon', 'rohit.menon@example.com', '+919812340003' },
    new List<String>{ 'Ananya', 'Reddy', 'ananya.reddy@example.com', '+919812340004' },
    new List<String>{ 'Vikram', 'Joshi', 'vikram.joshi@example.com', '+919812340005' },
    new List<String>{ 'Kavitha', 'Nair', 'kavitha.nair@example.com', '+919812340006' },
    new List<String>{ 'Siddharth', 'Rao', 'siddharth.rao@example.com', '+919812340007' },
    new List<String>{ 'Deepa', 'Krishnan', 'deepa.krishnan@example.com', '+919812340008' },
    new List<String>{ 'Amit', 'Verma', 'amit.verma@example.com', '+919812340009' },
    new List<String>{ 'Pooja', 'Desai', 'pooja.desai@example.com', '+919812340010' },
    new List<String>{ 'Karthik', 'Pillai', 'karthik.pillai@example.com', '+919812340011' },
    new List<String>{ 'Sunita', 'Ghosh', 'sunita.ghosh@example.com', '+919812340012' },
    new List<String>{ 'Rahul', 'Bansal', 'rahul.bansal@example.com', '+919812340013' },
    new List<String>{ 'Divya', 'Saxena', 'divya.saxena@example.com', '+919812340014' },
    new List<String>{ 'Varun', 'Malhotra', 'varun.malhotra@example.com', '+919812340015' },
    new List<String>{ 'Neha', 'Kulkarni', 'neha.kulkarni@example.com', '+919812340016' },
    new List<String>{ 'Aditya', 'Choudhary', 'aditya.choudhary@example.com', '+919812340017' },
    new List<String>{ 'Ritu', 'Agarwal', 'ritu.agarwal@example.com', '+919812340018' },
    new List<String>{ 'Manish', 'Tiwari', 'manish.tiwari@example.com', '+919812340019' },
    new List<String>{ 'Swati', 'Bhatt', 'swati.bhatt@example.com', '+919812340020' }
};

if (!Schema.SObjectType.Account.fields.getMap().containsKey('ispersonaccount')) {
    System.debug('[seed_twenty_person_patients] Person Accounts not enabled; abort.');
} else {
    Set<String> wantEmails = new Set<String>();
    for (List<String> r : rows) {
        wantEmails.add(r[2]);
    }
    Set<String> haveEmails = new Set<String>();
    for (Account a : [
        SELECT PersonEmail
        FROM Account
        WHERE IsPersonAccount = TRUE AND PersonEmail IN :wantEmails
    ]) {
        haveEmails.add(a.PersonEmail);
    }

    Id paRtId;
    for (RecordType rt : [
        SELECT Id
        FROM RecordType
        WHERE SobjectType = 'Account' AND IsPersonType = TRUE AND IsActive = TRUE
        LIMIT 1
    ]) {
        paRtId = rt.Id;
    }

    List<Account> toInsert = new List<Account>();
    for (List<String> r : rows) {
        String em = r[2];
        if (haveEmails.contains(em)) {
            continue;
        }
        Account pa = new Account();
        pa.FirstName = r[0];
        pa.LastName = r[1];
        pa.PersonEmail = em;
        pa.PersonMobilePhone = r[3];
        pa.Description = 'Onco Global seeded demo patient';
        if (paRtId != null) {
            pa.RecordTypeId = paRtId;
        }
        toInsert.add(pa);
    }

    if (toInsert.isEmpty()) {
        System.debug('[seed_twenty_person_patients] All ' + rows.size() + ' emails already present; nothing to insert.');
    } else {
        List<Database.SaveResult> srs = Database.insert(toInsert, dmlAllowDupes);
        Integer ok = 0;
        for (Integer i = 0; i < srs.size(); i++) {
            if (srs[i].isSuccess()) {
                ok++;
            } else {
                for (Database.Error err : srs[i].getErrors()) {
                    System.debug('[seed_twenty_person_patients] Row ' + i + ' ERROR: ' + err.getMessage());
                }
            }
        }
        System.debug('[seed_twenty_person_patients] Inserted ' + ok + ' of ' + toInsert.size() + ' Person Account(s).');
    }
}

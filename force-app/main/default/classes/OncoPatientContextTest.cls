@IsTest
private class OncoPatientContextTest {
    @IsTest
    static void internalUser_returnsErrorOrContact() {
        OncoPatientContext.PatientContextRequest req = new OncoPatientContext.PatientContextRequest();
        req.invoke = true;
        List<OncoPatientContext.PatientContextResult> rows = OncoPatientContext.getCurrentPatientContext(
            new List<OncoPatientContext.PatientContextRequest>{ req }
        );
        // Internal users typically have no ContactId
        System.assertNotEquals(null, rows[0]);
    }
}
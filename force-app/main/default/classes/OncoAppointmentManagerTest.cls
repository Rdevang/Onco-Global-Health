@IsTest
private class OncoAppointmentManagerTest {
    @IsTest
    static void manageAppointment_rejectsUnknownAction() {
        OncoAppointmentManager.ManageRequest req = new OncoAppointmentManager.ManageRequest();
        req.actionType = 'noop';
        req.appointmentId = '000000000000000AAA';
        List<OncoAppointmentManager.ManageResult> rows = OncoAppointmentManager.manageAppointment(
            new List<OncoAppointmentManager.ManageRequest>{ req }
        );
        System.assertEquals(1, rows.size());
        System.assertEquals(false, rows[0].isSuccess);
    }
}

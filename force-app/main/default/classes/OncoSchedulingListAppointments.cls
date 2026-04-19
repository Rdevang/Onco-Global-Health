public with sharing class OncoSchedulingListAppointments {
    public class ListApptsRequest {
        @InvocableVariable(required=true label='Patient Account Id')
        public String patientAccountId;
        @InvocableVariable(label='Include Past')
        public Boolean includePast;
    }

    public class AppointmentRow {
        @InvocableVariable public String serviceAppointmentId;
        @InvocableVariable public String appointmentNumber;
        @InvocableVariable public Datetime startTime;
        @InvocableVariable public Datetime endTime;
        @InvocableVariable public String status;
        @InvocableVariable public String workTypeName;
        @InvocableVariable public String territoryName;
    }

    @InvocableMethod(
        label='Get My Appointments'
        description='Lists ServiceAppointments for a patient Account (ParentRecordId).'
        category='Onco'
    )
    public static List<List<AppointmentRow>> getMyAppointments(List<ListApptsRequest> requests) {
        List<List<AppointmentRow>> wrap = new List<List<AppointmentRow>>();
        if (requests == null || requests.isEmpty()) {
            wrap.add(new List<AppointmentRow>());
            return wrap;
        }
        ListApptsRequest req = requests[0];
        if (String.isBlank(req.patientAccountId)) {
            wrap.add(new List<AppointmentRow>());
            return wrap;
        }
        Boolean past = req.includePast == true;
        Datetime now = System.now();
        List<ServiceAppointment> rows;
        if (past) {
            rows = [
                SELECT Id, AppointmentNumber, SchedStartTime, SchedEndTime, Status, WorkType.Name, ServiceTerritory.Name
                FROM ServiceAppointment
                WHERE ParentRecordId = :req.patientAccountId
                ORDER BY SchedStartTime DESC
                LIMIT 50
            ];
        } else {
            rows = [
                SELECT Id, AppointmentNumber, SchedStartTime, SchedEndTime, Status, WorkType.Name, ServiceTerritory.Name
                FROM ServiceAppointment
                WHERE ParentRecordId = :req.patientAccountId AND SchedStartTime >= :now
                ORDER BY SchedStartTime ASC
                LIMIT 50
            ];
        }
        List<AppointmentRow> out = new List<AppointmentRow>();
        for (ServiceAppointment sa : rows) {
            AppointmentRow a = new AppointmentRow();
            a.serviceAppointmentId = sa.Id;
            a.appointmentNumber = sa.AppointmentNumber;
            a.startTime = sa.SchedStartTime;
            a.endTime = sa.SchedEndTime;
            a.status = sa.Status;
            a.workTypeName = sa.WorkType != null ? sa.WorkType.Name : null;
            a.territoryName = sa.ServiceTerritory != null ? sa.ServiceTerritory.Name : null;
            out.add(a);
        }
        wrap.add(out);
        return wrap;
    }
}
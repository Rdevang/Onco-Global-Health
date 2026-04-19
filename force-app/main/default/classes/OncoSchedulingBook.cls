public with sharing class OncoSchedulingBook {
    private static final String DEFAULT_WORK_TYPE_NAME = 'Onco New Consult';

    public class BookAppointmentRequest {
        @InvocableVariable(
            required = true
            label = 'Patient lookup email'
            description = 'Plain email the patient confirmed; resolves Person Account. Users do not provide Salesforce record Ids.'
        )
        public String patientLookupEmail;
        @InvocableVariable(required = true label = 'Healthcare Facility Id')
        public String healthcareFacilityId;
        @InvocableVariable(required = true label = 'Healthcare Provider Id')
        public String healthcareProviderId;
        @InvocableVariable(
            label = 'Work Type Id'
            description = 'Scheduler WorkType Id. Omit to use default Onco New Consult when present in the org.'
        )
        public String workTypeId;
        /**
         * ISO 8601 UTC string (e.g. 2026-04-20T03:54:11Z). Required. Agentforce sends this as text, not Apex Datetime.
         */
        @InvocableVariable(required = true label = 'Start Time (UTC) ISO 8601')
        public String startTimeUtc;
    }

    public class MutationResult {
        @InvocableVariable public Boolean success;
        /** Display number from ServiceAppointment (AppointmentNumber, or Name if blank). */
        @InvocableVariable(
            label = 'Appointment Number'
            description = 'Human-readable appointment number for confirmations.'
        )
        public String appointmentNumber;
        /** Scheduled start in UTC (ISO 8601). */
        @InvocableVariable(
            label = 'Scheduled Start (UTC) ISO'
            description = 'Appointment SchedStartTime as ISO 8601 UTC.'
        )
        public String scheduledStartTimeUtc;
        /** Scheduled end in UTC (ISO 8601). */
        @InvocableVariable(
            label = 'Scheduled End (UTC) ISO'
            description = 'Appointment SchedEndTime as ISO 8601 UTC.'
        )
        public String scheduledEndTimeUtc;
        /** IANA timezone from ServiceAppointment.TimeZone when set. */
        @InvocableVariable(label = 'Appointment Time Zone') public String appointmentTimeZone;
        @InvocableVariable public String message;
    }

    @InvocableMethod(
        label='Book Appointment'
        description='Creates a ServiceAppointment and AssignedResource. Patient identity is email only (no Account or Contact Ids from the caller).'
        category='Onco'
    )
    public static List<MutationResult> bookAppointment(List<BookAppointmentRequest> requests) {
        MutationResult r = new MutationResult();
        if (requests == null || requests.isEmpty()) {
            r.success = false;
            r.message = 'No request';
            return new List<MutationResult>{ r };
        }
        BookAppointmentRequest req = requests[0];
        try {
            OncoPatientEmailLookup.PersonMatch match = OncoPatientEmailLookup.findPersonByEmail(req.patientLookupEmail);
            String acctIdStr = match != null && match.accountId != null ? String.valueOf(match.accountId) : null;
            String contactIdStr =
                match != null && match.personContactId != null ? String.valueOf(match.personContactId) : null;

            String wtId = req.workTypeId;
            if (String.isBlank(wtId)) {
                List<WorkType> wts = [
                    SELECT Id
                    FROM WorkType
                    WHERE Name = :DEFAULT_WORK_TYPE_NAME
                    LIMIT 1
                ];
                if (!wts.isEmpty()) {
                    wtId = wts[0].Id;
                }
            }
            Datetime startDt = parseStartTimeUtc(req.startTimeUtc);
            if (String.isBlank(acctIdStr) || String.isBlank(req.healthcareFacilityId) || String.isBlank(req.healthcareProviderId)
                || String.isBlank(wtId) || startDt == null) {
                r.success = false;
                r.message = 'Missing or invalid inputs (patient lookup email must match a Person Account, facility, provider, work type, start time ISO UTC).';
                return new List<MutationResult>{ r };
            }
            Id territoryId = OncoSchedulerGateway.getTerritoryIdForFacility(req.healthcareFacilityId);
            Id resourceId = OncoSchedulerGateway.getServiceResourceIdForProvider(req.healthcareProviderId);
            Decimal durDec = OncoSchedulerGateway.getWorkTypeDurationMinutes(wtId);
            Integer dur = durDec.intValue();
            if (territoryId == null || resourceId == null) {
                r.success = false;
                r.message = 'Territory or ServiceResource not found.';
                return new List<MutationResult>{ r };
            }
            Datetime endT = startDt.addMinutes(dur);
            ServiceAppointment sa = new ServiceAppointment(
                ParentRecordId = acctIdStr,
                ContactId = String.isNotBlank(contactIdStr) ? contactIdStr : null,
                WorkTypeId = wtId,
                ServiceTerritoryId = territoryId,
                EarliestStartTime = startDt.addDays(-1),
                DueDate = startDt.addDays(1),
                SchedStartTime = startDt,
                SchedEndTime = endT,
                Status = 'Scheduled',
                Subject = 'Onco booking',
                Description = 'Booked via OncoSchedulingBook'
            );
            insert sa;
            insert new AssignedResource(ServiceAppointmentId = sa.Id, ServiceResourceId = resourceId);
            ServiceAppointment created = [
                SELECT Id, AppointmentNumber, SchedStartTime, SchedEndTime, TimeZone, Subject
                FROM ServiceAppointment
                WHERE Id = :sa.Id
                LIMIT 1
            ];
            r.success = true;
            r.appointmentNumber = String.isNotBlank(created.AppointmentNumber)
                ? created.AppointmentNumber
                : (String.isNotBlank(created.Subject) ? created.Subject : String.valueOf(created.Id));
            r.scheduledStartTimeUtc = formatIsoUtc(created.SchedStartTime);
            r.scheduledEndTimeUtc = formatIsoUtc(created.SchedEndTime);
            r.appointmentTimeZone = created.TimeZone;
            r.message =
                'Booked. Appointment number '
                + r.appointmentNumber
                + '. Start (UTC): '
                + r.scheduledStartTimeUtc
                + (String.isNotBlank(r.appointmentTimeZone) ? '. Time zone: ' + r.appointmentTimeZone : '')
                + '.';
            return new List<MutationResult>{ r };
        } catch (Exception e) {
            r.success = false;
            r.message = e.getMessage();
            return new List<MutationResult>{ r };
        }
    }

    /**
     * Parses ISO 8601 UTC from Agentforce / Flow (string). Aligns with OncoSchedulingSlotsAgent slot lines.
     */
    private static Datetime parseStartTimeUtc(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        String s = raw.trim();
        if (s.endsWithIgnoreCase('z')) {
            s = s.substring(0, s.length() - 1).trim();
        }
        s = s.replace('T', ' ');
        if (s.length() >= 19) {
            try {
                return Datetime.valueOfGmt(s.substring(0, 19));
            } catch (Exception e) {
                return null;
            }
        }
        return null;
    }

    private static String formatIsoUtc(Datetime d) {
        if (d == null) {
            return null;
        }
        return d.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
    }
}

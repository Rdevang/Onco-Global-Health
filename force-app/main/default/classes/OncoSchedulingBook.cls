public with sharing class OncoSchedulingBook {
    private static final String DEFAULT_WORK_TYPE_NAME = 'Onco New Consult';

    /**
     * Resolves Person Accounts by email without relying on the caller's row access (Agent / Experience guest).
     */
    private without sharing class PatientEmailResolver {
        List<Account> findByPersonEmail(String em) {
            return [
                SELECT Id, PersonContactId
                FROM Account
                WHERE IsPersonAccount = TRUE AND PersonEmail = :em
                LIMIT 1
            ];
        }
    }

    public class BookAppointmentRequest {
        @InvocableVariable(
            label = 'Patient Account Id'
            description = 'Person Account Id for ParentRecordId. Omit when Patient lookup email is set.'
        )
        public String patientAccountId;
        @InvocableVariable(
            label = 'Patient lookup email'
            description = 'Plain Person Account email when Account Id is unknown. If a JSON or structured value is sent, the first email address in the text is used.'
        )
        public String patientLookupEmail;
        @InvocableVariable(label = 'Patient Contact Id')
        public String patientContactId;
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
        @InvocableVariable public String serviceAppointmentId;
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
        description='Creates a ServiceAppointment and AssignedResource.'
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
            String acctIdStr = req.patientAccountId;
            String contactIdStr = req.patientContactId;
            if (String.isBlank(acctIdStr)) {
                String em = normalizePatientLookupEmail(req.patientLookupEmail);
                if (String.isNotBlank(em)) {
                    List<Account> accRows = new PatientEmailResolver().findByPersonEmail(em);
                    if (!accRows.isEmpty()) {
                        acctIdStr = accRows[0].Id;
                        if (String.isBlank(contactIdStr) && accRows[0].PersonContactId != null) {
                            contactIdStr = accRows[0].PersonContactId;
                        }
                    }
                }
            }
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
                r.message = 'Missing or invalid inputs (patient Account or lookup email, facility, provider, work type, start time ISO UTC).';
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
            r.serviceAppointmentId = created.Id;
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

    /**
     * Planner/LLM sometimes passes JSON blobs or map-like strings instead of a bare email.
     * Extracts the first RFC-like address for PersonEmail lookup.
     */
    @TestVisible
    private static String normalizePatientLookupEmail(String raw) {
        if (String.isBlank(raw)) {
            return null;
        }
        String s = raw.trim();
        if (s.startsWith('{')) {
            try {
                Object o = JSON.deserializeUntyped(s);
                if (o instanceof Map<String, Object>) {
                    Map<String, Object> m = (Map<String, Object>) o;
                    for (String k : new List<String>{ 'recipientId', 'email', 'personEmail' }) {
                        if (m.containsKey(k) && m.get(k) != null) {
                            String v = String.valueOf(m.get(k)).trim();
                            String extracted = extractFirstEmail(v);
                            if (String.isNotBlank(extracted)) {
                                return extracted;
                            }
                        }
                    }
                }
            } catch (Exception e) {
                // Non-JSON (e.g. {recipientId=me@x.com, ...}); fall through to regex on full string
            }
        }
        return extractFirstEmail(s);
    }

    private static String extractFirstEmail(String s) {
        if (String.isBlank(s)) {
            return null;
        }
        Matcher m = Pattern.compile('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}').matcher(s);
        return m.find() ? m.group() : null;
    }
}
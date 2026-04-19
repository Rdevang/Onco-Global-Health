/**
 * End-to-end smoke test that drives every agent-facing invocable in sequence,
 * using only human inputs (names, email, appointment number) — never a Salesforce
 * record Id supplied by the user.
 *
 * Flow:
 *   1. Search Oncology Specialties -> capture plannerReferenceText (CareSpecialty Id)
 *   2. Get Available Slots for Medical Oncology at a fixed facility (department-first)
 *      -> capture plannerReferenceText (HealthcareProvider Id per slot)
 *   3. Book Appointment with patient email only
 *   4. List My Appointments by patient email
 *   5. Manage Appointment -> reschedule by appointment number + email
 *   6. Manage Appointment -> cancel by appointment number + email
 *
 * The script aborts with a descriptive System.assert when an invariant breaks
 * (no record Ids leaked in user-visible text, booking succeeds, list sees the
 * booked appointment, reschedule + cancel round-trip).
 *
 * Usage:
 *   sf apex run --file scripts/apex/smoke_test_agent_flow.apex -o <alias>
 */

String PATIENT_EMAIL;
String FACILITY_NAME = 'Onco Global - Mumbai Powai';
String SPECIALTY_NAME = 'Medical Oncology';

// ---------- Fixture: pick a patient with an email ----------
List<Account> emailPatients = [
    SELECT Id, Name, PersonEmail FROM Account
    WHERE IsPersonAccount = true AND PersonEmail != null
    ORDER BY PersonEmail LIMIT 1
];
System.assert(!emailPatients.isEmpty(), 'No Person Account with email found.');
PATIENT_EMAIL = emailPatients[0].PersonEmail;
System.debug('[Smoke] Patient: ' + emailPatients[0].Name + ' <' + PATIENT_EMAIL + '>');

// Facility Id is a fixture (not user-supplied) — the agent normally gets it from
// "Find Cancer Care Facilities", which is a separate discovery path.
List<HealthcareFacility> facilities = [
    SELECT Id, Name FROM HealthcareFacility WHERE Name = :FACILITY_NAME LIMIT 1
];
System.assert(!facilities.isEmpty(), 'Fixture facility missing: ' + FACILITY_NAME);
Id facilityId = facilities[0].Id;

// ---------- 1. Search Oncology Specialties ----------
OncoDiscoverySpecialtiesAgent.AgentRequest specReq = new OncoDiscoverySpecialtiesAgent.AgentRequest();
specReq.searchText = null;
List<OncoDiscoverySpecialtiesAgent.AgentResult> specOut = OncoDiscoverySpecialtiesAgent.searchSpecialtiesForAgent(
    new List<OncoDiscoverySpecialtiesAgent.AgentRequest>{ specReq }
);
System.assertEquals(1, specOut.size(), 'Specialties wrapper returned wrong shape.');
System.assertEquals(true, specOut[0].success, 'Specialties call failed: ' + specOut[0].message);
System.debug('[Smoke] specialtiesText:\n' + specOut[0].specialtiesText);
System.debug('[Smoke] plannerReferenceText (specialties):\n' + specOut[0].plannerReferenceText);

// Invariant: user-facing text MUST NOT contain record-Id markers.
System.assert(
    !specOut[0].specialtiesText.containsIgnoreCase('CareSpecialty Id:'),
    'User-facing specialtiesText leaked record Id label.'
);
System.assert(
    specOut[0].specialtiesText.containsIgnoreCase(SPECIALTY_NAME),
    'Expected ' + SPECIALTY_NAME + ' in specialtiesText.'
);
// plannerReferenceText must carry the CareSpecialty Id for the department-first call.
System.assert(
    specOut[0].plannerReferenceText.containsIgnoreCase('CareSpecialty Id:'),
    'plannerReferenceText missing CareSpecialty Id line.'
);

// Extract the Medical Oncology CareSpecialty Id from plannerReferenceText.
String careSpecialtyId;
for (String line : specOut[0].plannerReferenceText.split('\n')) {
    if (line.containsIgnoreCase(SPECIALTY_NAME) && line.containsIgnoreCase('CareSpecialty Id:')) {
        Integer idx = line.indexOfIgnoreCase('CareSpecialty Id:') + 'CareSpecialty Id:'.length();
        careSpecialtyId = line.substring(idx).trim();
        break;
    }
}
System.assert(String.isNotBlank(careSpecialtyId), 'Could not extract CareSpecialty Id from plannerReferenceText.');
System.debug('[Smoke] CareSpecialty Id (internal): ' + careSpecialtyId);

// ---------- 2. Get Available Slots (department-first) ----------
OncoSchedulingSlotsAgent.AgentRequest slotReq = new OncoSchedulingSlotsAgent.AgentRequest();
slotReq.healthcareFacilityId = facilityId;
slotReq.careSpecialtyId = careSpecialtyId;
List<OncoSchedulingSlotsAgent.AgentResult> slotOut = OncoSchedulingSlotsAgent.getSlotsForAgent(
    new List<OncoSchedulingSlotsAgent.AgentRequest>{ slotReq }
);
System.assertEquals(1, slotOut.size(), 'Slots wrapper returned wrong shape.');
System.assertEquals(true, slotOut[0].success, 'Slots call failed: ' + slotOut[0].message);
System.debug('[Smoke] slotsText:\n' + slotOut[0].slotsText);
System.debug('[Smoke] plannerReferenceText (slots):\n' + slotOut[0].plannerReferenceText);

System.assert(
    !slotOut[0].slotsText.containsIgnoreCase('HealthcareProvider Id:'),
    'User-facing slotsText leaked record Id label.'
);
System.assert(
    slotOut[0].plannerReferenceText.containsIgnoreCase('HealthcareProvider Id:'),
    'plannerReferenceText missing HealthcareProvider Id line.'
);

// Extract first slot's start time + provider Id from plannerReferenceText.
String firstSlotStart;
String firstSlotProviderId;
for (String line : slotOut[0].plannerReferenceText.split('\n')) {
    if (line.containsIgnoreCase('Start (UTC):') && line.containsIgnoreCase('HealthcareProvider Id:')) {
        Integer s = line.indexOfIgnoreCase('Start (UTC):') + 'Start (UTC):'.length();
        Integer e = line.indexOfIgnoreCase('| HealthcareProvider Id:');
        firstSlotStart = line.substring(s, e).trim();
        Integer p = line.indexOfIgnoreCase('HealthcareProvider Id:') + 'HealthcareProvider Id:'.length();
        String tail = line.substring(p).trim();
        // tail is either just the Id, or "<Id> | <providerName>"
        Integer pipe = tail.indexOf('|');
        firstSlotProviderId = (pipe > 0 ? tail.substring(0, pipe).trim() : tail);
        break;
    }
}
System.assert(String.isNotBlank(firstSlotStart), 'No slot start extracted.');
System.assert(String.isNotBlank(firstSlotProviderId), 'No provider Id extracted.');
System.debug('[Smoke] First slot: ' + firstSlotStart + ' provider: ' + firstSlotProviderId);

// Convert "2026-04-20 03:54:11" -> ISO 8601 with Z
String startIso = firstSlotStart.replace(' ', 'T') + 'Z';

// ---------- 3. Book Appointment ----------
OncoSchedulingBook.BookAppointmentRequest bookReq = new OncoSchedulingBook.BookAppointmentRequest();
bookReq.patientLookupEmail = PATIENT_EMAIL;
bookReq.healthcareFacilityId = facilityId;
bookReq.healthcareProviderId = firstSlotProviderId;
bookReq.startTimeUtc = startIso;
List<OncoSchedulingBook.MutationResult> bookOut = OncoSchedulingBook.bookAppointment(
    new List<OncoSchedulingBook.BookAppointmentRequest>{ bookReq }
);
System.assertEquals(1, bookOut.size(), 'Book wrapper returned wrong shape.');
System.assertEquals(true, bookOut[0].success, 'Booking failed: ' + bookOut[0].message);
System.debug('[Smoke] Booked: ' + bookOut[0].message);
String apptNumber = bookOut[0].appointmentNumber;
System.assert(String.isNotBlank(apptNumber), 'Appointment number missing in booking response.');
System.assert(
    !bookOut[0].message.contains('001'),
    'Booking message should not contain a 001 (Account) record Id.'
);

// ---------- 4. List My Appointments ----------
OncoListAppointmentsAgent.AgentRequest listReq = new OncoListAppointmentsAgent.AgentRequest();
listReq.patientLookupEmail = PATIENT_EMAIL;
listReq.includePast = false;
List<OncoListAppointmentsAgent.AgentResult> listOut = OncoListAppointmentsAgent.listAppointmentsForAgent(
    new List<OncoListAppointmentsAgent.AgentRequest>{ listReq }
);
System.assertEquals(1, listOut.size(), 'List wrapper returned wrong shape.');
System.assertEquals(true, listOut[0].success, 'List call failed: ' + listOut[0].message);
System.debug('[Smoke] appointmentsText:\n' + listOut[0].appointmentsText);
System.assert(
    listOut[0].appointmentsText.contains(apptNumber),
    'List appointments did not include booked appointment ' + apptNumber
);
System.assert(
    !listOut[0].appointmentsText.containsIgnoreCase('ServiceAppointment Id'),
    'List leaked a record Id label.'
);

// ---------- 5. Manage Appointment -> reschedule ----------
OncoAppointmentManager.ManageRequest resReq = new OncoAppointmentManager.ManageRequest();
resReq.actionType = 'Reschedule';
resReq.appointmentNumber = apptNumber;
resReq.patientLookupEmail = PATIENT_EMAIL;
// Push the slot 1 hour later in UTC.
Datetime parsedStart = Datetime.valueOfGmt(firstSlotStart.substring(0, 19));
resReq.newStartTime = parsedStart.addHours(1).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');
List<OncoAppointmentManager.ManageResult> resOut = OncoAppointmentManager.manageAppointment(
    new List<OncoAppointmentManager.ManageRequest>{ resReq }
);
System.assertEquals(1, resOut.size(), 'Reschedule wrapper returned wrong shape.');
System.assertEquals(true, resOut[0].isSuccess, 'Reschedule failed: ' + resOut[0].message);
System.debug('[Smoke] Reschedule: ' + resOut[0].message);

// ---------- 6. Manage Appointment -> cancel ----------
OncoAppointmentManager.ManageRequest canReq = new OncoAppointmentManager.ManageRequest();
canReq.actionType = 'Cancel';
canReq.appointmentNumber = apptNumber;
canReq.patientLookupEmail = PATIENT_EMAIL;
List<OncoAppointmentManager.ManageResult> canOut = OncoAppointmentManager.manageAppointment(
    new List<OncoAppointmentManager.ManageRequest>{ canReq }
);
System.assertEquals(1, canOut.size(), 'Cancel wrapper returned wrong shape.');
System.assertEquals(true, canOut[0].isSuccess, 'Cancel failed: ' + canOut[0].message);
System.debug('[Smoke] Cancel: ' + canOut[0].message);

// ---------- Negative check: wrong email cannot see the appointment ----------
OncoAppointmentManager.ManageRequest wrongReq = new OncoAppointmentManager.ManageRequest();
wrongReq.actionType = 'Cancel';
wrongReq.appointmentNumber = apptNumber;
wrongReq.patientLookupEmail = 'nobody@example.test';
List<OncoAppointmentManager.ManageResult> wrongOut = OncoAppointmentManager.manageAppointment(
    new List<OncoAppointmentManager.ManageRequest>{ wrongReq }
);
System.assertEquals(false, wrongOut[0].isSuccess, 'Unknown email must not succeed.');
System.debug('[Smoke] Negative check (wrong email): ' + wrongOut[0].message);

System.debug('[Smoke] ALL ASSERTIONS PASSED');

/**
 * Deterministic slot generation aligned with Onco seed OperatingHours (Mon–Sat 09:00–18:00 Asia/Kolkata).
 * Does not call Salesforce Scheduler REST — suitable for demos and Agentforce actions.
 */
public without sharing class OncoSchedulerGateway {
    public static final String TERRITORY_NAME_PREFIX = 'Onco Territory - ';
    /** Maximum search window per request (days). */
    public static final Integer MAX_RANGE_DAYS = 14;
    public static final Integer SLOT_STEP_MINUTES = 30;

    /**
     * Finds ServiceTerritory for a HealthcareFacility using the naming convention from seed data.
     */
    public static Id getTerritoryIdForFacility(Id healthcareFacilityId) {
        if (healthcareFacilityId == null) {
            return null;
        }
        HealthcareFacility fac = [
            SELECT Name
            FROM HealthcareFacility
            WHERE Id = :healthcareFacilityId
            LIMIT 1
        ];
        String tName = TERRITORY_NAME_PREFIX + fac.Name;
        List<ServiceTerritory> rows = [
            SELECT Id
            FROM ServiceTerritory
            WHERE Name = :tName AND IsActive = true
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0].Id;
    }

    /**
     * ServiceResource for a provider uses the same display name as HealthcareProvider.Name (seed convention).
     */
    public static Id getServiceResourceIdForProvider(Id healthcareProviderId) {
        if (healthcareProviderId == null) {
            return null;
        }
        HealthcareProvider hp = [SELECT Name FROM HealthcareProvider WHERE Id = :healthcareProviderId LIMIT 1];
        List<ServiceResource> rows = [
            SELECT Id
            FROM ServiceResource
            WHERE Name = :hp.Name AND IsActive = true
            LIMIT 1
        ];
        return rows.isEmpty() ? null : rows[0].Id;
    }

    public static Decimal getWorkTypeDurationMinutes(Id workTypeId) {
        if (workTypeId == null) {
            return 30;
        }
        WorkType wt = [SELECT EstimatedDuration FROM WorkType WHERE Id = :workTypeId LIMIT 1];
        return wt.EstimatedDuration != null && wt.EstimatedDuration > 0 ? wt.EstimatedDuration : 30;
    }

    /**
     * Builds candidate slots: Mon–Sat, each slot fully inside 09:00–18:00 in {@code timezoneId}.
     */
    public static List<Datetime> generateSlots(
        Datetime fromUtc,
        Datetime toUtc,
        Integer durationMinutes,
        String timezoneId
    ) {
        List<Datetime> slots = new List<Datetime>();
        if (fromUtc == null || toUtc == null || fromUtc >= toUtc || durationMinutes == null || durationMinutes <= 0) {
            return slots;
        }
        Datetime endCap = toUtc > fromUtc.addDays(MAX_RANGE_DAYS) ? fromUtc.addDays(MAX_RANGE_DAYS) : toUtc;
        String tz = String.isNotBlank(timezoneId) ? timezoneId : 'Asia/Kolkata';
        Datetime cursor = fromUtc;
        Long stepMs = SLOT_STEP_MINUTES * 60L * 1000L;
        while (cursor < endCap) {
            Datetime slotEnd = cursor.addMinutes(durationMinutes);
            if (slotEnd > endCap) {
                break;
            }
            String dayName = cursor.format('EEEE', tz);
            if (dayName == 'Sunday') {
                cursor = cursor.addMinutes(SLOT_STEP_MINUTES);
                continue;
            }
            Integer startMin = localMinutesFromMidnight(cursor, tz);
            Integer endMin = localMinutesFromMidnight(slotEnd, tz);
            // Same calendar day in local TZ — if slot spans midnight, reject
            String d0 = cursor.format('yyyy-MM-dd', tz);
            String d1 = slotEnd.format('yyyy-MM-dd', tz);
            if (d0 != d1) {
                cursor = cursor.addMinutes(SLOT_STEP_MINUTES);
                continue;
            }
            Integer openMin = 9 * 60;
            Integer closeMin = 18 * 60;
            if (startMin >= openMin && endMin <= closeMin) {
                slots.add(cursor);
            }
            cursor = cursor.addMinutes(SLOT_STEP_MINUTES);
        }
        return slots;
    }

    private static Integer localMinutesFromMidnight(Datetime dt, String tz) {
        Integer hh = Integer.valueOf(dt.format('H', tz));
        Integer mm = Integer.valueOf(dt.format('m', tz));
        return hh * 60 + mm;
    }
}
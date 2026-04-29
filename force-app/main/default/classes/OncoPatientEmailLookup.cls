/**
 * Resolves Person Account (and optional Person Contact) from email for Agent / Experience callers
 * without requiring Salesforce record Ids from end users.
 */
public without sharing class OncoPatientEmailLookup {
    public class PersonMatch {
        public Id accountId;
        public Id personContactId;
    }

    /**
     * Returns Person Account Id when exactly one Person Account matches PersonEmail, else null.
     */
    public static Id findPersonAccountIdByEmail(String raw) {
        PersonMatch m = findPersonByEmail(raw);
        return m != null ? m.accountId : null;
    }

    /**
     * Returns Account Id and PersonContactId when exactly one Person Account matches PersonEmail.
     */
    public static PersonMatch findPersonByEmail(String raw) {
        String em = normalizePatientLookupEmail(raw);
        if (String.isBlank(em)) {
            return null;
        }
        return new EmailResolver().lookup(em);
    }

    private without sharing class EmailResolver {
        PersonMatch lookup(String em) {
            List<Account> rows = [
                SELECT Id, PersonContactId
                FROM Account
                WHERE IsPersonAccount = TRUE AND PersonEmail = :em
                LIMIT 1
            ];
            if (rows.isEmpty()) {
                return null;
            }
            PersonMatch m = new PersonMatch();
            m.accountId = rows[0].Id;
            m.personContactId = rows[0].PersonContactId;
            return m;
        }
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
                // Non-JSON; fall through to regex on full string
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

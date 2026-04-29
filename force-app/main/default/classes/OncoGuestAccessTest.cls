/**
 * Guest-user smoke tests for the Onco Global Patient Navigator agent flows.
 *
 * These run as the Embedded Service for Web (Agent Web Deployment) guest user
 * that hosts the live Agentforce conversation. They guard against regressions
 * where a facade is left {@code with sharing} or the guest permission set
 * loses an object grant — both of which silently return empty results to the
 * planner and surface as "no available slots" / "no providers" in chat.
 */
@IsTest(SeeAllData=true)
private class OncoGuestAccessTest {
    private static final Id AGENT_WEB_GUEST_USER_ID = '005ak00000XligvAAB';

    private static User guestUser() {
        return [SELECT Id, Name FROM User WHERE Id = :AGENT_WEB_GUEST_USER_ID LIMIT 1];
    }

    @IsTest
    static void guest_canFetchSlotsForKnownProvider() {
        System.runAs(guestUser()) {
            OncoSchedulingSlotsAgent.AgentRequest req = new OncoSchedulingSlotsAgent.AgentRequest();
            req.healthcareFacilityId = '0klak0000000EBCAA2';
            req.healthcareProviderId = '0cmak000003EatDAAS';
            List<OncoSchedulingSlotsAgent.AgentResult> out =
                OncoSchedulingSlotsAgent.getSlotsForAgent(
                    new List<OncoSchedulingSlotsAgent.AgentRequest>{ req }
                );
            System.assertEquals(true, out[0].success, 'success expected: ' + out[0].message);
            System.assert(
                out[0].slotsText != null && out[0].slotsText.length() > 100,
                'expected non-empty slot list, got: ' + out[0].slotsText
            );
            System.assert(
                out[0].slotsText.contains('Dr. Ishita Banerjee'),
                'expected provider name in slot list: ' + out[0].slotsText
            );
        }
    }

    @IsTest
    static void guest_canListFacilities() {
        System.runAs(guestUser()) {
            OncoDiscoveryFacilitiesAgent.AgentRequest req = new OncoDiscoveryFacilitiesAgent.AgentRequest();
            List<OncoDiscoveryFacilitiesAgent.AgentResult> out =
                OncoDiscoveryFacilitiesAgent.findFacilitiesForAgent(
                    new List<OncoDiscoveryFacilitiesAgent.AgentRequest>{ req }
                );
            System.assertEquals(true, out[0].success, 'success expected: ' + out[0].message);
            System.assert(
                out[0].facilitiesText != null && out[0].facilitiesText.length() > 50,
                'expected non-empty facility list, got: ' + out[0].facilitiesText
            );
        }
    }

    @IsTest
    static void guest_canFindProviders() {
        System.runAs(guestUser()) {
            OncoDiscoveryProvidersAgent.AgentRequest req = new OncoDiscoveryProvidersAgent.AgentRequest();
            List<OncoDiscoveryProvidersAgent.AgentResult> out =
                OncoDiscoveryProvidersAgent.findProvidersForAgent(
                    new List<OncoDiscoveryProvidersAgent.AgentRequest>{ req }
                );
            System.assertEquals(true, out[0].success, 'success expected: ' + out[0].message);
            System.assert(
                out[0].providersText != null && out[0].providersText.length() > 50,
                'expected non-empty provider list, got: ' + out[0].providersText
            );
        }
    }

    @IsTest
    static void guest_canSearchSpecialties() {
        System.runAs(guestUser()) {
            OncoDiscoverySpecialtiesAgent.AgentRequest req = new OncoDiscoverySpecialtiesAgent.AgentRequest();
            List<OncoDiscoverySpecialtiesAgent.AgentResult> out =
                OncoDiscoverySpecialtiesAgent.searchSpecialtiesForAgent(
                    new List<OncoDiscoverySpecialtiesAgent.AgentRequest>{ req }
                );
            System.assertEquals(true, out[0].success, 'success expected: ' + out[0].message);
            System.assert(
                out[0].message != null && out[0].message.length() > 0,
                'expected message text, got: ' + out[0].message
            );
        }
    }
}

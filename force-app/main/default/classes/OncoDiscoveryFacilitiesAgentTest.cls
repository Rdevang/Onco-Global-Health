@IsTest
private class OncoDiscoveryFacilitiesAgentTest {
    @IsTest
    static void findFacilitiesForAgent_returnsStructuredResult() {
        OncoDiscoveryFacilitiesAgent.AgentRequest req = new OncoDiscoveryFacilitiesAgent.AgentRequest();
        req.city = 'NonexistentCityXYZ123';
        List<OncoDiscoveryFacilitiesAgent.AgentResult> rows = OncoDiscoveryFacilitiesAgent.findFacilitiesForAgent(
            new List<OncoDiscoveryFacilitiesAgent.AgentRequest>{ req }
        );
        System.assertEquals(1, rows.size());
        System.assertEquals(true, rows[0].success);
    }
}

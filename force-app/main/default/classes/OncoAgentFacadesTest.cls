@IsTest
private class OncoAgentFacadesTest {
    @IsTest
    static void specialtiesAgent_listsOrEmpty() {
        OncoDiscoverySpecialtiesAgent.AgentRequest req = new OncoDiscoverySpecialtiesAgent.AgentRequest();
        req.searchText = 'zzznonexistent';
        List<OncoDiscoverySpecialtiesAgent.AgentResult> rows = OncoDiscoverySpecialtiesAgent.searchSpecialtiesForAgent(
            new List<OncoDiscoverySpecialtiesAgent.AgentRequest>{ req }
        );
        System.assertEquals(1, rows.size());
        System.assertEquals(true, rows[0].success);
    }

    @IsTest
    static void providersAgent_runs() {
        OncoDiscoveryProvidersAgent.AgentRequest req = new OncoDiscoveryProvidersAgent.AgentRequest();
        req.city = 'zzznonexistentcity';
        List<OncoDiscoveryProvidersAgent.AgentResult> rows = OncoDiscoveryProvidersAgent.findProvidersForAgent(
            new List<OncoDiscoveryProvidersAgent.AgentRequest>{ req }
        );
        System.assertEquals(1, rows.size());
    }

    @IsTest
    static void knowledgeAgent_blankQuery() {
        OncoKnowledgeSearchAgent.AgentRequest req = new OncoKnowledgeSearchAgent.AgentRequest();
        req.queryText = '';
        List<OncoKnowledgeSearchAgent.AgentResult> rows = OncoKnowledgeSearchAgent.searchKnowledgeForAgent(
            new List<OncoKnowledgeSearchAgent.AgentRequest>{ req }
        );
        System.assertEquals(1, rows.size());
    }

    @IsTest
    static void slotsAgent_missingIds() {
        OncoSchedulingSlotsAgent.AgentRequest req = new OncoSchedulingSlotsAgent.AgentRequest();
        List<OncoSchedulingSlotsAgent.AgentResult> rows = OncoSchedulingSlotsAgent.getSlotsForAgent(
            new List<OncoSchedulingSlotsAgent.AgentRequest>{ req }
        );
        System.assertEquals(1, rows.size());
        System.assertEquals(false, rows[0].success);
    }
}

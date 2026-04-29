/**
 * Text output for Agentforce planner; wraps OncoKnowledgeService.searchKnowledge (SOSL fallback).
 */
public without sharing class OncoKnowledgeSearchAgent {
    public class AgentRequest {
        @InvocableVariable(required = true label = 'Search Text' description = 'Keywords for Knowledge article search.')
        public String queryText;
        @InvocableVariable(label = 'Max Results' description = '1-20, default 10.')
        public Integer maxResults;
    }

    public class AgentResult {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String articlesText;
        @InvocableVariable public String message;
    }

    @InvocableMethod(
        label = 'Search Knowledge Articles'
        description = 'Keyword search over published Knowledge__kav articles.'
        category = 'Onco'
    )
    public static List<AgentResult> searchKnowledgeForAgent(List<AgentRequest> requests) {
        AgentResult r = new AgentResult();
        r.success = false;
        r.articlesText = '';
        r.message = '';
        if (requests == null || requests.isEmpty()) {
            r.message = 'No request';
            return new List<AgentResult>{ r };
        }
        try {
            OncoKnowledgeService.SearchRequest req = new OncoKnowledgeService.SearchRequest();
            req.queryText = requests[0].queryText;
            req.maxResults = requests[0].maxResults;
            List<List<OncoKnowledgeService.ArticleHit>> wrapped = OncoKnowledgeService.searchKnowledge(
                new List<OncoKnowledgeService.SearchRequest>{ req }
            );
            List<OncoKnowledgeService.ArticleHit> rows = wrapped != null && !wrapped.isEmpty()
                ? wrapped[0]
                : new List<OncoKnowledgeService.ArticleHit>();
            List<String> lines = new List<String>();
            for (OncoKnowledgeService.ArticleHit row : rows) {
                if (row == null) {
                    continue;
                }
                lines.add(
                    '- ' +
                        (String.isNotBlank(row.title) ? row.title : 'Article') +
                        ' | Snippet: ' +
                        (String.isNotBlank(row.summarySnippet) ? row.summarySnippet : '')
                );
            }
            r.articlesText = String.join(lines, '\n');
            r.success = true;
            r.message = rows.isEmpty() ? 'No articles matched.' : 'Found ' + rows.size() + ' article(s).';
            return new List<AgentResult>{ r };
        } catch (Exception e) {
            r.message = e.getMessage();
            return new List<AgentResult>{ r };
        }
    }
}

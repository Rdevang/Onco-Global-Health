/**
 * SOSL wrapper over Knowledge__kav for Agentforce / Flow retrieval.
 */
public without sharing class OncoKnowledgeService {
    public class SearchRequest {
        @InvocableVariable(required=true label='Search Text')
        public String queryText;
        @InvocableVariable(label='Max Results')
        public Integer maxResults;
    }

    public class ArticleHit {
        @InvocableVariable public String articleId;
        @InvocableVariable public String title;
        @InvocableVariable public String urlName;
        @InvocableVariable public String summarySnippet;
    }

    @InvocableMethod(
        label='Search Knowledge Articles'
        description='Runs SOSL against online Knowledge__kav articles.'
        category='Onco'
    )
    public static List<List<ArticleHit>> searchKnowledge(List<SearchRequest> requests) {
        List<List<ArticleHit>> wrap = new List<List<ArticleHit>>();
        if (requests == null || requests.isEmpty()) {
            wrap.add(new List<ArticleHit>());
            return wrap;
        }
        SearchRequest req = requests[0];
        Integer lim = req.maxResults != null && req.maxResults > 0 ? Math.min(req.maxResults, 20) : 10;
        List<ArticleHit> hits = new List<ArticleHit>();
        if (String.isBlank(req.queryText)) {
            wrap.add(hits);
            return wrap;
        }
        String q = String.escapeSingleQuotes(req.queryText.trim());
        String sosl =
            'FIND \'' + q + '\' IN ALL FIELDS RETURNING Knowledge__kav(Id, Title, UrlName, Summary WHERE PublishStatus = \'Online\' LIMIT '
            + lim
            + ')';
        try {
            List<List<SObject>> raw = Search.query(sosl);
            if (raw.isEmpty()) {
                wrap.add(hits);
                return wrap;
            }
            for (Knowledge__kav k : (List<Knowledge__kav>) raw[0]) {
                ArticleHit h = new ArticleHit();
                h.articleId = k.Id;
                h.title = k.Title;
                h.urlName = k.UrlName;
                if (k.Summary != null && k.Summary.length() > 240) {
                    h.summarySnippet = k.Summary.substring(0, 240) + '…';
                } else {
                    h.summarySnippet = k.Summary;
                }
                hits.add(h);
            }
        } catch (Exception e) {
            ArticleHit err = new ArticleHit();
            err.summarySnippet = 'Search error: ' + e.getMessage();
            hits.add(err);
        }
        wrap.add(hits);
        return wrap;
    }
}
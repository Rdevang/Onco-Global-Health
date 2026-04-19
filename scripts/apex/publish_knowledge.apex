/**
 * Phase 03 - Seed and publish Onco Global Knowledge articles (Knowledge__kav).
 *
 * Prerequisites: Data category group Onco_Care deployed (see force-app/.../dataCategoryGroups/).
 *
 * Run: sf apex run --file scripts/apex/publish_knowledge.apex --target-org Healthcloud
 *
 * Idempotent: skips UrlNames that already have an Online version.
 */

final String GROUP_NAME = 'Onco_Care';

final List<String> TITLES = new List<String>{
    'What is Medical Oncology and when do I need it?',
    'Surgical Oncology services at Onco Global',
    'Radiation Therapy options and side effects',
    'Pediatric cancer care and child-friendly facilities',
    'Women\'s cancers - screening and treatment',
    'Counseling and emotional support services',
    'Financial assistance and government schemes',
    'What to expect on your first visit',
    'Insurance partners and TPA process',
    'Parking, public transport and accessibility'
};

final List<String> URL_NAMES = new List<String>{
    'ka-001-medical-oncology-when-do-i-need-it',
    'ka-002-surgical-oncology-services-onco-global',
    'ka-003-radiation-therapy-options-side-effects',
    'ka-004-pediatric-cancer-care-bengaluru-centers',
    'ka-005-womens-cancers-screening-treatment',
    'ka-006-counseling-emotional-support-services',
    'ka-007-financial-assistance-government-schemes',
    'ka-008-first-visit-what-to-expect',
    'ka-009-insurance-partners-tpa-process',
    'ka-010-parking-public-transport-accessibility'
};

// Leaf data category developer names (must match Onco_Care.datacategorygroup-meta.xml)
final List<String> CATEGORY_LEAVES = new List<String>{
    'Medical_Oncology',
    'Surgical_Oncology',
    'Radiation_Oncology',
    'Pediatric_Oncology',
    'Gynecologic_Oncology',
    'Counseling',
    'Financial_Assistance',
    'Diagnosis',
    'Insurance_Accepted',
    'Parking_Access'
};

final List<String> SUMMARIES = new List<String>{
    'Medical oncology focuses on treating cancer using medication, including chemotherapy, targeted therapy, immunotherapy, and hormone therapy. A medical oncologist works with your care team to plan treatment, monitor response, and help manage side effects.\n\nThis article explains what medical oncology is and how it fits into your care plan. It does not replace advice from your treating physician.\n\nWhen to contact us\nIf you want to book a consult or find a medical oncologist near you, use the Onco Global patient portal or WhatsApp self-service. Our team can help match you to the right doctor and location.',
    'Surgical oncology involves operations to diagnose, stage, or treat cancer. Your surgeon works closely with medical and radiation oncology to plan the safest approach for you.\n\nAt Onco Global, surgical oncology services are available at multiple hospitals. Wait times and pre-operative steps vary by procedure and location.\n\nWhen to contact us\nTo learn which surgical oncology services are offered at your preferred hospital, message us through the patient portal chat or request a callback from scheduling.',
    'Radiation therapy uses carefully controlled radiation to treat cancer. Your radiation oncologist explains options, expected side effects, and what to expect across visits.\n\nSide effects depend on the area treated and your overall health. Always follow your care team\'s instructions for skin care, nutrition, and follow-up.\n\nWhen to contact us\nIf you need to schedule or reschedule radiation visits, use self-service booking or ask the digital assistant for available slots.',
    'Pediatric oncology care is designed for children and teens, with family-centered support and child-friendly facilities at select Onco Global centers, including Bengaluru.\n\nOur teams coordinate with caregivers on school, nutrition, and emotional support resources. This overview is general information only.\n\nWhen to contact us\nFor pediatric oncology appointments in Bengaluru or other cities, use the portal or chat to find pediatric specialists and book a visit.',
    'Gynecologic oncology focuses on cancers of the female reproductive system. Screening, diagnosis, and treatment plans are individualized based on exam findings and tests.\n\nOnco Global offers multidisciplinary care with privacy and dignity as priorities.\n\nWhen to contact us\nIf you have questions about screening programs or need a specialist visit, contact us through the patient portal or WhatsApp channel.',
    'Counseling and emotional support can help patients and families cope with stress during diagnosis and treatment. Options may include one-on-one counseling, support groups, and referrals.\n\nServices vary by location. Ask your care team what is available at your center.\n\nWhen to contact us\nTo request counseling resources or speak with a care navigator, use the portal chat or send a message through your preferred digital channel.',
    'Financial assistance programs and government schemes may help eligible patients with treatment costs. Eligibility rules change over time and depend on documentation and program availability.\n\nOur financial counseling team can guide you on paperwork and next steps.\n\nWhen to contact us\nAsk the digital assistant for "financial assistance" or request a financial counseling callback through the patient portal.',
    'Your first visit usually includes registration, vitals, history, and a discussion of tests or treatment options. Bring your ID, insurance card, prior reports, and a list of medications.\n\nArrive early to complete forms if needed. If you need language assistance, request an interpreter before the visit.\n\nWhen to contact us\nTo reschedule your first visit or ask what to bring for your specific doctor, use self-service scheduling or chat with the Onco assistant.',
    'Onco Global partners with major insurers and TPAs. Coverage depends on your policy, pre-authorization rules, and treatment setting.\n\nBring your insurance card and TPA details to registration. Pre-auth timelines vary by insurer.\n\nWhen to contact us\nFor general questions about insurance partners, start with the portal knowledge search. For claim or pre-auth issues, contact the billing desk at your hospital location.',
    'Parking, public transport, and accessibility differ by Onco Global hospital. Many locations offer wheelchair access, drop-off zones, and nearby transit links.\n\nCheck your appointment confirmation for the facility address and suggested entry gate.\n\nWhen to contact us\nIf you need wheelchair assistance or directions, message the hospital front desk number on your confirmation or ask the digital assistant for the facility phone directory.'
};

Integer n = TITLES.size();
if (n != URL_NAMES.size() || n != CATEGORY_LEAVES.size() || n != SUMMARIES.size()) {
    System.assert(false, 'Article arrays out of sync');
}

Integer created = 0;
Integer skipped = 0;

for (Integer i = 0; i < n; i++) {
    String url = URL_NAMES[i];
    List<Knowledge__kav> online = [
        SELECT Id FROM Knowledge__kav WHERE UrlName = :url AND PublishStatus = 'Online' LIMIT 1
    ];
    if (!online.isEmpty()) {
        skipped++;
        continue;
    }

    Knowledge__kav draft = new Knowledge__kav(
        Title = TITLES[i],
        UrlName = url,
        Summary = SUMMARIES[i],
        Language = 'en_US',
        ValidationStatus = 'Validated',
        IsVisibleInPkb = true,
        IsVisibleInPrm = true,
        IsVisibleInCsp = true
    );
    insert draft;

    insert new Knowledge__DataCategorySelection(
        ParentId = draft.Id,
        DataCategoryGroupName = GROUP_NAME,
        DataCategoryName = CATEGORY_LEAVES[i]
    );

    Id kaId = [SELECT KnowledgeArticleId FROM Knowledge__kav WHERE Id = :draft.Id].KnowledgeArticleId;
    KbManagement.PublishingService.publishArticle(kaId, true);
    created++;
}

System.debug('[Knowledge] Created/published: ' + created + ', skipped (already online): ' + skipped);
System.debug('[Knowledge] Online article count (KA URLs): ' + [
    SELECT COUNT() FROM Knowledge__kav
    WHERE PublishStatus = 'Online' AND UrlName LIKE 'ka-%'
]);

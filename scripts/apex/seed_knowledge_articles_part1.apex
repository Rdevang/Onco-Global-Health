/**
 * Seeds the Knowledge base for the Onco Global patient-scheduling agent - PART 1.
 *
 * Deletes 2 test articles ("Cat Test", "TEST Onco Seed Smoke"), then inserts
 * and publishes articles ka-011..ka-030 (treatment modalities, cancer types,
 * and the first two facility guides). Part 2 handles the remaining 20.
 *
 * Idempotent on UrlName: re-running will skip any article whose UrlName
 * already exists in the org.
 *
 * Usage:
 *   sf apex run --file scripts/apex/seed_knowledge_articles_part1.apex -o <alias>
 */

// ---------- 0. Delete obvious test articles via PublishingService ----------
Set<String> TEST_TITLES = new Set<String>{ 'Cat Test', 'TEST Onco Seed Smoke' };
List<Knowledge__kav> junk = [
    SELECT Id, KnowledgeArticleId, Title, PublishStatus
    FROM Knowledge__kav
    WHERE Title IN :TEST_TITLES
];
Integer deleted = 0;
for (Knowledge__kav k : junk) {
    try {
        if (k.PublishStatus == 'Online') {
            KbManagement.PublishingService.archiveOnlineArticle(k.KnowledgeArticleId, null);
            KbManagement.PublishingService.deleteArchivedArticle(k.KnowledgeArticleId);
        } else if (k.PublishStatus == 'Draft') {
            KbManagement.PublishingService.deleteDraftArticle(k.KnowledgeArticleId);
        } else if (k.PublishStatus == 'Archived') {
            KbManagement.PublishingService.deleteArchivedArticle(k.KnowledgeArticleId);
        }
        deleted++;
    } catch (Exception e) {
        System.debug('[KB] Could not delete ' + k.Title + ': ' + e.getMessage());
    }
}
System.debug('[KB] Test articles removed: ' + deleted);

// ---------- 1. Draft articles 11..30 ----------
List<Knowledge__kav> candidates = new List<Knowledge__kav>();

candidates.add(new Knowledge__kav(
    UrlName = 'ka-011-understanding-chemotherapy',
    Title = 'Understanding Chemotherapy - What to Expect',
    Summary = 'Chemotherapy uses medicines to destroy cancer cells that divide rapidly. At Onco Global we deliver chemo as IV infusion, oral tablets or injections, in day-care chairs or inpatient wards depending on the regimen. Each cycle is planned by your medical oncologist around your diagnosis, stage and organ function tests. Common side effects include fatigue, nausea, hair thinning and low blood counts; our day-care nurses provide anti-emetic premedication and counsel you on red-flag symptoms. Blood tests are usually done the day before each cycle. Expect to spend 2 to 6 hours in the chair per visit. Bring a light meal, medication list and a companion. To start or review a chemo plan, book a Medical Oncology consult via the patient portal, WhatsApp or the contact centre.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-012-immunotherapy-explained',
    Title = 'Immunotherapy Explained - How It Works',
    Summary = 'Immunotherapy helps your immune system recognise and kill cancer cells. Checkpoint inhibitors (such as pembrolizumab and nivolumab) are the most common class used at Onco Global, delivered as IV infusions every 2 to 6 weeks. Eligibility depends on the cancer type, PD-L1 or MSI testing, and overall health. Unlike chemo, immunotherapy side effects are immune-mediated: thyroid changes, skin rash, colitis or pneumonitis. These are usually manageable if reported early, so we give every patient a 24x7 helpline card. Most patients continue normal daily activities during treatment. Ask your oncologist whether your tumour profile is suitable; if yes, the drug is scheduled in our day-care centre with monitoring by an onco-immunotherapy-trained nurse.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-013-targeted-therapy-precision-medicine',
    Title = 'Targeted Therapy - Precision Cancer Medicine',
    Summary = 'Targeted therapy uses drugs that block specific molecules driving cancer growth, for example EGFR inhibitors in lung cancer, HER2 blockers in breast cancer, or BCR-ABL inhibitors in CML. Onco Global routinely sends tumour samples for IHC, FISH and next-generation sequencing so that eligible patients can receive oral or IV targeted drugs. Side effects are usually milder than chemotherapy but may include rash, diarrhoea, hand-foot syndrome or liver enzyme changes. Most targeted drugs are taken at home with periodic clinic reviews. Our pharmacy team coordinates insurance pre-authorisation and patient-assistance programs for high-cost molecules. Speak to your medical oncologist about biomarker testing before treatment starts.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-014-hormone-therapy-hormone-sensitive-cancers',
    Title = 'Hormone Therapy for Hormone-Sensitive Cancers',
    Summary = 'Hormone (endocrine) therapy blocks the hormones that fuel certain cancers, most commonly hormone-receptor-positive breast cancer and prostate cancer. Treatments include tamoxifen, aromatase inhibitors, LHRH agonists (goserelin, leuprolide) and anti-androgens. These are given as daily tablets, monthly or three-monthly depot injections at our day-care unit, or occasionally as surgical procedures. Therapy can last 5 to 10 years for adjuvant breast cancer and is usually well tolerated. Common side effects include hot flushes, joint stiffness, bone density loss and mood changes; we recommend baseline DEXA scans and periodic reviews. Skipping doses reduces effectiveness, so sign up for WhatsApp reminders from the patient portal.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-015-bone-marrow-stem-cell-transplant',
    Title = 'Bone Marrow and Stem Cell Transplant Program',
    Summary = 'Onco Global runs a JCI-benchmarked adult and paediatric transplant unit performing autologous and allogeneic bone marrow or peripheral-blood stem cell transplants for leukaemia, lymphoma, myeloma and select solid tumours. The workup includes HLA typing, cardiac and pulmonary tests, infection screening and donor identification where needed. Conditioning chemotherapy is followed by cell infusion and 3 to 6 weeks of protected inpatient care. A dedicated transplant coordinator walks the family through insurance, government schemes and accommodation. After discharge, patients attend structured follow-up in the transplant clinic for at least 2 years. Ask the haematology team to refer you for a transplant evaluation if your oncologist suggests it.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-016-palliative-care-symptom-management',
    Title = 'Palliative Care and Symptom Management',
    Summary = 'Palliative care focuses on relieving pain, breathlessness, nausea, fatigue and emotional distress at any stage of cancer, not only end-of-life. Our multidisciplinary team includes palliative physicians, specialist nurses, physiotherapists, psychologists and spiritual-care volunteers. Services are delivered in outpatient clinics, during inpatient stays and through home-care visits across all Onco Global cities. We can also arrange hospice referrals when appropriate. You do not need to stop cancer-directed treatment to see palliative care - most patients benefit from parallel support. Ask your oncologist for a referral, or book a Palliative Care consult directly via the patient portal or WhatsApp.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-017-clinical-trials-at-onco-global',
    Title = 'Clinical Trials at Onco Global',
    Summary = 'Onco Global participates in more than 80 active clinical trials spanning early-phase immunotherapy, novel targeted drugs, CAR-T therapy and improved supportive care. Trials offer access to next-generation medicines today, at no drug cost. Every trial follows DCGI, ICMR and Institutional Ethics Committee approvals. A clinical research coordinator will explain eligibility, benefits, risks and the informed-consent process in your preferred language. Participation is entirely voluntary and you may withdraw at any time without affecting your standard care. To check if a trial matches your diagnosis, ask your oncologist or request a Clinical Trial Screening via the portal. Our study list is reviewed monthly and cross-site enrollment is coordinated centrally.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-018-second-opinion-services',
    Title = 'Second Opinion Services',
    Summary = 'A second opinion can confirm your diagnosis, explore alternative treatments and give you peace of mind. The Second Opinion Clinic at Onco Global accepts patients whether their primary care is with us or with another hospital. Upload scans, pathology slides, biopsy blocks and prior reports through the secure portal; we also accept email and WhatsApp. A senior multi-disciplinary tumour board of medical, surgical and radiation oncologists reviews each case and issues a written opinion within 3 working days for most cancers. Video consultations are available for out-of-town patients. Costs are transparent and insurance-eligible. Ask the contact centre for a Second Opinion appointment, no referral letter is required.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-019-breast-cancer-care-pathway',
    Title = 'Breast Cancer Care Pathway',
    Summary = 'Our breast cancer programme treats early-stage, locally advanced and metastatic disease with a tumour-board-driven plan. Standard pathway: triple assessment (clinical exam, mammogram / ultrasound, core biopsy) leading to breast-conserving surgery or mastectomy with sentinel-node biopsy or axillary clearance, followed as needed by chemotherapy, radiation, targeted therapy (trastuzumab, CDK4/6 inhibitors) and endocrine therapy. Oncoplastic and reconstructive surgery is available in the same setting. We also run a dedicated hereditary-cancer clinic for BRCA / PALB2 testing and risk-reducing advice. Survivorship care includes lymphoedema physiotherapy, menopause management and annual follow-up. Start by booking a Surgical or Medical Oncology consult with your biopsy report ready.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-020-lung-cancer-diagnosis-treatment',
    Title = 'Lung Cancer Diagnosis and Treatment',
    Summary = 'Lung cancer care at Onco Global includes low-dose CT screening for heavy smokers, EBUS-guided biopsy, molecular profiling (EGFR, ALK, ROS1, KRAS, PD-L1) and multi-disciplinary treatment planning. Early-stage patients are offered minimally invasive VATS or robotic lobectomy. Locally advanced disease receives concurrent chemoradiation with consolidation immunotherapy. Metastatic patients receive biomarker-driven targeted therapy or immunotherapy with or without chemo. Smoking-cessation counselling and pulmonary rehabilitation are integrated into every plan. Red-flag symptoms that warrant urgent review include cough >3 weeks, coughing up blood, weight loss and persistent chest pain. Book a Medical Oncology consult to start the workup.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-021-colorectal-cancer-screening-care',
    Title = 'Colorectal Cancer Screening and Care',
    Summary = 'Colorectal cancer is highly curable when detected early. Onco Global offers screening colonoscopy from age 45, or earlier for those with family history, inflammatory bowel disease or Lynch syndrome. When a tumour is found, staging with CT and MRI guides either laparoscopic / robotic surgery, neoadjuvant chemoradiation (for rectal cancers) or systemic therapy for metastatic disease. Stoma care nurses support ostomy patients and most stomas can be reversed later. Chemotherapy regimens (FOLFOX, FOLFIRI, capecitabine) are delivered in our day-care unit with portable infusion pumps available. Genetic testing is offered when indicated. Speak to the surgical or medical oncology team, or request a screening colonoscopy via the portal.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-022-blood-cancers-leukemia-lymphoma-myeloma',
    Title = 'Blood Cancers - Leukemia, Lymphoma, Myeloma',
    Summary = 'Our haemato-oncology team treats acute and chronic leukaemias, Hodgkin and non-Hodgkin lymphomas, multiple myeloma and myelodysplastic syndromes. Workup includes bone marrow biopsy with flow cytometry, cytogenetics and molecular panels (FLT3, NPM1, JAK2, IgH, t(14;18)) delivered by our in-house lab. Treatment ranges from oral targeted drugs (imatinib, ibrutinib, venetoclax) to multi-agent chemo, monoclonal antibodies (rituximab, daratumumab), CAR-T therapy and autologous or allogeneic stem-cell transplant. A dedicated haematology day-care with HEPA-filtered rooms supports high-risk treatments. Paediatric cases are managed jointly with the paediatric oncology team. Ask for a Haemato-Oncology consult to begin.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-023-head-neck-cancer-services',
    Title = 'Head and Neck Cancer Services',
    Summary = 'Head and neck cancers affect the mouth, throat, voice box, salivary glands and thyroid. Onco Global offers a one-stop Head and Neck Clinic with ENT surgeons, oral and maxillofacial surgeons, medical and radiation oncologists, speech therapists, dietitians and dental specialists. Standard pathway includes panendoscopy with biopsy, imaging, dental assessment before radiation, multidisciplinary tumour-board planning, reconstructive surgery (free flap), IMRT / IGRT radiation and systemic therapy. Tobacco and alcohol cessation support is integrated. Speech, swallowing and nutrition rehabilitation continues for months after treatment. Symptoms that need urgent evaluation include a mouth ulcer >3 weeks, a neck lump or hoarseness. Book a Surgical Oncology or ENT consult to start.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-024-prostate-cancer-treatment-options',
    Title = 'Prostate Cancer Treatment Options',
    Summary = 'Prostate cancer often grows slowly, and treatment is chosen based on stage, grade (Gleason / ISUP), PSA kinetics, life expectancy and patient preference. Active surveillance is offered for low-risk disease. Curative options include robot-assisted radical prostatectomy and advanced external-beam radiotherapy with or without brachytherapy boost. Locally advanced or metastatic disease is treated with androgen deprivation therapy, next-generation anti-androgens (abiraterone, enzalutamide) and newer therapies including PSMA-targeted treatment for selected patients. Side effects on urinary, bowel and sexual function are actively managed with pelvic-floor physiotherapy and sexual health counselling. Book a Urology or Medical Oncology consult with your PSA and MRI reports.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-025-skin-cancer-melanoma-care',
    Title = 'Skin Cancer and Melanoma Care',
    Summary = 'Skin cancers include basal-cell and squamous-cell carcinomas (very common, usually curable by excision) and melanoma (needs specialist care). Onco Global offers dermoscopy-based lesion assessment, sentinel lymph-node biopsy, Mohs-style wide excision, immunotherapy (checkpoint inhibitors) and targeted BRAF/MEK therapy for metastatic melanoma. Patients with many moles, fair skin or family history are enrolled in an annual skin-surveillance clinic with photographic mapping. Any skin lesion that is new, changing, bleeding or different from surrounding moles should be seen urgently. Most suspicious lesions can be biopsied the same day. Book a Surgical Oncology or Dermatology consult through the portal.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-026-gi-liver-cancer-care',
    Title = 'Gastrointestinal and Liver Cancer Care',
    Summary = 'Our GI oncology programme covers stomach, pancreas, liver, gallbladder, bile duct and small-bowel cancers. Diagnostic tools include endoscopic ultrasound with FNA, MRCP, triple-phase CT, PET-CT and interventional radiology. Treatment combines minimally invasive or robotic surgery, neoadjuvant and adjuvant chemo, targeted drugs and advanced radiation including stereotactic body radiotherapy for liver lesions. Liver-directed therapies such as TACE, TARE and radiofrequency ablation are delivered by our interventional radiology team. Patients with pancreatic cancer have access to a dedicated high-volume surgical team. Nutrition support and pain management are integrated. Ask for a GI Surgical or Medical Oncology consult with all prior imaging.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-027-neuro-oncology-brain-spine-tumors',
    Title = 'Brain and Spine Tumors - Neuro-oncology',
    Summary = 'Neuro-oncology at Onco Global combines neurosurgery, radiation and medical oncology for gliomas, meningiomas, pituitary adenomas, paediatric brain tumours, spinal cord tumours and brain metastases. Our surgical team uses neuronavigation, intra-operative MRI where available, awake craniotomy and minimally invasive endoscopic techniques. Radiation options include IMRT, stereotactic radiosurgery (SRS, Gamma-Knife style) and proton beam referrals. Systemic therapy follows molecular profiling (IDH, MGMT, 1p/19q). A dedicated neuro-rehab team manages post-operative seizures, speech and mobility. Red-flag symptoms include persistent headache, new seizures, progressive weakness or vision changes. Book a Neurology or Neurosurgery consult and we will coordinate oncology review.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-028-thyroid-cancer-diagnosis-treatment',
    Title = 'Thyroid Cancer - Diagnosis and Treatment',
    Summary = 'Most thyroid cancers (papillary and follicular) are highly curable. Workup starts with ultrasound-guided FNA for suspicious nodules and thyroid function tests. Treatment usually includes hemi- or total thyroidectomy with or without central / lateral neck dissection, often followed by radioactive iodine therapy in a dedicated RAI ward. Medullary and anaplastic types need molecular testing (RET, BRAF) and may be treated with targeted drugs such as selpercatinib or dabrafenib-trametinib. Lifelong thyroxine replacement and periodic thyroglobulin monitoring are essential. Voice preservation and parathyroid-sparing surgery are our standards. Book a Surgical Oncology or Endocrinology consult with your ultrasound and FNA reports.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-029-facility-mumbai-powai',
    Title = 'Onco Global Mumbai Powai - Facility Guide',
    Summary = 'Onco Global - Mumbai Powai is our 180-bed flagship site in central Mumbai, with comprehensive medical, surgical and radiation oncology, a paediatric cancer unit and a bone-marrow transplant ward. Facilities include 4 linear accelerators (including an SBRT-capable machine), MRI, PET-CT, robotic surgery, 12 day-care chemo chairs, an oncology pharmacy and a 24x7 oncology emergency room. Parking is available on-site and the nearest metro station is Powai. Visiting hours for inpatients are 10:00-12:00 and 17:00-20:00. Dedicated international-patients desk on the ground floor. Book a consult here via the portal, WhatsApp or by calling the contact centre; ask for the Powai centre by name.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-030-facility-mumbai-andheri',
    Title = 'Onco Global Mumbai Andheri - Facility Guide',
    Summary = 'Onco Global - Mumbai Andheri is a daycare-focused satellite centre for western suburbs patients. The 60-bed centre offers medical oncology consults, day-care chemotherapy, IV infusions, minor surgical procedures and specialist clinics for breast, gynaec and GI oncology. Radiation and complex surgery cases are referred to our Powai campus via a same-team clinician handover. Diagnostics include on-site mammography, ultrasound, pathology collection and CT; MRI and PET-CT are available next door. Parking is paid and there is a drop-off bay for wheelchair patients. Contact centre hours 07:00-22:00. Most patients choose Andheri for follow-ups and Powai for inpatient / RT visits; we coordinate both.'
));

for (Knowledge__kav k : candidates) {
    k.Language = 'en_US';
}

// ---------- 2. Skip anything whose UrlName already exists ----------
Set<String> wantedUrlNames = new Set<String>();
for (Knowledge__kav k : candidates) {
    wantedUrlNames.add(k.UrlName);
}
Set<String> existingUrlNames = new Set<String>();
for (Knowledge__kav k : [SELECT UrlName FROM Knowledge__kav WHERE UrlName IN :wantedUrlNames]) {
    existingUrlNames.add(k.UrlName);
}

List<Knowledge__kav> drafts = new List<Knowledge__kav>();
for (Knowledge__kav k : candidates) {
    if (!existingUrlNames.contains(k.UrlName)) {
        drafts.add(k);
    }
}
System.debug('[KB-1] Candidates: ' + candidates.size() + ', new drafts: ' + drafts.size());

if (!drafts.isEmpty()) {
    insert drafts;
    System.debug('[KB-1] Inserted drafts: ' + drafts.size());

    Set<Id> draftIds = new Set<Id>();
    for (Knowledge__kav k : drafts) {
        draftIds.add(k.Id);
    }
    Integer published = 0;
    for (Knowledge__kav k : [SELECT Id, KnowledgeArticleId, Title FROM Knowledge__kav WHERE Id IN :draftIds]) {
        try {
            KbManagement.PublishingService.publishArticle(k.KnowledgeArticleId, true);
            published++;
        } catch (Exception e) {
            System.debug('[KB-1] Publish failed for ' + k.Title + ': ' + e.getMessage());
        }
    }
    System.debug('[KB-1] Published articles: ' + published);
}

System.debug('[KB-1] DONE');

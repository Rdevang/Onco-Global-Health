// Idempotent: tag every Online English Knowledge__kav with one Onco_Care data category.
// Safe to re-run; skips rows that are already tagged.
//
// Strategy: simple title-keyword heuristic -> category name.
// All categories live under DataCategoryGroupName 'Onco_Care'.

Map<String, String> keywordToCategory = new Map<String, String>{
    'chemotherapy'      => 'Medical_Oncology',
    'immunotherapy'     => 'Medical_Oncology',
    'targeted therapy'  => 'Medical_Oncology',
    'hormone therapy'   => 'Medical_Oncology',
    'medical oncology'  => 'Medical_Oncology',
    'lung cancer'       => 'Medical_Oncology',
    'prostate'          => 'Medical_Oncology',
    'thyroid'           => 'Medical_Oncology',
    'skin cancer'       => 'Medical_Oncology',
    'melanoma'          => 'Medical_Oncology',
    'gastrointestinal'  => 'Medical_Oncology',
    'liver cancer'      => 'Medical_Oncology',
    'brain'             => 'Medical_Oncology',
    'neuro-oncology'    => 'Medical_Oncology',
    'head and neck'     => 'Medical_Oncology',
    'breast'            => 'Medical_Oncology',
    'colorectal'        => 'Medical_Oncology',
    'radiation'         => 'Radiation_Oncology',
    'surgical'          => 'Surgical_Oncology',
    'pediatric'         => 'Pediatric_Oncology',
    'women'             => 'Gynecologic_Oncology',
    'gynec'             => 'Gynecologic_Oncology',
    'blood cancer'      => 'Hemato_Oncology',
    'leukemia'          => 'Hemato_Oncology',
    'lymphoma'          => 'Hemato_Oncology',
    'myeloma'           => 'Hemato_Oncology',
    'bone marrow'       => 'Hemato_Oncology',
    'stem cell'         => 'Hemato_Oncology',
    'palliative'        => 'Palliative_Care',
    'pain management'   => 'Palliative_Care',
    'counseling'        => 'Counseling',
    'emotional'         => 'Counseling',
    'nutrition'         => 'Nutrition',
    'dietary'           => 'Nutrition',
    'financial'         => 'Financial_Assistance',
    'insurance'         => 'Insurance_Accepted',
    'parking'           => 'Parking_Access',
    'transport'         => 'Parking_Access',
    'facility guide'    => 'Visiting_Hours',
    'appointment'       => 'Visiting_Hours',
    'book your'         => 'Visiting_Hours',
    'reschedul'         => 'Visiting_Hours',
    'cancellation policy' => 'Visiting_Hours',
    'whatsapp'          => 'Visiting_Hours',
    'first visit'       => 'Visiting_Hours',
    'telehealth'        => 'Treatment_Planning',
    'virtual'           => 'Treatment_Planning',
    'consultation'      => 'Treatment_Planning',
    'fertility'         => 'Treatment_Planning',
    'clinical trials'   => 'Treatment_Planning',
    'second opinion'    => 'Treatment_Planning',
    'follow-up'         => 'Treatment_Planning',
    'survivorship'      => 'Survivorship',
    'physical therapy'  => 'Survivorship',
    'rehabilitation'    => 'Survivorship',
    'hair loss'         => 'Survivorship'
};

List<Knowledge__kav> arts = [
    SELECT Id, Title FROM Knowledge__kav
    WHERE PublishStatus = 'Online' AND Language = 'en_US' AND IsLatestVersion = true
];

Set<Id> alreadyTagged = new Set<Id>();
for (Knowledge__DataCategorySelection s : [
    SELECT ParentId, DataCategoryGroupName FROM Knowledge__DataCategorySelection
    WHERE ParentId IN :arts
]) {
    if (s.DataCategoryGroupName == 'Onco_Care') alreadyTagged.add(s.ParentId);
}

List<Knowledge__DataCategorySelection> toInsert = new List<Knowledge__DataCategorySelection>();
Integer tagged = 0, skipped = 0, fallbackCount = 0;

for (Knowledge__kav a : arts) {
    if (alreadyTagged.contains(a.Id)) { skipped++; continue; }
    String t = a.Title == null ? '' : a.Title.toLowerCase();
    String cat = null;
    for (String kw : keywordToCategory.keySet()) {
        if (t.contains(kw)) { cat = keywordToCategory.get(kw); break; }
    }
    if (cat == null) { cat = 'Medical_Oncology'; fallbackCount++; }
    Knowledge__DataCategorySelection s = new Knowledge__DataCategorySelection(
        ParentId = a.Id,
        DataCategoryGroupName = 'Onco_Care',
        DataCategoryName = cat
    );
    toInsert.add(s);
    tagged++;
}

if (!toInsert.isEmpty()) {
    Database.SaveResult[] rs = Database.insert(toInsert, false);
    Integer ok = 0, fail = 0;
    for (Database.SaveResult r : rs) {
        if (r.isSuccess()) ok++; else {
            fail++;
            System.debug('FAIL: ' + r.getErrors());
        }
    }
    System.debug('CATEGORIZE: tagged=' + ok + ' failed=' + fail + ' skipped=' + skipped + ' fallback=' + fallbackCount);
} else {
    System.debug('CATEGORIZE: nothing to insert (all ' + skipped + ' already tagged).');
}

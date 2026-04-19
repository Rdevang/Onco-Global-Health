/**
 * Seeds the Knowledge base for the Onco Global patient-scheduling agent - PART 2.
 *
 * Inserts and publishes articles ka-031..ka-050 (remaining facility guides,
 * scheduling / digital engagement, and supportive care). Run Part 1 first.
 *
 * Idempotent on UrlName: re-running will skip any article whose UrlName
 * already exists in the org.
 *
 * Usage:
 *   sf apex run --file scripts/apex/seed_knowledge_articles_part2.apex -o <alias>
 */

List<Knowledge__kav> candidates = new List<Knowledge__kav>();

candidates.add(new Knowledge__kav(
    UrlName = 'ka-031-facility-delhi-dwarka',
    Title = 'Onco Global Delhi Dwarka - Facility Guide',
    Summary = 'Onco Global - Delhi Dwarka serves NCR patients with a 150-bed oncology hospital, 3 linear accelerators, PET-CT, MRI, robotic surgery and a dedicated haematology-BMT unit. Our Dwarka team runs specialty clinics six days a week across medical, surgical, radiation, gynae, paediatric and palliative oncology. The ISBT bus stand is 15 minutes away and Delhi Metro Blue Line (Dwarka Sector 21) is the nearest station. Ayushman Bharat, CGHS and major insurance panels are empanelled. Day-care chemotherapy slots are available between 08:00 and 20:00, bookable via portal or WhatsApp. International patient services and airport pickup can be arranged by the concierge desk.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-032-facility-bengaluru-whitefield',
    Title = 'Onco Global Bengaluru Whitefield - Facility Guide',
    Summary = 'Onco Global - Bengaluru Whitefield is a 120-bed comprehensive cancer centre in east Bengaluru serving Whitefield, Marathahalli, KR Puram and nearby areas. Services include medical, surgical and radiation oncology, robotic surgery, daycare chemo, MRI, PET-CT and a paediatric oncology ward. Purple-Line metro (Whitefield) is walking distance and valet parking is available. Weekday specialty clinics run 08:00-20:00 and weekend clinics till 14:00. We offer multi-language support including Kannada, Tamil, Telugu, Hindi and English. Commercial insurance and corporate-tie-up patients have a dedicated desk. Book a consult here by picking Whitefield in the portal or by asking our agent for "Whitefield centre".'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-033-facility-bengaluru-hsr',
    Title = 'Onco Global Bengaluru HSR - Facility Guide',
    Summary = 'Onco Global - Bengaluru HSR is an outpatient-focused centre for southeast Bengaluru. It offers specialty consults, day-care chemotherapy, pathology collection, ultrasound, mammography and a chemo-prep pharmacy. Complex surgery, radiation and transplant services are provided at our Whitefield campus with integrated scheduling. Parking is on-site and the BMTC terminal is 5 minutes away. Clinic hours 08:00-21:00 on weekdays and 09:00-18:00 on Saturdays; closed on major public holidays. We run special twice-a-month clinics in oncofertility and hereditary cancer genetics. Book a follow-up or survivorship visit here, or request a transfer from another centre through the portal.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-034-facility-chennai-anna-nagar',
    Title = 'Onco Global Chennai Anna Nagar - Facility Guide',
    Summary = 'Onco Global - Chennai Anna Nagar is our 140-bed cancer centre in north-central Chennai with medical, surgical and radiation oncology, haemato-oncology, BMT, paediatric oncology and palliative care. Imaging includes 3T MRI, PET-CT, digital mammography and ultrasound-guided biopsy. Two modern linear accelerators with IMRT / SBRT are in daily use. Metro access via the Anna Nagar East station. Weekday clinics 08:00-20:00; weekend clinics 08:00-14:00. Tamil, Telugu, Malayalam, Hindi and English are spoken at the help-desk. International patient services include visa letters and onward travel co-ordination. Book a consult from the portal and select "Chennai Anna Nagar" as the preferred location.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-035-facility-kolkata-salt-lake',
    Title = 'Onco Global Kolkata Salt Lake - Facility Guide',
    Summary = 'Onco Global - Kolkata Salt Lake is a 110-bed cancer centre in Salt Lake Sector V with a full suite of oncology services: medical, surgical, radiation, haematology and paediatric oncology. We offer digital PET-CT, MRI, 2 linear accelerators and a modern chemo day-care with 10 infusion chairs. Bengali, Hindi and English support at the help-desk. Paid parking on-site and Sector V metro nearby. Weekend tumour-board reviews are hosted here for complex cases referred from Eastern India. We run free community breast-cancer screening camps on the first Saturday of every month. Book a consult or screening camp slot through the portal or WhatsApp chatbot.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-036-facility-hyderabad-banjara',
    Title = 'Onco Global Hyderabad Banjara - Facility Guide',
    Summary = 'Onco Global - Hyderabad Banjara is a 160-bed cancer and transplant centre in Banjara Hills. It houses 4 linear accelerators including an SBRT machine, a dedicated adult-and-paediatric BMT unit, robotic surgery and a high-volume breast and GI oncology programme. Specialty clinics run six days a week. The facility is 15 minutes from Begumpet station and has on-site valet parking. Telugu, Urdu, Hindi and English are spoken. Ayushman Bharat, Aarogyasri, CGHS and leading insurance panels are accepted and a dedicated TPA help-desk assists with pre-authorisations. Book a consult by picking "Hyderabad Banjara" in the patient portal or ask the agent for the Banjara Hills centre.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-037-facility-pune-baner',
    Title = 'Onco Global Pune Baner - Facility Guide',
    Summary = 'Onco Global - Pune Baner is a 90-bed cancer hospital in west Pune serving Baner, Aundh, Balewadi and Hinjewadi IT parks. We provide medical, surgical and radiation oncology, day-care chemo, PET-CT, MRI and a fast-track second-opinion clinic. Corporate tie-ups with major Hinjewadi IT companies include on-site cancer-screening camps. Specialty clinics run 08:00-20:00 weekdays and 08:00-14:00 Saturdays. Marathi, Hindi and English support. The hospital has secure underground parking and a cafe serving oncology-friendly meals. Book a consult from the patient portal by choosing "Pune Baner" or ask the WhatsApp agent for the Baner centre.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-038-facility-jaipur-malviya',
    Title = 'Onco Global Jaipur Malviya - Facility Guide',
    Summary = 'Onco Global - Jaipur Malviya is our Rajasthan cancer centre with 80 beds, offering medical, surgical and radiation oncology, day-care chemotherapy and a tumour-board referral link to our larger centres for complex cases. Services include a dedicated breast oncology clinic, gynae oncology, a head-and-neck clinic and a weekly paediatric oncology clinic staffed by visiting specialists. Hindi, Marwari, Punjabi and English support. Outpatient hours 08:30-20:00. The site is 20 minutes from Jaipur Junction railway station with on-site parking. We coordinate with Mahatma Jyotiba Phule Jan Arogya, Ayushman Bharat and most insurance panels. Pick "Jaipur Malviya" in the portal or WhatsApp to book.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-039-book-first-appointment',
    Title = 'How to Book Your First Appointment',
    Summary = 'Booking a first appointment with Onco Global takes less than 2 minutes. Use any of three channels: (1) patient portal at patients.oncoglobal.example - click New Appointment, choose the city, department (or specific doctor) and pick a time; (2) WhatsApp chat to our official number - just type "book" and our agent will guide you; (3) call the contact centre 24x7. You will need a valid mobile number and email, and any prior reports such as biopsy, imaging or lab results. After booking you receive a confirmation with the location and a preparation checklist. New patients without a specific doctor in mind can choose a department (Medical, Surgical, Radiation, Paediatric or Gynaecologic Oncology) and we will match the right specialist at the chosen city and date.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-040-reschedule-cancel-policy',
    Title = 'Rescheduling and Cancellation Policy',
    Summary = 'Appointments can be rescheduled or cancelled free of charge up to 2 hours before the scheduled time, via the patient portal, WhatsApp or the contact centre. Use your appointment number (format SA-xxxx) and registered email or mobile. If you cancel or miss 3 or more appointments in a row, we may ask you to confirm future bookings in advance. For day-care chemotherapy or radiation sessions, please try to inform us at least 24 hours ahead because slots are in high demand and a prepared drug mix may be wasted if missed. Emergencies are always accommodated - call the helpline. Rescheduling keeps the same appointment number and does not require a new booking.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-041-preparing-for-oncology-consultation',
    Title = 'Preparing for Your Oncology Consultation',
    Summary = 'To make the most of your consultation, bring: a photo ID, insurance card, a current medication list, all prior biopsy or pathology reports and slides, imaging discs (CT, MRI, PET-CT) and the most recent blood tests. A family member is welcome - many decisions are easier with a second listener. Write down your top 3 questions in advance. Arrive 20 minutes early for registration and vitals. Plan for 45 to 75 minutes for a first consult. If you have swallowing difficulty, a sample meal can help the dietician assess you, and if you are on blood thinners, mention this at registration. After the visit you will receive a secure PDF of the clinical note and plan in the patient portal.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-042-followup-appointments-care-plans',
    Title = 'Follow-up Appointments and Care Plans',
    Summary = 'Cancer care does not end after treatment. Your oncologist will set a survivorship schedule - typically every 3 months for the first 2 years, every 6 months for years 3 to 5, then annually. Each visit may include a clinical exam, blood tests, imaging and symptom review. You can view your upcoming appointments, test results and medication list in the patient portal. Reminders are sent by WhatsApp and email 72 hours and again 2 hours before each visit. If you are travelling or relocating, we can transfer your care to another Onco Global centre or share a comprehensive summary with your local doctor. Request a care-plan copy anytime from the contact centre.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-043-telehealth-virtual-consultations',
    Title = 'Virtual and Telehealth Consultations',
    Summary = 'Many oncology follow-ups and second-opinion reviews can be done over video. Our telehealth service is available 7 days a week across time zones. After you book a virtual slot, upload your reports through the secure portal or WhatsApp; the doctor reviews them in advance so you get a focused 20-minute consult. Digital prescriptions, lab requisitions and refills are delivered electronically. Video consults are not suitable for first-time biopsy-driven planning, painful acute symptoms or emergency care - those need an in-person visit. You can switch between in-person and virtual follow-ups freely. Technical support is available through the Help button on the portal or through the WhatsApp agent.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-044-whatsapp-reminders-digital-engagement',
    Title = 'Appointment Reminders via WhatsApp',
    Summary = 'Onco Global sends appointment confirmations, preparation checklists and day-of-visit reminders to the mobile number on your record via our official WhatsApp business account. Reminders arrive 72 hours and 2 hours before each visit and include the clinician name, appointment number and a map link. You can reply directly to reschedule, cancel, request a report or speak to a human agent - the WhatsApp self-service agent handles most requests in one conversation. To opt in, update your preferred channel in the patient portal under Profile > Communication Preferences, or text "START" to our WhatsApp number. Standard WhatsApp data charges apply and messages are encrypted end-to-end.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-045-oncology-nutrition-dietary-support',
    Title = 'Oncology Nutrition and Dietary Support',
    Summary = 'Good nutrition improves treatment tolerance and recovery. Every Onco Global cancer patient can meet a registered oncology dietitian free of cost during day-care visits and inpatient stays. We help with weight loss, taste changes, nausea, mouth sores, swallowing difficulty, bowel issues and diabetes during cancer care. Specialised diets are available for head-and-neck, GI, haemato-oncology and transplant patients. We can also plan Enteral and home-parenteral nutrition where needed. Vegetarian, vegan and regional cuisine options are taken into account. Please bring a 3-day food diary to your first dietitian visit. Book a Nutrition consult through the portal, WhatsApp or ask your oncologist for a referral.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-046-physiotherapy-rehabilitation',
    Title = 'Physical Therapy and Rehabilitation',
    Summary = 'Our oncology rehabilitation team includes physiotherapists, occupational therapists, lymphoedema specialists, speech and swallowing therapists and a rehab physician. Services target fatigue, deconditioning, post-surgical stiffness, chemo-induced neuropathy, lymphoedema after breast or gynae surgery, and speech/swallowing issues after head-and-neck treatment. Sessions are delivered in-person at each Onco Global centre and as home-based tele-rehab for selected patients. Early referral (before or during treatment) gives the best outcomes. A structured prehabilitation programme before major surgery reduces hospital stay and complications. Ask your oncologist for a Rehab consult or request one from the portal; most plans are 6 to 12 sessions.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-047-hair-loss-wig-services',
    Title = 'Hair Loss and Wig Services',
    Summary = 'Hair loss during chemotherapy is common but usually temporary. Our scalp-cooling programme (available at Powai, Whitefield, Dwarka and Hyderabad Banjara) can reduce hair loss with many chemo regimens. Sessions add 30-60 minutes per chemo visit and are included free with eligible regimens. For patients who still lose hair we run a wig-fitting service with natural and synthetic options starting from 2,500 INR, and a free-wig scheme for patients supported by our patient-welfare trust. Eyebrow and eyelash tattooing partners are listed. Hair usually regrows over 3 to 6 months after chemo ends. Ask your chemo day-care nurse about scalp cooling or book a Wig Fitting through the portal.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-048-fertility-preservation-before-treatment',
    Title = 'Fertility Preservation Before Treatment',
    Summary = 'Chemotherapy, radiation and some hormone therapies can affect future fertility. If you are of reproductive age, please discuss fertility preservation with your oncologist before starting treatment. The Onco Global oncofertility clinic offers sperm banking (same-day), embryo or oocyte freezing (2 to 3 weeks before chemo) and ovarian tissue cryopreservation in selected cases. Men and women can be seen the same week as diagnosis to avoid delaying cancer therapy. For adolescents and paediatric patients we coordinate with specialist centres. Costs are insurance-partial and patient-assistance schemes are available. Ask for an Oncofertility consult through the portal; urgent requests are escalated directly to the fertility team.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-049-pain-management-program',
    Title = 'Pain Management Program',
    Summary = 'Cancer pain is manageable. Our pain management team includes palliative physicians, anaesthesia-trained pain specialists, psychologists and physiotherapists. Treatments range from oral medication (paracetamol, NSAIDs, opioids) and neuropathic agents (gabapentin, duloxetine) to interventional procedures: coeliac plexus block, intrathecal pumps, radiofrequency ablation and vertebroplasty. Non-drug approaches include mindfulness, acupuncture-trained therapists and TENS. The WHO analgesic ladder is individualised to each patient. Opioids, when needed, are prescribed safely with tolerance and side-effects carefully monitored. You should never tolerate severe pain - call our 24x7 helpline or request a Pain Clinic visit through the portal same day.'
));
candidates.add(new Knowledge__kav(
    UrlName = 'ka-050-survivorship-followup-care',
    Title = 'Survivorship and Follow-up Care',
    Summary = 'Finishing treatment is an important milestone. Our survivorship programme gives you a personalised care plan covering surveillance scans, symptom watch, vaccinations, bone health, cardiac and second-cancer risk, lifestyle and mental health. Survivorship clinics are available at every Onco Global city, run by specialist nurses and supervised by your oncologist. We encourage annual physicals, structured exercise (150 minutes per week), smoking cessation and alcohol moderation. Support groups - breast cancer, blood cancer, paediatric survivors and caregivers - meet monthly in person and online. A smartphone survivorship diary is available in the patient portal. Book a Survivorship visit at least once a year; urgent symptoms are seen within 48 hours.'
));

for (Knowledge__kav k : candidates) {
    k.Language = 'en_US';
}

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
System.debug('[KB-2] Candidates: ' + candidates.size() + ', new drafts: ' + drafts.size());

if (!drafts.isEmpty()) {
    insert drafts;
    System.debug('[KB-2] Inserted drafts: ' + drafts.size());

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
            System.debug('[KB-2] Publish failed for ' + k.Title + ': ' + e.getMessage());
        }
    }
    System.debug('[KB-2] Published articles: ' + published);
}

System.debug('[KB-2] DONE');

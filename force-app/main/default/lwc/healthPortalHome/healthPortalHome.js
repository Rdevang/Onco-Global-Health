import { LightningElement, api, track } from 'lwc';

const SCROLL_THRESHOLD_PX = 24;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default class HealthPortalHome extends LightningElement {
    @api brandName = 'Onco Global Health';
    @api emergencyPhone = '+1-800-911-CARE';
    @api agentLaunchUrl = '';

    @track searchTerm = '';
    @track newsletterEmail = '';
    @track newsletterError = '';
    @track newsletterSuccess = false;
    @track isHeaderSolid = false;
    @track statusMessage = '';
    @track openFaqId = '';

    _scrollHandler;

    /* ------------------------------------------------------------------
     * Lifecycle
     * ----------------------------------------------------------------*/
    connectedCallback() {
        this._scrollHandler = () => {
            const scrolled = (window.scrollY || window.pageYOffset || 0) > SCROLL_THRESHOLD_PX;
            if (scrolled !== this.isHeaderSolid) {
                this.isHeaderSolid = scrolled;
            }
        };
        window.addEventListener('scroll', this._scrollHandler, { passive: true });
    }

    disconnectedCallback() {
        if (this._scrollHandler) {
            window.removeEventListener('scroll', this._scrollHandler);
            this._scrollHandler = null;
        }
    }

    /* ------------------------------------------------------------------
     * Computed UI state
     * ----------------------------------------------------------------*/
    get headerClass() {
        const base = 'portal-header slds-grid slds-grid_align-spread slds-grid_vertical-align-center';
        return this.isHeaderSolid ? `${base} portal-header_solid` : `${base} portal-header_transparent`;
    }

    get emergencyHref() {
        const cleaned = (this.emergencyPhone || '').replace(/[^+\d]/g, '');
        return cleaned ? `tel:${cleaned}` : '#';
    }

    /* ------------------------------------------------------------------
     * Static-ish content collections (kept as getters so they stay reactive
     * to brandName / config changes from Builder).
     * ----------------------------------------------------------------*/
    get trustStats() {
        return [
            {
                key: 'patients',
                value: '120K+',
                label: 'Patients cared for in the last 12 months',
                icon: 'utility:heart'
            },
            {
                key: 'providers',
                value: '450+',
                label: 'Board-certified specialists across our network',
                icon: 'utility:user'
            },
            {
                key: 'support',
                value: '24/7',
                label: 'Always-on triage support and digital care navigation',
                icon: 'utility:clock'
            },
            {
                key: 'access',
                value: '< 48 hr',
                label: 'Average time from inquiry to first oncology appointment',
                icon: 'utility:event'
            }
        ];
    }

    get featureCards() {
        return [
            {
                key: 'schedule',
                title: 'Schedule Appointment',
                description:
                    'Find a time that works with one of our specialists or care teams. Same-day options often available.',
                icon: 'utility:event',
                ctaLabel: 'Book a visit',
                ariaLabel: 'Schedule a new appointment',
                bullets: [
                    'In-person or virtual',
                    'Department-first or named-doctor flow',
                    'Choose a slot, confirm in seconds'
                ]
            },
            {
                key: 'portal',
                title: 'Patient Portal Login',
                description:
                    'View test results, message your care team, manage prescriptions, and access your full visit history securely.',
                icon: 'utility:user',
                ctaLabel: 'Sign in',
                ariaLabel: 'Sign in to the patient portal',
                bullets: [
                    'Secure HIPAA-aligned access',
                    'Lab and imaging results',
                    'Family and caregiver delegation'
                ]
            },
            {
                key: 'symptoms',
                title: 'Symptom Checker',
                description:
                    'Answer a few quick questions to find the right level of care—and get directed to the right specialist if needed.',
                icon: 'utility:health_check',
                ctaLabel: 'Start check',
                ariaLabel: 'Start the symptom checker',
                bullets: [
                    'Clinically reviewed pathways',
                    'Triage to self-care, primary, or specialist',
                    'Hand-off straight to scheduling'
                ]
            }
        ];
    }

    get specialties() {
        return [
            {
                key: 'medical',
                name: 'Medical Oncology',
                blurb: 'Systemic therapies including chemotherapy, immunotherapy, and targeted treatment.',
                icon: 'utility:prescription'
            },
            {
                key: 'surgical',
                name: 'Surgical Oncology',
                blurb: 'Curative and palliative cancer surgery from minimally invasive to complex resection.',
                icon: 'utility:cut'
            },
            {
                key: 'radiation',
                name: 'Radiation Oncology',
                blurb: 'IMRT, SBRT, and brachytherapy delivered with image-guided precision.',
                icon: 'utility:lightning'
            },
            {
                key: 'pediatric',
                name: 'Pediatric Oncology',
                blurb: 'Whole-family cancer care for children, with child-life specialists on every team.',
                icon: 'utility:user'
            },
            {
                key: 'gyn',
                name: 'Gynecologic Oncology',
                blurb: 'Specialized care for ovarian, uterine, cervical, and other gynecologic cancers.',
                icon: 'utility:favorite'
            },
            {
                key: 'palliative',
                name: 'Hemato-Oncology & Palliative Care',
                blurb: 'Blood cancer treatment alongside symptom-focused supportive care for any stage.',
                icon: 'utility:hierarchy'
            }
        ];
    }

    get journeySteps() {
        return [
            {
                key: 'search',
                step: '01',
                title: 'Search or ask',
                blurb: 'Tell us what you need—a doctor, a department, or just your symptoms. Our digital concierge guides you.'
            },
            {
                key: 'choose',
                step: '02',
                title: 'Choose your care',
                blurb: 'Compare specialists, locations, and visit types. See live availability across our network.'
            },
            {
                key: 'schedule',
                step: '03',
                title: 'Schedule in seconds',
                blurb: 'Pick a time that fits, confirm online, and we will register your chart automatically if you are new.'
            },
            {
                key: 'visit',
                step: '04',
                title: 'Show up cared for',
                blurb: 'Get pre-visit instructions, secure messaging, and a single dashboard for results, billing, and follow-ups.'
            }
        ];
    }

    get testimonials() {
        return [
            {
                key: 't1',
                quote:
                    'I went from a confusing diagnosis to a treatment plan in a single afternoon. The navigator and the medical oncology team made me feel like a person, not a chart.',
                name: 'Priya S.',
                role: 'Patient — Bengaluru',
                initials: 'PS'
            },
            {
                key: 't2',
                quote:
                    'My mother needed urgent surgical oncology care. We booked, registered, and got pre-op instructions the same day. The clarity was a relief during a hard week.',
                name: 'Aditya C.',
                role: 'Family caregiver — Bengaluru',
                initials: 'AC'
            },
            {
                key: 't3',
                quote:
                    'I love that I can message my care team and pull labs from my phone. The symptom checker even routed me to the right specialist on a weekend.',
                name: 'Rohan M.',
                role: 'Patient — Mumbai',
                initials: 'RM'
            }
        ];
    }

    get locations() {
        return [
            {
                key: 'hsr',
                name: 'Onco Global — Bengaluru HSR',
                city: 'Bengaluru, India',
                blurb: 'Comprehensive surgical and gynecologic oncology programs.',
                hours: 'Mon–Sat · 7:00 AM – 9:00 PM'
            },
            {
                key: 'whitefield',
                name: 'Onco Global — Bengaluru Whitefield',
                city: 'Bengaluru, India',
                blurb: 'Medical and pediatric oncology with on-site infusion suite.',
                hours: 'Mon–Sat · 7:00 AM – 9:00 PM'
            },
            {
                key: 'mumbai',
                name: 'Onco Global — Mumbai Andheri',
                city: 'Mumbai, India',
                blurb: 'Radiation oncology, hematology, and second-opinion clinic.',
                hours: 'Mon–Sat · 8:00 AM – 8:00 PM'
            }
        ];
    }

    get articles() {
        return [
            {
                key: 'a1',
                category: 'Treatment basics',
                title: 'What to expect during your first chemotherapy infusion',
                blurb:
                    'A walk-through of arrival, vitals, infusion, and recovery — plus what to bring and what to ask.',
                readTime: '6 min read'
            },
            {
                key: 'a2',
                category: 'Wellness',
                title: 'Nutrition during cancer treatment: a starter guide',
                blurb:
                    'Practical, evidence-based advice on eating well when appetite, taste, and energy shift.',
                readTime: '8 min read'
            },
            {
                key: 'a3',
                category: 'Caregivers',
                title: 'Supporting a loved one through diagnosis and treatment',
                blurb:
                    'How caregivers can stay informed, ask the right questions, and protect their own well-being.',
                readTime: '5 min read'
            }
        ];
    }

    get faqs() {
        return [
            {
                key: 'faq1',
                question: 'Do I need a referral to book an appointment?',
                answer:
                    'No. Most of our specialties accept self-referrals. If you would like, our digital concierge can recommend a department based on your symptoms before you book.'
            },
            {
                key: 'faq2',
                question: 'Are virtual visits available?',
                answer:
                    'Yes. Many follow-up visits, second opinions, and supportive-care visits can be done virtually. You can pick virtual or in-person on the scheduling screen.'
            },
            {
                key: 'faq3',
                question: 'What insurance do you accept?',
                answer:
                    'We accept all major commercial plans and most national programs. You can confirm your coverage during scheduling, and our financial counselors review every estimate before your visit.'
            },
            {
                key: 'faq4',
                question: 'How do I get my medical records?',
                answer:
                    'Sign in to the Patient Portal to download recent results and visit summaries. For older records, request a release through the portal and we will deliver them securely within 5 business days.'
            },
            {
                key: 'faq5',
                question: 'What if I am a brand-new patient?',
                answer:
                    'You can book straight from this page. If we do not find a chart on file, we will register a new one with just your name, email, and consent — your full intake happens before your first visit.'
            }
        ];
    }

    get faqsView() {
        const open = this.openFaqId;
        return this.faqs.map((f) => {
            const isOpen = f.key === open;
            return {
                ...f,
                isOpen,
                buttonAria: isOpen ? 'true' : 'false',
                panelHidden: !isOpen,
                itemClass: isOpen
                    ? 'portal-faq__item portal-faq__item_open'
                    : 'portal-faq__item'
            };
        });
    }

    get newsletterFieldClass() {
        return this.newsletterError
            ? 'slds-form-element slds-has-error portal-newsletter__field'
            : 'slds-form-element portal-newsletter__field';
    }

    /* ------------------------------------------------------------------
     * Handlers
     * ----------------------------------------------------------------*/
    handleSearchChange(event) {
        this.searchTerm = event.target.value || '';
    }

    handleSearchSubmit(event) {
        if (event && event.preventDefault) {
            event.preventDefault();
        }
        const term = (this.searchTerm || '').trim();
        if (!term) {
            this.announce('Please enter a provider name, clinic, or specialty to search.');
            const input = this.template.querySelector('[data-id="hero-search"]');
            if (input && typeof input.focus === 'function') {
                input.focus();
            }
            return;
        }
        this.announce(`Searching for "${term}"...`);
        this.dispatchEvent(
            new CustomEvent('providersearch', {
                detail: { term },
                bubbles: true,
                composed: true
            })
        );
    }

    handleQuickFilter(event) {
        const term = event.currentTarget.dataset.term || '';
        if (!term) return;
        this.searchTerm = term;
        this.announce(`Searching for "${term}"...`);
        this.dispatchEvent(
            new CustomEvent('providersearch', {
                detail: { term, source: 'quick-filter' },
                bubbles: true,
                composed: true
            })
        );
    }

    handleFeatureAction(event) {
        const key = event.currentTarget.dataset.key;
        this.dispatchEvent(
            new CustomEvent('featureaction', {
                detail: { key },
                bubbles: true,
                composed: true
            })
        );
        const map = {
            schedule: 'Opening appointment scheduler...',
            portal: 'Opening patient portal sign-in...',
            symptoms: 'Opening symptom checker...'
        };
        this.announce(map[key] || 'Opening...');
    }

    handleSpecialtyClick(event) {
        const key = event.currentTarget.dataset.key;
        const name = event.currentTarget.dataset.name;
        this.dispatchEvent(
            new CustomEvent('specialtyselect', {
                detail: { key, name },
                bubbles: true,
                composed: true
            })
        );
        this.announce(`Exploring ${name}...`);
    }

    handleLocationClick(event) {
        const key = event.currentTarget.dataset.key;
        const name = event.currentTarget.dataset.name;
        this.dispatchEvent(
            new CustomEvent('locationselect', {
                detail: { key, name },
                bubbles: true,
                composed: true
            })
        );
        this.announce(`Loading ${name}...`);
    }

    handleArticleClick(event) {
        const key = event.currentTarget.dataset.key;
        const title = event.currentTarget.dataset.title;
        this.dispatchEvent(
            new CustomEvent('articleselect', {
                detail: { key, title },
                bubbles: true,
                composed: true
            })
        );
        this.announce(`Opening "${title}"...`);
    }

    handleFaqToggle(event) {
        const key = event.currentTarget.dataset.key;
        this.openFaqId = this.openFaqId === key ? '' : key;
    }

    handleLaunchAssistant() {
        if (this.agentLaunchUrl) {
            window.open(this.agentLaunchUrl, '_blank', 'noopener,noreferrer');
        }
        this.announce('Launching Health Assistant...');
        this.dispatchEvent(
            new CustomEvent('launchassistant', {
                bubbles: true,
                composed: true
            })
        );
    }

    handleNewsletterChange(event) {
        this.newsletterEmail = event.target.value || '';
        if (this.newsletterError) {
            this.newsletterError = '';
        }
    }

    handleNewsletterSubmit(event) {
        if (event && event.preventDefault) {
            event.preventDefault();
        }
        const value = (this.newsletterEmail || '').trim();
        if (!value) {
            this.newsletterError = 'Please enter your email address.';
            this.announce(this.newsletterError);
            return;
        }
        if (!EMAIL_RE.test(value)) {
            this.newsletterError = 'Please enter a valid email address (e.g. name@example.com).';
            this.announce(this.newsletterError);
            return;
        }
        this.newsletterError = '';
        this.newsletterSuccess = true;
        this.announce('You are subscribed. Look for our next health digest.');
        this.dispatchEvent(
            new CustomEvent('newslettersignup', {
                detail: { email: value },
                bubbles: true,
                composed: true
            })
        );
        this.newsletterEmail = '';
    }

    handleSkipToMain(event) {
        event.preventDefault();
        const main = this.template.querySelector('[data-id="main-content"]');
        if (main && typeof main.focus === 'function') {
            main.focus();
        }
    }

    announce(message) {
        this.statusMessage = '';
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            this.statusMessage = message;
        }, 50);
    }
}

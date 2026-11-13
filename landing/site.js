(() => {
  const STORAGE_KEY = "tamyrflow.landing.lang";

  const copy = {
    ru: {
      navFeatures: "Возможности",
      navAbout: "О приложении",
      navReviews: "Отзывы",
      navDownload: "Скачать",
      heroPill: "Фитнес и здоровье",
      heroTitleBefore: "Лучшая версия себя ",
      heroTitleGrad: "каждый день",
      heroLead: "TamyrFlow — ваш личный помощник для здоровья, активности и баланса.",
      ctaAppStore: "Скачать в App Store",
      ctaVideo: "Смотреть видео",
      f1Title: "Здоровье",
      f1Body: "Пульс, давление, кислород и температура — всё под контролем.",
      f2Title: "Активность",
      f2Body: "Шаги, калории и тренировки для вашего прогресса.",
      f3Title: "Восстановление",
      f3Body: "Качественный сон и уровень энергии.",
      f4Title: "Аналитика",
      f4Body: "Персональные рекомендации на основе ваших данных.",
      aboutPill: "Удобный интерфейс",
      aboutTitleBefore: "Вся информация в одном ",
      aboutTitleGrad: "приложении",
      aboutLead:
        "Понятные метрики, аккуратный дизайн и всё необходимое, чтобы заботиться о своём здоровье.",
      trustSafe: "Безопасно",
      trustEasy: "Просто",
      ctaTitle: "Начните заботиться о себе уже сегодня",
      ctaBody: "Скачайте TamyrFlow и сделайте первый шаг к лучшей версии себя.",
      footerPrivacy: "Политика конфиденциальности",
      footerTerms: "Условия использования",
      footerSupport: "Поддержка",
      privacyTitle: "Политика конфиденциальности TamyrFlow",
      privacyMeta: "Дата последнего обновления: 12 ноября 2026 года",
      termsTitle: "Условия использования",
      termsMeta: "Дата последнего обновления: 12 ноября 2026 года",
      supportTitle: "Поддержка",
      supportLead:
        "Вопросы по приложению, аккаунту или персональным данным — напишите нам. Обычно отвечаем в рабочие дни.",
      supportEmailLabel: "Email",
      supportPhoneLabel: "Телефон",
      supportCountry: "Страна: Республика Казахстан",
      supportDelete:
        "Удалить аккаунт можно в приложении: Профиль → Удалить аккаунт. Если нужна помощь — напишите на email поддержки.",
      loadingLegal: "Загрузка документа…",
      legalError: "Не удалось загрузить документ. Обновите страницу.",
      navHome: "Главная",
      navPrivacy: "Конфиденциальность",
      navTerms: "Условия",
      navSupport: "Поддержка",
    },
    en: {
      navFeatures: "Features",
      navAbout: "About",
      navReviews: "Reviews",
      navDownload: "Download",
      heroPill: "Fitness & health",
      heroTitleBefore: "A better version of you ",
      heroTitleGrad: "every day",
      heroLead: "TamyrFlow is your personal companion for health, activity, and balance.",
      ctaAppStore: "Download on the App Store",
      ctaVideo: "Watch video",
      f1Title: "Health",
      f1Body: "Heart rate, blood pressure, oxygen, and temperature — all in one place.",
      f2Title: "Activity",
      f2Body: "Steps, calories, and workouts to support your progress.",
      f3Title: "Recovery",
      f3Body: "Quality sleep and energy levels.",
      f4Title: "Analytics",
      f4Body: "Personal insights based on your data.",
      aboutPill: "Simple interface",
      aboutTitleBefore: "Everything in one ",
      aboutTitleGrad: "app",
      aboutLead: "Clear metrics, polished design, and everything you need to care for your health.",
      trustSafe: "Secure",
      trustEasy: "Easy",
      ctaTitle: "Start taking care of yourself today",
      ctaBody: "Download TamyrFlow and take the first step toward a better version of yourself.",
      footerPrivacy: "Privacy Policy",
      footerTerms: "Terms of Use",
      footerSupport: "Support",
      privacyTitle: "TamyrFlow Privacy Policy",
      privacyMeta: "Last updated: November 12, 2026",
      termsTitle: "Terms of Use",
      termsMeta: "Last updated: November 12, 2026",
      supportTitle: "Support",
      supportLead:
        "Questions about the app, your account, or personal data — email us. We typically reply on business days.",
      supportEmailLabel: "Email",
      supportPhoneLabel: "Phone",
      supportCountry: "Country: Republic of Kazakhstan",
      supportDelete:
        "You can delete your account in the app: Profile → Delete account. Email support if you need help.",
      loadingLegal: "Loading document…",
      legalError: "Could not load the document. Please refresh.",
      navHome: "Home",
      navPrivacy: "Privacy",
      navTerms: "Terms",
      navSupport: "Support",
    },
    kk: {
      navFeatures: "Мүмкіндіктер",
      navAbout: "Қолданба туралы",
      navReviews: "Пікірлер",
      navDownload: "Жүктеу",
      heroPill: "Фитнес және денсаулық",
      heroTitleBefore: "Өзіңіздің үздік нұсқаңыз ",
      heroTitleGrad: "әр күн сайын",
      heroLead: "TamyrFlow — денсаулық, белсенділік және тепе-теңдік үшін жеке көмекшіңіз.",
      ctaAppStore: "App Store-дан жүктеу",
      ctaVideo: "Видеоны көру",
      f1Title: "Денсаулық",
      f1Body: "Пульс, қысым, оттегі және температура — бәрі бақылауда.",
      f2Title: "Белсенділік",
      f2Body: "Қадам, калория және жаттығулар — прогресіңіз үшін.",
      f3Title: "Қалпына келу",
      f3Body: "Сапалы ұйқы және энергия деңгейі.",
      f4Title: "Аналитика",
      f4Body: "Деректеріңізге негізделген жеке ұсыныстар.",
      aboutPill: "Ыңғайлы интерфейс",
      aboutTitleBefore: "Барлық ақпарат бір ",
      aboutTitleGrad: "қолданбада",
      aboutLead:
        "Түсінікті көрсеткіштер, ұқыпты дизайн және денсаулығыңызға қамқорлық үшін қажеттінің бәрі.",
      trustSafe: "Қауіпсіз",
      trustEasy: "Оңай",
      ctaTitle: "Өзіңізге бүгіннен бастап қамқор болыңыз",
      ctaBody: "TamyrFlow-ды жүктеп, үздік нұсқаңызға алғашқы қадам жасаңыз.",
      footerPrivacy: "Құпиялылық саясаты",
      footerTerms: "Пайдалану шарттары",
      footerSupport: "Қолдау",
      privacyTitle: "TamyrFlow құпиялылық саясаты",
      privacyMeta: "Соңғы жаңарту: 12 қараша 2026 жыл",
      termsTitle: "Пайдалану шарттары",
      termsMeta: "Соңғы жаңарту: 12 қараша 2026 жыл",
      supportTitle: "Қолдау",
      supportLead:
        "Қолданба, аккаунт немесе жеке деректер бойынша сұрақтар болса — бізге жазыңыз. Әдетте жұмыс күндері жауап береміз.",
      supportEmailLabel: "Email",
      supportPhoneLabel: "Телефон",
      supportCountry: "Ел: Қазақстан Республикасы",
      supportDelete:
        "Аккаунтты қолданбада жоюға болады: Профиль → Аккаунтты жою. Көмек керек болса — қолдау email-іне жазыңыз.",
      loadingLegal: "Құжат жүктелуде…",
      legalError: "Құжатты жүктеу мүмкін болмады. Бетті жаңартыңыз.",
      navHome: "Басты бет",
      navPrivacy: "Құпиялылық",
      navTerms: "Шарттар",
      navSupport: "Қолдау",
    },
  };

  function getLang() {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved === "ru" || saved === "en" || saved === "kk") return saved;
    const nav = (navigator.language || "ru").toLowerCase();
    if (nav.startsWith("kk") || nav.startsWith("kz")) return "kk";
    if (nav.startsWith("en")) return "en";
    return "ru";
  }

  function setLang(lang) {
    if (!copy[lang]) lang = "ru";
    localStorage.setItem(STORAGE_KEY, lang);
    document.documentElement.lang = lang;
    const t = copy[lang];
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (t[key] != null) el.textContent = t[key];
    });
    document.querySelectorAll(".lang-menu [data-lang]").forEach((btn) => {
      btn.setAttribute("aria-checked", String(btn.dataset.lang === lang));
    });
    const host = document.getElementById("legal-root");
    if (host?.dataset.doc) renderLegal(host.dataset.doc, lang);
  }

  function closeLangDropdowns() {
    document.querySelectorAll(".lang-dropdown.is-open").forEach((dd) => {
      dd.classList.remove("is-open");
      const trigger = dd.querySelector(".lang-trigger");
      const menu = dd.querySelector(".lang-menu");
      if (trigger) trigger.setAttribute("aria-expanded", "false");
      if (menu) menu.hidden = true;
    });
  }

  function initLangDropdowns() {
    document.querySelectorAll(".lang-dropdown").forEach((dd) => {
      const trigger = dd.querySelector(".lang-trigger");
      const menu = dd.querySelector(".lang-menu");
      if (!trigger || !menu) return;

      trigger.addEventListener("click", (e) => {
        e.stopPropagation();
        const willOpen = !dd.classList.contains("is-open");
        closeLangDropdowns();
        if (!willOpen) return;
        dd.classList.add("is-open");
        trigger.setAttribute("aria-expanded", "true");
        menu.hidden = false;
      });

      menu.querySelectorAll("[data-lang]").forEach((btn) => {
        btn.addEventListener("click", (e) => {
          e.stopPropagation();
          setLang(btn.dataset.lang);
          closeLangDropdowns();
        });
      });
    });

    document.addEventListener("click", () => closeLangDropdowns());
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") closeLangDropdowns();
    });
  }

  function setStatusMessage(host, text) {
    while (host.firstChild) host.removeChild(host.firstChild);
    const p = document.createElement("p");
    p.className = "meta";
    p.textContent = text;
    host.appendChild(p);
  }

  function appendLegalBlock(parent, block) {
    if (block.type === "h3") {
      const h3 = document.createElement("h3");
      h3.textContent = String(block.text ?? "");
      parent.appendChild(h3);
      return;
    }
    if (block.type === "p") {
      const p = document.createElement("p");
      p.textContent = String(block.text ?? "");
      parent.appendChild(p);
      return;
    }
    if (block.type === "ul") {
      const ul = document.createElement("ul");
      for (const item of block.items || []) {
        const li = document.createElement("li");
        li.textContent = String(item);
        ul.appendChild(li);
      }
      parent.appendChild(ul);
      return;
    }
    if (block.type === "contact") {
      const p = document.createElement("p");
      p.className = "contact-row";
      const strong = document.createElement("strong");
      strong.textContent = `${String(block.label ?? "")}:`;
      p.appendChild(strong);
      p.appendChild(document.createTextNode(` ${String(block.value ?? "")}`));
      parent.appendChild(p);
    }
  }

  async function renderLegal(docKey, lang) {
    const host = document.getElementById("legal-root");
    if (!host) return;
    const t = copy[lang] || copy.ru;
    setStatusMessage(host, t.loadingLegal);
    try {
      const res = await fetch("./legal-data.json", { cache: "no-store" });
      if (!res.ok) throw new Error("fetch failed");
      const data = await res.json();
      const sections = data[docKey]?.[lang] || data[docKey]?.ru || [];
      if (!sections.length) throw new Error("empty");
      while (host.firstChild) host.removeChild(host.firstChild);
      for (const section of sections) {
        const sectionEl = document.createElement("section");
        sectionEl.id = `s-${String(section.id ?? "")}`;
        const h2 = document.createElement("h2");
        h2.textContent = String(section.title ?? "");
        sectionEl.appendChild(h2);
        for (const block of section.blocks || []) {
          appendLegalBlock(sectionEl, block);
        }
        host.appendChild(sectionEl);
      }
    } catch {
      setStatusMessage(host, t.legalError);
    }
  }

  function initScrollReveals() {
    const nodes = Array.from(document.querySelectorAll("[data-reveal]"));
    if (!nodes.length) return;

    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      nodes.forEach((el) => el.classList.add("is-visible"));
      return;
    }

    const io = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (!entry.isIntersecting) continue;
          entry.target.classList.add("is-visible");
          io.unobserve(entry.target);
        }
      },
      { threshold: 0.18, rootMargin: "0px 0px -8% 0px" }
    );

    nodes.forEach((el) => io.observe(el));
  }

  function initHeaderScroll() {
    const header = document.querySelector(".site-header");
    if (!header) return;
    const onScroll = () => {
      header.classList.toggle("is-scrolled", window.scrollY > 12);
    };
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
  }

  document.addEventListener("DOMContentLoaded", () => {
    initLangDropdowns();
    setLang(getLang());
    initScrollReveals();
    initHeaderScroll();
  });
})();

(() => {
  const STORAGE_KEY = "tamyrflow.landing.lang";

  const copy = {
    ru: {
      navFeatures: "Возможности",
      navAbout: "О приложении",
      navReviews: "Отзывы",
      navDownload: "Скачать",
      heroPill: "Фитнес и здоровье",
      heroTitleBefore: "Лучше версия себя ",
      heroTitleGrad: "каждый день",
      heroLead: "TamyrFlow — твой личный помощник для здоровья, активности и баланса.",
      ctaAppStore: "Скачать в App Store",
      ctaVideo: "Смотреть видео",
      f1Title: "Здоровье",
      f1Body: "Пульс, давление, кислород и температура — всё под контролем.",
      f2Title: "Активность",
      f2Body: "Шаги, калории и тренировки для твоего прогресса.",
      f3Title: "Восстановление",
      f3Body: "Качественный сон и уровень энергии.",
      f4Title: "Аналитика",
      f4Body: "Персональные рекомендации на основе твоих данных.",
      aboutPill: "Удобный интерфейс",
      aboutTitleBefore: "Вся информация в одном ",
      aboutTitleGrad: "приложении",
      aboutLead:
        "Простые и понятные метрики, стильный дизайн и всё, что нужно для заботы о своём здоровье.",
      trustSafe: "Безопасно",
      trustEasy: "Легко",
      ctaTitle: "Начни заботиться о себе уже сегодня",
      ctaBody: "Скачай TamyrFlow и сделай первый шаг к лучшей версии себя",
      footerPrivacy: "Политика конфиденциальности",
      footerTerms: "Условия использования",
      footerSupport: "Поддержка",
      privacyTitle: "Политика конфиденциальности",
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
        "Удаление аккаунта доступно в приложении: Профиль → Удалить аккаунт. При необходимости напишите на email поддержки.",
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
      heroTitleBefore: "A better you ",
      heroTitleGrad: "every day",
      heroLead: "TamyrFlow — your personal helper for health, activity, and balance.",
      ctaAppStore: "Download on the App Store",
      ctaVideo: "Watch video",
      f1Title: "Health",
      f1Body: "Pulse, blood pressure, oxygen, and temperature — all in one place.",
      f2Title: "Activity",
      f2Body: "Steps, calories, and workouts for your progress.",
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
      ctaBody: "Download TamyrFlow and take the first step toward a better you",
      footerPrivacy: "Privacy Policy",
      footerTerms: "Terms of Use",
      footerSupport: "Support",
      privacyTitle: "Privacy Policy",
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
        "You can delete your account in the app: Profile → Delete account. Contact support by email if you need help.",
      loadingLegal: "Loading document…",
      legalError: "Could not load the document. Please refresh.",
      navHome: "Home",
      navPrivacy: "Privacy",
      navTerms: "Terms",
      navSupport: "Support",
    },
  };

  function getLang() {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved === "ru" || saved === "en") return saved;
    return (navigator.language || "ru").toLowerCase().startsWith("en") ? "en" : "ru";
  }

  function setLang(lang) {
    localStorage.setItem(STORAGE_KEY, lang);
    document.documentElement.lang = lang;
    const t = copy[lang];
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (t[key] != null) el.textContent = t[key];
    });
    document.querySelectorAll(".lang-switch button").forEach((btn) => {
      btn.setAttribute("aria-pressed", String(btn.dataset.lang === lang));
    });
    const host = document.getElementById("legal-root");
    if (host?.dataset.doc) renderLegal(host.dataset.doc, lang);
  }

  function setStatusMessage(host, text) {
    while (host.firstChild) host.removeChild(host.firstChild);
    const p = document.createElement("p");
    p.className = "meta";
    p.textContent = text;
    host.appendChild(p);
  }

  function appendLegalBlock(parent, block) {
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
    const t = copy[lang];
    setStatusMessage(host, t.loadingLegal);
    try {
      const res = await fetch("./legal-data.json", { cache: "no-store" });
      if (!res.ok) throw new Error("fetch failed");
      const data = await res.json();
      const sections = data[docKey]?.[lang] || [];
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
    document.querySelectorAll(".lang-switch button").forEach((btn) => {
      btn.addEventListener("click", () => setLang(btn.dataset.lang));
    });
    setLang(getLang());
    initScrollReveals();
    initHeaderScroll();
  });
})();

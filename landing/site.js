(() => {
  const STORAGE_KEY = "tamyrflow.landing.lang";

  const copy = {
    ru: {
      navHome: "Главная",
      navPrivacy: "Конфиденциальность",
      navTerms: "Условия",
      navSupport: "Поддержка",
      eyebrow: "Фитнес и wellness",
      heroTitle: "TamyrFlow",
      heroLead:
        "Приложение для отслеживания активности и показателей с совместимых умных часов и Apple Health.",
      ctaPrivacy: "Политика конфиденциальности",
      ctaSupport: "Поддержка",
      featuresTitle: "Что внутри",
      featuresLead: "Коротко о возможностях приложения для App Store и новых пользователей.",
      f1Title: "Часы по Bluetooth",
      f1Body: "Подключение совместимых часов, синхронизация шагов, пульса и других доступных метрик.",
      f2Title: "Apple Health",
      f2Body: "Чтение разрешённых показателей из Apple Health. Запись в HealthKit не выполняется.",
      f3Title: "Цели и профиль",
      f3Body: "Личный профиль, цели и история измерений в облаке при входе в аккаунт.",
      disclaimer:
        "TamyrFlow предназначен для фитнеса и общего wellness. Это не медицинское изделие и не заменяет консультацию врача.",
      footerRights: "© TamyrFlow. Республика Казахстан.",
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
    },
    en: {
      navHome: "Home",
      navPrivacy: "Privacy",
      navTerms: "Terms",
      navSupport: "Support",
      eyebrow: "Fitness & wellness",
      heroTitle: "TamyrFlow",
      heroLead:
        "Track activity and wellness metrics from compatible smartwatches and Apple Health.",
      ctaPrivacy: "Privacy Policy",
      ctaSupport: "Support",
      featuresTitle: "What’s inside",
      featuresLead: "A short overview for App Store visitors and new users.",
      f1Title: "Bluetooth watch",
      f1Body: "Connect a compatible watch and sync steps, heart rate, and other available metrics.",
      f2Title: "Apple Health",
      f2Body: "Read allowed metrics from Apple Health. TamyrFlow does not write to HealthKit.",
      f3Title: "Goals & profile",
      f3Body: "Personal profile, goals, and measurement history in the cloud when signed in.",
      disclaimer:
        "TamyrFlow is for fitness and general wellness. It is not a medical device and does not replace professional medical advice.",
      footerRights: "© TamyrFlow. Republic of Kazakhstan.",
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
    applyCopy(lang);
    document.querySelectorAll(".lang-switch button").forEach((btn) => {
      btn.setAttribute("aria-pressed", String(btn.dataset.lang === lang));
    });
    const host = document.getElementById("legal-root");
    if (host && host.dataset.doc) {
      renderLegal(host.dataset.doc, lang);
    }
  }

  function applyCopy(lang) {
    const t = copy[lang];
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const key = el.getAttribute("data-i18n");
      if (t[key] != null) el.textContent = t[key];
    });
    document.title = document.body.dataset.titleTemplate
      ? document.body.dataset.titleTemplate.replace("{brand}", "TamyrFlow")
      : "TamyrFlow";
  }

  function escapeHtml(s) {
    return String(s)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;");
  }

  async function renderLegal(docKey, lang) {
    const host = document.getElementById("legal-root");
    if (!host) return;
    const t = copy[lang];
    host.innerHTML = `<p class="meta">${escapeHtml(t.loadingLegal)}</p>`;
    try {
      const res = await fetch("./legal-data.json", { cache: "no-store" });
      if (!res.ok) throw new Error("fetch failed");
      const data = await res.json();
      const sections = data[docKey]?.[lang] || [];
      if (!sections.length) throw new Error("empty");
      host.innerHTML = sections
        .map((section) => {
          const blocks = (section.blocks || [])
            .map((b) => {
              if (b.type === "p") return `<p>${escapeHtml(b.text)}</p>`;
              if (b.type === "ul") {
                return `<ul>${(b.items || []).map((i) => `<li>${escapeHtml(i)}</li>`).join("")}</ul>`;
              }
              if (b.type === "contact") {
                return `<p class="contact-row"><strong>${escapeHtml(b.label)}:</strong> ${escapeHtml(b.value)}</p>`;
              }
              return "";
            })
            .join("");
          return `<section id="s-${escapeHtml(section.id)}"><h2>${escapeHtml(section.title)}</h2>${blocks}</section>`;
        })
        .join("");
    } catch {
      host.innerHTML = `<p class="meta">${escapeHtml(t.legalError)}</p>`;
    }
  }

  document.addEventListener("DOMContentLoaded", () => {
    document.querySelectorAll(".lang-switch button").forEach((btn) => {
      btn.addEventListener("click", () => setLang(btn.dataset.lang));
    });
    setLang(getLang());
  });
})();

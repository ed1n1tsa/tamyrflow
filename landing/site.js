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
      navSmartwatch: "Часы",
      swPill: "Совместимое устройство",
      swHeroTitle: "ET488 Smartwatch",
      swHeroLead:
        "Совместимые умные часы для отслеживания активности и показателей общего самочувствия с TamyrFlow.",
      swModelLabel: "Модель",
      swConnectLabel: "Подключение",
      swConnectValue: "Bluetooth",
      swAppLabel: "Приложение",
      swIntegration:
        "TamyrFlow подключается к совместимым ET488 по Bluetooth, получает поддерживаемые показатели с часов и показывает значения, тренды и историю в приложении. Доступность метрик зависит от аппаратного обеспечения и прошивки устройства.",
      swPhotoFront: "Спереди",
      swPhotoSide: "Сбоку",
      swPhotoAngle: "Ракурс",
      swPhotoBack: "Сзади",
      swFeaturesTitle: "Поддерживаемые функции",
      swFeaturesLead:
        "TamyrFlow может отображать следующие данные о самочувствии и активности, если их передаёт совместимый ET488. Доступность зависит от аппаратного обеспечения и прошивки. Показатели предназначены для фитнеса и общего самочувствия — без заявлений о медицинской точности.",
      swF1: "Пульс (Heart Rate)",
      swF1Body: "Показания пульса с подключённых часов.",
      swF2: "Кислород в крови (SpO₂)",
      swF2Body: "Значения SpO₂ при поддержке устройством.",
      swF3: "Температура тела",
      swF3Body: "Температура при наличии датчика.",
      swF4: "Артериальное давление",
      swF4Body: "Давление при поддержке прошивкой.",
      swF5: "Шаги за день",
      swF5Body: "Количество шагов, синхронизированное с часов.",
      swF6: "Активность",
      swF6Body: "Прогресс активности и связанные фитнес-данные в приложении.",
      swF7: "История измерений",
      swF7Body: "Прошлые показания, графики и тренды в TamyrFlow.",
      swF8: "Синхронизация Bluetooth",
      swF8Body: "Сопряжение и передача данных по Bluetooth.",
      swHowTitle: "Как это работает",
      swHowLead:
        "Простой путь от установки до просмотра данных. Часть экранов TamyrFlow доступна без подключённых часов; живые измерения требуют сопряжённого совместимого устройства.",
      swStep1Title: "Установите TamyrFlow",
      swStep1Body: "Скачайте приложение для iOS и создайте аккаунт или войдите.",
      swStep2Title: "Подключите ET488 по Bluetooth",
      swStep2Body:
        "Сопрягите совместимые часы ET488. Разрешение на геолокацию может запрашиваться только для поиска устройств поблизости.",
      swStep3Title: "Запустите поддерживаемое измерение",
      swStep3Body: "Используйте часы для поддерживаемого измерения самочувствия.",
      swStep4Title: "Смотрите данные в TamyrFlow",
      swStep4Body: "Просматривайте полученные значения, тренды и историю в приложении.",
      swDocsTitle: "Документация устройства",
      swDocsLead:
        "Сопроводительные документы для ET488. PDF открываются по публичным URL, когда проверенный файл доступен. Документы на проверке помечены соответствующим статусом — без вымышленных сертификатов и непроверенных отметок «Verified».",
      docsCatDevice: "Документация устройства",
      docsCatAccuracy: "Документы по валидации точности",
      docViewPdf: "Открыть PDF",
      docPending: "Ожидает проверки",
      docNotAvailable: "Недоступно",
      docsLoadError: "Не удалось загрузить список документов.",
      swDiscTitle: "Важное медицинское уведомление",
      swDisc1:
        "TamyrFlow предназначен только для фитнеса и общего самочувствия. Это не медицинское изделие и не предоставляет диагнозы, рекомендации по лечению или медицинские советы.",
      swDisc2:
        "Измерения поступают с аппаратного обеспечения совместимых умных часов. Их точность и доступность зависят от подключённого устройства.",
      swDisc3: "Не используйте эти измерения для принятия медицинских решений.",
      swReviewTitle: "Информация для App Review",
      swReview1: "TamyrFlow отображает показатели самочувствия, полученные с совместимых умных часов.",
      swReview2:
        "Приложение самостоятельно не измеряет физиологические параметры и не заявляет о медицинской точности.",
      swReview3: "Сопроводительная документация устройства приведена выше, где она доступна.",
      swReview4: "TamyrFlow предназначен только для фитнеса и общего самочувствия.",
      privacyTitle: "Политика конфиденциальности TamyrFlow",
      privacyMeta: "Дата последнего обновления: 12 ноября 2026 года",
      termsTitle: "Условия использования TamyrFlow",
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
      navSmartwatch: "Smartwatch",
      swPill: "Compatible device",
      swHeroTitle: "ET488 Smartwatch",
      swHeroLead:
        "Compatible smartwatch for activity tracking and general wellness measurements with TamyrFlow.",
      swModelLabel: "Model",
      swConnectLabel: "Connection",
      swConnectValue: "Bluetooth",
      swAppLabel: "App",
      swIntegration:
        "TamyrFlow pairs with a compatible ET488 over Bluetooth, receives supported wellness measurements from the watch hardware, and shows values, trends, and history in the app. Availability of each metric depends on the device hardware and firmware.",
      swPhotoFront: "Front",
      swPhotoSide: "Side",
      swPhotoAngle: "Angle",
      swPhotoBack: "Back",
      swFeaturesTitle: "Supported Features",
      swFeaturesLead:
        "TamyrFlow can display the following wellness and activity data when provided by a compatible ET488. Availability depends on the smartwatch hardware and firmware. These measurements are for general fitness and wellness — not medical-grade claims.",
      swF1: "Heart Rate (Pulse)",
      swF1Body: "Pulse readings received from the connected watch.",
      swF2: "Blood Oxygen (SpO₂)",
      swF2Body: "SpO₂ values when supported by the device.",
      swF3: "Body Temperature",
      swF3Body: "Temperature readings when a sensor is available.",
      swF4: "Blood Pressure",
      swF4Body: "Blood pressure values when supported by firmware.",
      swF5: "Daily Steps",
      swF5Body: "Step count synchronized from the watch.",
      swF6: "Activity Tracking",
      swF6Body: "Activity progress and related fitness data in the app.",
      swF7: "Measurement History",
      swF7Body: "Past readings, charts, and trends in TamyrFlow.",
      swF8: "Bluetooth Synchronization",
      swF8Body: "Pairing and data sync over Bluetooth.",
      swHowTitle: "How It Works",
      swHowLead:
        "A simple flow from install to viewing wellness data. Some TamyrFlow screens remain available without a connected watch; live measurements require a paired compatible device.",
      swStep1Title: "Install TamyrFlow",
      swStep1Body: "Download the iOS app and create or sign in to your account.",
      swStep2Title: "Connect ET488 via Bluetooth",
      swStep2Body:
        "Pair a compatible ET488 smartwatch. Location permission may be requested only to help find nearby Bluetooth devices.",
      swStep3Title: "Start a supported measurement",
      swStep3Body: "Use the smartwatch to run a supported wellness measurement.",
      swStep4Title: "View data in TamyrFlow",
      swStep4Body: "Review received values, trends, and history in the app.",
      swDocsTitle: "Device Documentation",
      swDocsLead:
        "Supporting documents for the ET488. PDFs open at public URLs when a verified file is available. Documents pending verification are labeled accordingly — no fabricated certificates or unverified “Verified” badges.",
      docsCatDevice: "Device documentation",
      docsCatAccuracy: "Accuracy Validation Documents",
      docViewPdf: "View PDF",
      docPending: "Pending verification",
      docNotAvailable: "Not available",
      docsLoadError: "Could not load the document list.",
      swDiscTitle: "Important Medical Disclaimer",
      swDisc1:
        "TamyrFlow is intended for general fitness and wellness purposes only. It is not a medical device and does not provide medical diagnoses, treatment recommendations, or medical advice.",
      swDisc2:
        "Measurements are provided by compatible smartwatch hardware. Their accuracy and availability depend on the connected device.",
      swDisc3: "Do not use these measurements to make medical decisions.",
      swReviewTitle: "Information for App Review",
      swReview1: "TamyrFlow displays wellness measurements received from compatible smartwatches.",
      swReview2:
        "The application does not independently measure physiological parameters or claim medical-grade accuracy.",
      swReview3: "Supporting device documentation is provided above where available.",
      swReview4: "TamyrFlow is intended for fitness and general wellness use only.",
      privacyTitle: "TamyrFlow Privacy Policy",
      privacyMeta: "Last updated: November 12, 2026",
      termsTitle: "TamyrFlow Terms of Use",
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
      navSmartwatch: "Сағат",
      swPill: "Үйлесімді құрылғы",
      swHeroTitle: "ET488 Smartwatch",
      swHeroLead:
        "TamyrFlow-пен белсенділікті және жалпы әл-ауқат өлшемдерін қадағалауға арналған үйлесімді смарт сағат.",
      swModelLabel: "Модель",
      swConnectLabel: "Қосылым",
      swConnectValue: "Bluetooth",
      swAppLabel: "Қолданба",
      swIntegration:
        "TamyrFlow үйлесімді ET488-пен Bluetooth арқылы жұптасады, сағат аппараттығынан қолдау көрсетілетін әл-ауқат өлшемдерін алады және қолданбада мәндерді, үрдістер мен тарихты көрсетеді. Әр метриканың қолжетімділігі құрылғы аппараттығы мен прошивкасына байланысты.",
      swPhotoFront: "Алдынан",
      swPhotoSide: "Қапталынан",
      swPhotoAngle: "Бұрыш",
      swPhotoBack: "Артынан",
      swFeaturesTitle: "Қолдау көрсетілетін мүмкіндіктер",
      swFeaturesLead:
        "TamyrFlow үйлесімді ET488 ұсынған кезде келесі әл-ауқат және белсенділік деректерін көрсете алады. Қолжетімділік сағат аппараттығы мен прошивкасына байланысты. Бұл өлшемдер жалпы фитнес пен әл-ауқат үшін — медициналық дәлдік туралы мәлімдеме жоқ.",
      swF1: "Жүрек соғысы (Pulse)",
      swF1Body: "Қосылған сағаттан алынған пульс көрсеткіштері.",
      swF2: "Қандағы оттегі (SpO₂)",
      swF2Body: "Құрылғы қолдаса SpO₂ мәндері.",
      swF3: "Дене температурасы",
      swF3Body: "Сенсор болса температура көрсеткіштері.",
      swF4: "Қан қысымы",
      swF4Body: "Прошивка қолдаса қан қысымы мәндері.",
      swF5: "Күнделікті қадам",
      swF5Body: "Сағаттан синхрондалған қадам саны.",
      swF6: "Белсенділікті қадағалау",
      swF6Body: "Қолданбадағы белсенділік прогресі және фитнес деректері.",
      swF7: "Өлшеулер тарихы",
      swF7Body: "TamyrFlow-дағы өткен көрсеткіштер, графиктер және үрдістер.",
      swF8: "Bluetooth синхрондау",
      swF8Body: "Bluetooth арқылы жұптау және деректерді синхрондау.",
      swHowTitle: "Қалай жұмыс істейді",
      swHowLead:
        "Орнатудан әл-ауқат деректерін көруге дейінгі қарапайым ағын. Кейбір TamyrFlow экрандары сағатсыз да қолжетімді; тірі өлшемдер үшін жұпталған үйлесімді құрылғы қажет.",
      swStep1Title: "TamyrFlow орнатыңыз",
      swStep1Body: "iOS қолданбасын жүктеп, аккаунт жасаңыз немесе кіріңіз.",
      swStep2Title: "ET488-ті Bluetooth арқылы қосыңыз",
      swStep2Body:
        "Үйлесімді ET488 смарт сағатын жұптаңыз. Геолокация рұқсаты тек жақын Bluetooth құрылғыларын табу үшін сұралуы мүмкін.",
      swStep3Title: "Қолдау көрсетілетін өлшеуді бастаңыз",
      swStep3Body: "Қолдау көрсетілетін әл-ауқат өлшеуін смарт сағат арқылы орындаңыз.",
      swStep4Title: "Деректерді TamyrFlow-да қараңыз",
      swStep4Body: "Алынған мәндерді, үрдістер мен тарихты қолданбада қараңыз.",
      swDocsTitle: "Құрылғы құжаттамасы",
      swDocsLead:
        "ET488 үшін қосымша құжаттар. Тексерілген файл қолжетімді болса PDF жария URL арқылы ашылады. Тексеру күтіп тұрған құжаттар тиісінше белгіленеді — ойдан шығарылған сертификаттар мен расталмаған “Verified” белгілері жоқ.",
      docsCatDevice: "Құрылғы құжаттамасы",
      docsCatAccuracy: "Дәлдікті тексеру құжаттары",
      docViewPdf: "PDF ашу",
      docPending: "Тексеру күтілуде",
      docNotAvailable: "Қолжетімсіз",
      docsLoadError: "Құжаттар тізімін жүктеу мүмкін болмады.",
      swDiscTitle: "Маңызды медициналық ескерту",
      swDisc1:
        "TamyrFlow тек жалпы фитнес пен әл-ауқат мақсаттарына арналған. Бұл медициналық құрылғы емес және диагноз, ем ұсынысы немесе медициналық кеңес бермейді.",
      swDisc2:
        "Өлшемдерді үйлесімді смарт сағат аппараттығы ұсынады. Олардың дәлдігі мен қолжетімділігі қосылған құрылғыға байланысты.",
      swDisc3: "Бұл өлшемдерді медициналық шешім қабылдау үшін пайдаланбаңыз.",
      swReviewTitle: "App Review ақпараты",
      swReview1: "TamyrFlow үйлесімді смарт сағаттардан алынған әл-ауқат өлшемдерін көрсетеді.",
      swReview2:
        "Қолданба физиологиялық параметрлерді өз бетінше өлшемейді және медициналық дәлдікке үміттенбейді.",
      swReview3: "Қолдау құжаттамасы жоғарыда, қолжетімді болғанда берілген.",
      swReview4: "TamyrFlow тек фитнес пен жалпы әл-ауқатқа арналған.",
      privacyTitle: "TamyrFlow құпиялылық саясаты",
      privacyMeta: "Соңғы жаңарту: 12 қараша 2026 жыл",
      termsTitle: "TamyrFlow пайдалану шарттары",
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

  function setLang(lang, options = {}) {
    const persist = options.persist !== false;
    if (!copy[lang]) lang = "ru";
    if (persist) localStorage.setItem(STORAGE_KEY, lang);
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
    if (document.getElementById("device-docs-root")) renderDeviceDocs(lang);
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

  let legalRenderToken = 0;
  let deviceDocsRenderToken = 0;

  async function fetchJson(url, timeoutMs = 8000) {
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), timeoutMs);
    try {
      const res = await fetch(url, { cache: "no-store", signal: ctrl.signal });
      if (!res.ok) throw new Error("fetch failed");
      return await res.json();
    } finally {
      clearTimeout(timer);
    }
  }

  async function renderLegal(docKey, lang) {
    const host = document.getElementById("legal-root");
    if (!host) return;
    const token = ++legalRenderToken;
    const t = copy[lang] || copy.ru;
    setStatusMessage(host, t.loadingLegal);
    try {
      const data = await fetchJson("./legal-data.json");
      if (token !== legalRenderToken) return;
      const activeLang = document.documentElement.lang || lang;
      const sections =
        data[docKey]?.[activeLang] || data[docKey]?.[lang] || data[docKey]?.ru || [];
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
      if (token !== legalRenderToken) return;
      const active = copy[document.documentElement.lang] || t;
      setStatusMessage(host, active.legalError);
    }
  }

  function categoryTitle(id, t) {
    if (id === "device") return t.docsCatDevice || "Device documentation";
    if (id === "accuracy") return t.docsCatAccuracy || "Accuracy Validation Documents";
    return id;
  }

  function statusLabel(status, t) {
    if (status === "available") return t.docViewPdf || "View PDF";
    if (status === "pending") return t.docPending || "Pending verification";
    return t.docNotAvailable || "Not available";
  }

  function localizedDocFields(doc, lang) {
    const pack = doc?.i18n?.[lang] || doc?.i18n?.en || {};
    return {
      title: String(pack.title || doc.title || ""),
      type: String(pack.type || doc.type || ""),
      description: String(pack.description || doc.description || ""),
    };
  }

  async function renderDeviceDocs(lang) {
    const host = document.getElementById("device-docs-root");
    if (!host) return;
    const token = ++deviceDocsRenderToken;
    const t = copy[lang] || copy.en;
    setStatusMessage(host, t.loadingLegal || "Loading…");
    try {
      const data = await fetchJson("./device-docs.json");
      if (token !== deviceDocsRenderToken) return;
      const activeLang = document.documentElement.lang || lang;
      const activeCopy = copy[activeLang] || t;
      while (host.firstChild) host.removeChild(host.firstChild);

      for (const category of data.categories || []) {
        const block = document.createElement("section");
        block.className = "sw-docs-category";
        const h3 = document.createElement("h3");
        h3.textContent = categoryTitle(category.id, activeCopy);
        block.appendChild(h3);

        const grid = document.createElement("div");
        grid.className = "sw-docs-grid";

        for (const doc of category.documents || []) {
          const fields = localizedDocFields(doc, activeLang);
          const card = document.createElement("article");
          card.className = "sw-doc-card";

          const type = document.createElement("p");
          type.className = "sw-doc-type";
          type.textContent = fields.type;
          card.appendChild(type);

          const title = document.createElement("h4");
          title.textContent = fields.title;
          card.appendChild(title);

          const desc = document.createElement("p");
          desc.className = "sw-doc-desc";
          desc.textContent = fields.description;
          card.appendChild(desc);

          const status = String(doc.status || "not_available");
          if (status === "available" && doc.file) {
            const link = document.createElement("a");
            link.className = "btn btn-outline btn-sm";
            link.href = `./${String(doc.file).replace(/^\.\//, "")}`;
            link.target = "_blank";
            link.rel = "noopener";
            link.textContent = statusLabel(status, activeCopy);
            card.appendChild(link);
          } else {
            const badge = document.createElement("span");
            badge.className = `sw-doc-status is-${status === "pending" ? "pending" : "na"}`;
            badge.textContent = statusLabel(status, activeCopy);
            card.appendChild(badge);
          }

          grid.appendChild(card);
        }

        block.appendChild(grid);
        host.appendChild(block);
      }
    } catch {
      if (token !== deviceDocsRenderToken) return;
      const active = copy[document.documentElement.lang] || t;
      setStatusMessage(host, active.docsLoadError || active.legalError);
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
    const saved = localStorage.getItem(STORAGE_KEY);
    const hasSaved = saved === "ru" || saved === "en" || saved === "kk";
    const onSmartwatch = Boolean(document.getElementById("device-docs-root"));
    if (hasSaved) {
      setLang(saved);
    } else if (onSmartwatch) {
      // English-primary for App Review UI, without overwriting browser preference.
      setLang("en", { persist: false });
    } else {
      setLang(getLang());
    }
    initScrollReveals();
    initHeaderScroll();
  });
})();

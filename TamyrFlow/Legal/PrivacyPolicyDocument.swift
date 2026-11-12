import Foundation

/// Structured privacy policy — rendered as a readable scrolling document.
enum PrivacyPolicyDocument {
    typealias Section = LegalRichDocument.Section
    typealias Block = LegalRichDocument.Block

    static var updatedLabel: String {
        switch LanguageStoreBootstrap.bundle.preferredLocalizations.first {
        case "en": return "Last updated: November 12, 2026"
        case "kk": return "Соңғы жаңарту: 12 қараша 2026 жыл"
        default: return "Дата последнего обновления: 12 ноября 2026 года"
        }
    }

    static var documentTitle: String {
        switch LanguageStoreBootstrap.bundle.preferredLocalizations.first {
        case "en": return "TamyrFlow Privacy Policy"
        case "kk": return "TamyrFlow құпиялылық саясаты"
        default: return "Политика конфиденциальности TamyrFlow"
        }
    }

    static var sections: [Section] {
        switch LanguageStoreBootstrap.bundle.preferredLocalizations.first {
        case "en": return english
        case "kk": return kazakh
        default: return russian
        }
    }

    // MARK: - Russian (canonical)

    private static let russian: [Section] = [
        Section(id: "1", title: "1. Общие положения", blocks: [
            .paragraph("TamyrFlow — мобильное приложение для фитнеса и отслеживания физической активности, которое помогает пользователям просматривать показатели здоровья и самочувствия, получаемые с совместимых умных часов и из Apple Health, отслеживать изменения показателей и управлять персональными целями."),
            .paragraph("Настоящая Политика конфиденциальности объясняет, какие данные мы собираем, как используем, храним и защищаем их, а также какие права имеют пользователи."),
            .paragraph("Приложение предназначено для распространения на территории Республики Казахстан."),
            .paragraph("Обработка персональных данных осуществляется в соответствии с законодательством Республики Казахстан и на основании необходимых согласий пользователя.")
        ]),
        Section(id: "2", title: "2. Какие данные мы собираем", blocks: [
            .paragraph("Мы можем собирать и обрабатывать следующие категории данных."),
            .paragraph("Персональная информация"),
            .bullets([
                "имя пользователя;",
                "адрес электронной почты или номер телефона, используемый для регистрации;",
                "пол и возраст;",
                "рост и вес;",
                "фотография профиля, если добавлена пользователем;",
                "настройки профиля и персональные цели."
            ]),
            .paragraph("Данные о здоровье и физической активности"),
            .paragraph("Приложение может обрабатывать:"),
            .bullets([
                "количество шагов;",
                "частоту сердечных сокращений (пульс);",
                "уровень кислорода в крови (SpO₂);",
                "артериальное давление;",
                "температуру, измеряемую совместимым устройством;",
                "расход калорий;",
                "показатели физической активности;",
                "историю измерений."
            ]),
            .paragraph("Данные могут поступать:"),
            .bullets([
                "с совместимых умных часов через Bluetooth;",
                "из Apple Health с разрешения пользователя;",
                "из информации, самостоятельно введённой пользователем."
            ]),
            .paragraph("Доступность отдельных показателей зависит от возможностей подключённого устройства и предоставленных разрешений."),
            .paragraph("Технические данные"),
            .paragraph("При использовании приложения могут обрабатываться:"),
            .bullets([
                "модель устройства;",
                "версия операционной системы;",
                "версия приложения;",
                "язык устройства;",
                "IP-адрес при взаимодействии с облачными сервисами;",
                "технические сведения о Bluetooth-соединении;",
                "диагностическая информация, необходимая для выявления ошибок."
            ])
        ]),
        Section(id: "3", title: "3. Как мы используем данные", blocks: [
            .paragraph("Мы используем данные для:"),
            .bullets([
                "регистрации и обслуживания аккаунта;",
                "предоставления функций приложения;",
                "подключения и синхронизации умных часов;",
                "отображения показателей здоровья и активности;",
                "сохранения истории измерений;",
                "построения графиков и статистики;",
                "отслеживания персональных целей;",
                "синхронизации данных с облачным хранилищем;",
                "обеспечения безопасности аккаунта;",
                "устранения технических ошибок;",
                "улучшения стабильности и удобства приложения."
            ]),
            .paragraph("Мы не продаём персональные данные пользователей третьим лицам."),
            .paragraph("Данные о здоровье и активности не используются для рекламного таргетинга, продажи рекламодателям или брокерам данных.")
        ]),
        Section(id: "4", title: "4. Bluetooth и подключённые устройства", blocks: [
            .paragraph("TamyrFlow использует Bluetooth для обнаружения, подключения и синхронизации совместимых умных часов."),
            .paragraph("Приложение получает готовые показатели измерений, сформированные подключённым устройством."),
            .paragraph("TamyrFlow не использует датчики iPhone для самостоятельного измерения артериального давления, кислорода в крови или температуры тела."),
            .paragraph("Пользователь самостоятельно предоставляет разрешение на использование Bluetooth и может отозвать его в настройках iOS."),
            .paragraph("При отключении разрешения функции синхронизации часов могут быть недоступны.")
        ]),
        Section(id: "5", title: "5. Apple Health и HealthKit", blocks: [
            .paragraph("TamyrFlow может получать данные из Apple Health с использованием HealthKit исключительно после предоставления разрешения пользователем."),
            .paragraph("Приложение использует доступ к Apple Health только для чтения поддерживаемых показателей."),
            .paragraph("TamyrFlow не записывает и не изменяет данные в Apple Health."),
            .paragraph("Полученные данные используются для отображения показателей здоровья, физической активности, статистики и истории."),
            .paragraph("Данные Apple Health не используются для рекламы, маркетингового профилирования или продажи третьим лицам."),
            .paragraph("Передача данных Apple Health в облачное хранилище, если такая функция реализована, допускается только при наличии необходимых разрешений и с соблюдением требований Apple и применимого законодательства."),
            .paragraph("Пользователь может изменить или отозвать доступ через настройки Apple Health или iOS.")
        ]),
        Section(id: "6", title: "6. Хранение и безопасность данных", blocks: [
            .paragraph("TamyrFlow использует облачную инфраструктуру для хранения данных аккаунта, пользовательских настроек и поддерживаемых данных приложения."),
            .paragraph("Мы применяем технические и организационные меры для защиты персональных данных, включая:"),
            .bullets([
                "защищённую передачу информации;",
                "механизмы аутентификации;",
                "ограничение доступа к персональным данным;",
                "контроль доступа к облачному хранилищу;",
                "меры предотвращения несанкционированного доступа."
            ]),
            .paragraph("Данные хранятся в течение периода, необходимого для предоставления функций приложения, выполнения законных обязательств и обработки запросов пользователя."),
            .paragraph("После прекращения использования сервиса пользователь может запросить удаление своих персональных данных."),
            .paragraph("Отдельные сведения могут сохраняться, если это требуется применимым законодательством."),
            .paragraph("Ни одна система хранения и передачи информации не может гарантировать абсолютную безопасность.")
        ]),
        Section(id: "7", title: "7. Передача данных третьим сторонам", blocks: [
            .paragraph("TamyrFlow может использовать сторонние сервисы для хранения данных пользователей, обеспечения работы приложения и технической поддержки."),
            .paragraph("Передача информации осуществляется исключительно в целях предоставления функций приложения и обеспечения его стабильной работы."),
            .paragraph("Мы не продаём персональные данные пользователей третьим лицам."),
            .paragraph("Данные о здоровье и физической активности не передаются рекламным компаниям и не используются для рекламного таргетинга."),
            .paragraph("При использовании сторонних сервисов мы принимаем необходимые меры для защиты персональных данных пользователей.")
        ]),
        Section(id: "8", title: "8. Права пользователя", blocks: [
            .paragraph("Пользователь имеет право в соответствии с применимым законодательством:"),
            .bullets([
                "получать информацию об обработке персональных данных;",
                "запрашивать доступ к своим данным;",
                "исправлять неточную информацию;",
                "отзывать согласие на обработку данных в предусмотренных законом случаях;",
                "запрашивать удаление аккаунта и связанных персональных данных;",
                "управлять разрешениями Bluetooth и Apple Health;",
                "обращаться с вопросами о конфиденциальности."
            ]),
            .paragraph("Для реализации своих прав пользователь может воспользоваться функциями приложения или обратиться в службу поддержки.")
        ]),
        Section(id: "9", title: "9. Удаление аккаунта", blocks: [
            .paragraph("Пользователь может инициировать удаление аккаунта непосредственно в приложении TamyrFlow."),
            .paragraph("После подтверждения удаления аккаунта связанные с ним персональные данные удаляются в соответствии с установленными сроками хранения и требованиями законодательства."),
            .paragraph("Информация, которую необходимо сохранять по законным основаниям, может храниться в течение предусмотренного законом периода."),
            .paragraph("Удаление приложения с iPhone не означает автоматического удаления аккаунта и данных, сохранённых в облаке."),
            .paragraph("Для получения помощи с удалением аккаунта пользователь может обратиться в службу поддержки.")
        ]),
        Section(id: "10", title: "10. Медицинский дисклеймер", blocks: [
            .paragraph("TamyrFlow предназначен для отслеживания физической активности, общего самочувствия и отображения данных совместимых устройств."),
            .paragraph("Приложение не предназначено для самостоятельной диагностики заболеваний, назначения лечения или замены консультации медицинского специалиста."),
            .paragraph("Показатели пульса, артериального давления, кислорода в крови и температуры поступают с подключённых устройств или из разрешённых пользователем источников."),
            .paragraph("Точность показателей зависит от характеристик устройства, условий измерения и правильности его использования."),
            .paragraph("Отображаемая информация носит информационный и фитнес-характер."),
            .paragraph("Пользователям не следует использовать данные приложения как единственное основание для принятия медицинских решений."),
            .paragraph("При возникновении вопросов о состоянии здоровья рекомендуется обратиться к квалифицированному медицинскому специалисту.")
        ]),
        Section(id: "11", title: "11. Разрешения iOS", blocks: [
            .paragraph("Для работы отдельных функций TamyrFlow может запрашивать следующие разрешения."),
            .paragraph("Bluetooth"),
            .paragraph("Используется для подключения совместимых умных часов и получения показателей измерений."),
            .paragraph("Apple Health"),
            .paragraph("Используется для чтения разрешённых пользователем показателей здоровья и физической активности."),
            .paragraph("Уведомления"),
            .paragraph("Могут использоваться для напоминаний об активности и служебных сообщений, если соответствующая функция доступна и пользователь разрешил уведомления."),
            .paragraph("Фотографии"),
            .paragraph("Могут использоваться для выбора фотографии профиля, если пользователь самостоятельно использует эту функцию."),
            .paragraph("Все разрешения предоставляются пользователем через системные механизмы iOS."),
            .paragraph("Пользователь может изменить или отозвать разрешения в настройках устройства.")
        ]),
        Section(id: "12", title: "12. Изменения политики", blocks: [
            .paragraph("Мы можем периодически обновлять настоящую Политику конфиденциальности в связи с изменением функций приложения, способов обработки данных или требований законодательства."),
            .paragraph("При существенных изменениях пользователи будут уведомлены доступными средствами."),
            .paragraph("Актуальная версия Политики конфиденциальности публикуется на официальной странице TamyrFlow.")
        ]),
        Section(id: "13", title: "13. Контакты", blocks: [
            .paragraph("Если у вас есть вопросы о конфиденциальности, обработке или удалении персональных данных, вы можете связаться с нами."),
            .contact(label: "Приложение", value: "TamyrFlow"),
            .contact(label: "Email", value: "tamyrflow@gmail.com"),
            .contact(label: "Телефон", value: "+7 706 690 55 06"),
            .contact(label: "Страна", value: "Республика Казахстан")
        ])
    ]

    // MARK: - English

    private static let english: [Section] = [
        Section(id: "1", title: "1. General", blocks: [
            .paragraph("TamyrFlow is a fitness and activity-tracking mobile app that helps users view wellness metrics from compatible smartwatches and Apple Health, track changes over time, and manage personal goals."),
            .paragraph("This Privacy Policy explains what data we collect, how we use, store, and protect it, and what rights users have."),
            .paragraph("The app is intended for distribution in the Republic of Kazakhstan."),
            .paragraph("Personal data is processed in accordance with the laws of the Republic of Kazakhstan and based on the user’s required consents.")
        ]),
        Section(id: "2", title: "2. Data we collect", blocks: [
            .paragraph("We may collect and process the following categories of data."),
            .paragraph("Personal information"),
            .bullets([
                "display name;",
                "email address or phone number used for registration;",
                "sex and age;",
                "height and weight;",
                "profile photo, if you add one;",
                "profile settings and personal goals."
            ]),
            .paragraph("Health and activity data"),
            .paragraph("The app may process:"),
            .bullets([
                "step count;",
                "heart rate;",
                "blood oxygen (SpO₂);",
                "blood pressure;",
                "temperature measured by a compatible device;",
                "calories burned;",
                "physical activity metrics;",
                "measurement history."
            ]),
            .paragraph("Data may come from:"),
            .bullets([
                "compatible smartwatches via Bluetooth;",
                "Apple Health with your permission;",
                "information you enter yourself."
            ]),
            .paragraph("Availability of metrics depends on the connected device and the permissions you grant."),
            .paragraph("Technical data"),
            .paragraph("When you use the app we may process:"),
            .bullets([
                "device model;",
                "OS version;",
                "app version;",
                "device language;",
                "IP address when contacting cloud services;",
                "technical Bluetooth connection details;",
                "diagnostic information needed to find errors."
            ])
        ]),
        Section(id: "3", title: "3. How we use data", blocks: [
            .paragraph("We use data to:"),
            .bullets([
                "register and maintain your account;",
                "provide app features;",
                "connect and sync smartwatches;",
                "display health and activity metrics;",
                "store measurement history;",
                "build charts and statistics;",
                "track personal goals;",
                "sync data with cloud storage;",
                "keep the account secure;",
                "fix technical issues;",
                "improve stability and usability."
            ]),
            .paragraph("We do not sell users’ personal data to third parties."),
            .paragraph("Health and activity data are not used for ad targeting, sold to advertisers, or sold to data brokers.")
        ]),
        Section(id: "4", title: "4. Bluetooth and connected devices", blocks: [
            .paragraph("TamyrFlow uses Bluetooth to discover, connect, and sync compatible smartwatches."),
            .paragraph("The app receives measurement values produced by the connected device."),
            .paragraph("TamyrFlow does not use iPhone sensors to independently measure blood pressure, blood oxygen, or body temperature."),
            .paragraph("You grant Bluetooth permission yourself and can revoke it in iOS Settings."),
            .paragraph("If permission is turned off, watch sync features may be unavailable.")
        ]),
        Section(id: "5", title: "5. Apple Health and HealthKit", blocks: [
            .paragraph("TamyrFlow may read Apple Health data via HealthKit only after you grant permission."),
            .paragraph("Access is read-only for supported metrics."),
            .paragraph("TamyrFlow does not write or change data in Apple Health."),
            .paragraph("Retrieved data is used to show health and activity metrics, statistics, and history."),
            .paragraph("Apple Health data is not used for advertising, marketing profiles, or sale to third parties."),
            .paragraph("If cloud sync of Apple Health–sourced data is enabled, it happens only with the required permissions and in line with Apple rules and applicable law."),
            .paragraph("You can change or revoke access in Apple Health or iOS Settings.")
        ]),
        Section(id: "6", title: "6. Storage and security", blocks: [
            .paragraph("TamyrFlow uses cloud infrastructure to store account data, settings, and supported app data."),
            .paragraph("We apply technical and organizational measures to protect personal data, including:"),
            .bullets([
                "encrypted transport;",
                "authentication controls;",
                "limited access to personal data;",
                "cloud access controls;",
                "measures against unauthorized access."
            ]),
            .paragraph("Data is kept for as long as needed to provide the service, meet legal duties, and handle user requests."),
            .paragraph("After you stop using the service you may request deletion of your personal data."),
            .paragraph("Some records may be retained when required by law."),
            .paragraph("No storage or transmission system can guarantee absolute security.")
        ]),
        Section(id: "7", title: "7. Sharing with third parties", blocks: [
            .paragraph("TamyrFlow may use third-party services for storage, app operation, and technical support."),
            .paragraph("Sharing happens only to provide app features and keep the service reliable."),
            .paragraph("We do not sell personal data to third parties."),
            .paragraph("Health and activity data are not shared with advertising companies and are not used for ad targeting."),
            .paragraph("When we use third-party services we take appropriate steps to protect personal data.")
        ]),
        Section(id: "8", title: "8. Your rights", blocks: [
            .paragraph("Subject to applicable law, you may:"),
            .bullets([
                "receive information about processing of your personal data;",
                "request access to your data;",
                "correct inaccurate information;",
                "withdraw consent where the law allows;",
                "request deletion of your account and related personal data;",
                "manage Bluetooth and Apple Health permissions;",
                "contact us about privacy questions."
            ]),
            .paragraph("You can use in-app features or contact support to exercise these rights.")
        ]),
        Section(id: "9", title: "9. Account deletion", blocks: [
            .paragraph("You can start account deletion directly in TamyrFlow."),
            .paragraph("After you confirm deletion, related personal data is removed according to retention rules and the law."),
            .paragraph("Information that must be kept for legal reasons may remain for the required period."),
            .paragraph("Deleting the app from an iPhone does not automatically delete your cloud account and data."),
            .paragraph("Contact support if you need help deleting your account.")
        ]),
        Section(id: "10", title: "10. Medical disclaimer", blocks: [
            .paragraph("TamyrFlow is for tracking physical activity, general wellness, and displaying data from compatible devices."),
            .paragraph("It is not intended for self-diagnosis, treatment, or replacing advice from a medical professional."),
            .paragraph("Heart rate, blood pressure, blood oxygen, and temperature come from connected devices or sources you authorize."),
            .paragraph("Accuracy depends on the device, measurement conditions, and correct use."),
            .paragraph("Displayed information is informational and fitness-oriented."),
            .paragraph("Do not rely on the app alone for medical decisions."),
            .paragraph("If you have health concerns, consult a qualified medical professional.")
        ]),
        Section(id: "11", title: "11. iOS permissions", blocks: [
            .paragraph("Some features may request these permissions."),
            .paragraph("Bluetooth"),
            .paragraph("Used to connect compatible smartwatches and receive measurements."),
            .paragraph("Apple Health"),
            .paragraph("Used to read health and activity metrics you allow."),
            .paragraph("Notifications"),
            .paragraph("May be used for activity reminders and service messages if available and allowed."),
            .paragraph("Photos"),
            .paragraph("May be used to choose a profile photo if you use that feature."),
            .paragraph("All permissions are granted through iOS system prompts."),
            .paragraph("You can change or revoke them in device Settings.")
        ]),
        Section(id: "12", title: "12. Policy changes", blocks: [
            .paragraph("We may update this Privacy Policy when features, processing practices, or legal requirements change."),
            .paragraph("For material changes we will notify users by available means."),
            .paragraph("The current version is published on the official TamyrFlow page.")
        ]),
        Section(id: "13", title: "13. Contact", blocks: [
            .paragraph("If you have questions about privacy, processing, or deletion of personal data, contact us."),
            .contact(label: "App", value: "TamyrFlow"),
            .contact(label: "Email", value: "tamyrflow@gmail.com"),
            .contact(label: "Phone", value: "+7 706 690 55 06"),
            .contact(label: "Country", value: "Republic of Kazakhstan")
        ])
    ]

    // MARK: - Kazakh (summary aligned with RU canonical text)

    private static let kazakh: [Section] = [
        Section(id: "1", title: "1. Жалпы ережелер", blocks: [
            .paragraph("TamyrFlow — үйлесімді смарт-сағаттар мен Apple Health деректерінен денсаулық пен белсенділік көрсеткіштерін қарауға, өзгерістерді бақылауға және жеке мақсаттарды басқаруға арналған фитнес қолданбасы."),
            .paragraph("Осы Құпиялылық саясаты қандай деректерді жинайтынымызды, қалай пайдаланатынымызды, сақтайтынымызды және қорғайтынымызды, сондай-ақ пайдаланушы құқықтарын түсіндіреді."),
            .paragraph("Қолданба Қазақстан Республикасы аумағында таратуға арналған."),
            .paragraph("Жеке деректер Қазақстан Республикасының заңнамасына және пайдаланушының қажетті келісімдеріне сәйкес өңделеді.")
        ]),
        Section(id: "2", title: "2. Қандай деректерді жинаймыз", blocks: [
            .paragraph("Біз келесі санаттағы деректерді жинай және өңдей аламыз."),
            .paragraph("Жеке ақпарат"),
            .bullets([
                "пайдаланушы аты;",
                "тіркеуге қолданылатын email немесе телефон;",
                "жынысы мен жасы;",
                "бойы мен салмағы;",
                "профиль фотосы (қосылса);",
                "профиль баптаулары мен жеке мақсаттар."
            ]),
            .paragraph("Денсаулық пен белсенділік деректері"),
            .bullets([
                "қадам саны;",
                "жүрек соғысы (пульс);",
                "қандағы оттегі (SpO₂);",
                "қан қысымы;",
                "құрылғымен өлшенген температура;",
                "калория шығыны;",
                "белсенділік көрсеткіштері;",
                "өлшеу тарихы."
            ]),
            .paragraph("Деректер Bluetooth арқылы сағаттан, пайдаланушы рұқсатымен Apple Health-тан немесе қолмен енгізілген ақпараттан келуі мүмкін.")
        ]),
        Section(id: "3", title: "3. Деректерді қалай қолданамыз", blocks: [
            .paragraph("Деректер аккаунтты жүргізу, қолданба функцияларын ұсыну, сағатты синхрондау, көрсеткіштерді көрсету, тарих пен статистиканы сақтау, мақсаттарды бақылау, бұлттық синхрондау, қауіпсіздік және қателерді түзету үшін қолданылады."),
            .paragraph("Біз жеке деректерді үшінші тұлғаларға сатпаймыз."),
            .paragraph("Денсаулық пен белсенділік деректері жарнамалық таргеттеуге қолданылмайды.")
        ]),
        Section(id: "4", title: "4. Bluetooth және құрылғылар", blocks: [
            .paragraph("TamyrFlow үйлесімді сағаттарды табу, қосу және синхрондау үшін Bluetooth пайдаланады."),
            .paragraph("Қолданба құрылғы қалыптастырған дайын өлшемдерді алады және iPhone сенсорларымен қысым/SpO₂/температураны өз бетінше өлшемейді."),
            .paragraph("Bluetooth рұқсатын пайдаланушы iOS баптауларында басқарады.")
        ]),
        Section(id: "5", title: "5. Apple Health және HealthKit", blocks: [
            .paragraph("TamyrFlow Apple Health деректерін тек пайдаланушы рұқсатынан кейін оқи алады."),
            .paragraph("Қолжетімділік — тек оқу; Apple Health-қа жазу немесе өзгерту жоқ."),
            .paragraph("Бұл деректер жарнамаға немесе үшінші тұлғаларға сатуға қолданылмайды.")
        ]),
        Section(id: "6", title: "6. Сақтау және қауіпсіздік", blocks: [
            .paragraph("Аккаунт пен қолданба деректері бұлттық инфрақұрылымда сақталады."),
            .paragraph("Біз қорғалған байланыс, аутентификация және қолжетімділікті шектеу шараларын қолданамыз."),
            .paragraph("Пайдаланушы жеке деректерін жоюды сұрай алады; заң бойынша қажетті мәліметтер сақталуы мүмкін.")
        ]),
        Section(id: "7", title: "7. Үшінші тараптар", blocks: [
            .paragraph("Сақтау және техникалық қолдау үшін үшінші тарап сервистері қолданылуы мүмкін — тек қолданба жұмысы үшін."),
            .paragraph("Жеке деректер сатылмайды; денсаулық деректері жарнама компанияларына берілмейді.")
        ]),
        Section(id: "8", title: "8. Пайдаланушы құқықтары", blocks: [
            .bullets([
                "өңдеу туралы ақпарат алу;",
                "деректерге қол жеткізу;",
                "дәлсіздікті түзету;",
                "келісімді кері қайтару (заң бойынша);",
                "аккаунт пен деректерді жоюды сұрау;",
                "Bluetooth және Apple Health рұқсаттарын басқару;",
                "құпиялылық бойынша сұрақ қою."
            ])
        ]),
        Section(id: "9", title: "9. Аккаунтты жою", blocks: [
            .paragraph("Аккаунтты TamyrFlow ішінде жоюға болады."),
            .paragraph("iPhone-нан қолданбаны өшіру бұлттағы аккаунтты автоматты жоймайды.")
        ]),
        Section(id: "10", title: "10. Медициналық ескерту", blocks: [
            .paragraph("TamyrFlow фитнес пен жалпы әл-ауқатты бақылауға арналған, диагноз немесе емдеу үшін емес."),
            .paragraph("Көрсеткіштер құрылғылардан келеді; дәлдік құрылғы мен өлшеу жағдайына байланысты."),
            .paragraph("Денсаулық мәселесінде білікті дәрігерге жүгініңіз.")
        ]),
        Section(id: "11", title: "11. iOS рұқсаттары", blocks: [
            .paragraph("Bluetooth — сағатты қосу үшін; Apple Health — рұқсат етілген көрсеткіштерді оқу үшін; хабарламалар мен фото — тиісті функциялар үшін."),
            .paragraph("Рұқсаттарды құрылғы баптауларында өзгертуге болады.")
        ]),
        Section(id: "12", title: "12. Саясат өзгерістері", blocks: [
            .paragraph("Саясат қолданба немесе заң талаптары өзгергенде жаңартылуы мүмкін."),
            .paragraph("Маңызды өзгерістер туралы қолжетімді тәсілдермен хабарлаймыз.")
        ]),
        Section(id: "13", title: "13. Байланыс", blocks: [
            .paragraph("Құпиялылық немесе деректерді жою туралы сұрақтар бойынша бізбен байланысыңыз."),
            .contact(label: "Қолданба", value: "TamyrFlow"),
            .contact(label: "Email", value: "tamyrflow@gmail.com"),
            .contact(label: "Телефон", value: "+7 706 690 55 06"),
            .contact(label: "Ел", value: "Қазақстан Республикасы")
        ])
    ]
}

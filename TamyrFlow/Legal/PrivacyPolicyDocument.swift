import Foundation

/// Structured privacy policy — rendered as a readable scrolling document.
/// Content mirrors landing/legal-data.json (RU/EN/KK).
enum PrivacyPolicyDocument {
    typealias Section = LegalRichDocument.Section
    typealias Block = LegalRichDocument.Block

    static var updatedLabel: String {
        switch LanguageStoreBootstrap.code {
        case AppLanguageCode.en.rawValue: return "Last updated: November 12, 2026"
        case AppLanguageCode.kk.rawValue: return "Соңғы жаңарту: 12 қараша 2026 жыл"
        default: return "Дата последнего обновления: 12 ноября 2026 года"
        }
    }

    static var documentTitle: String {
        switch LanguageStoreBootstrap.code {
        case AppLanguageCode.en.rawValue: return "TamyrFlow Privacy Policy"
        case AppLanguageCode.kk.rawValue: return "TamyrFlow құпиялылық саясаты"
        default: return "Политика конфиденциальности TamyrFlow"
        }
    }

    static var sections: [Section] {
        switch LanguageStoreBootstrap.code {
        case AppLanguageCode.en.rawValue: return english
        case AppLanguageCode.kk.rawValue: return kazakh
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
        Section(id: "1", title: "1. General provisions", blocks: [
            .paragraph("TamyrFlow is a mobile fitness and activity-tracking app that helps users view health and well-being metrics from compatible smartwatches and Apple Health, track changes in those metrics, and manage personal goals."),
            .paragraph("This Privacy Policy explains what data we collect, how we use, store, and protect it, and what rights users have."),
            .paragraph("The app is intended for distribution in the Republic of Kazakhstan."),
            .paragraph("Personal data is processed in accordance with the laws of the Republic of Kazakhstan and on the basis of the user’s necessary consents.")
        ]),
        Section(id: "2", title: "2. What data we collect", blocks: [
            .paragraph("We may collect and process the following categories of data."),
            .paragraph("Personal information"),
            .bullets([
                "user name;",
                "email address or phone number used for registration;",
                "sex and age;",
                "height and weight;",
                "profile photo, if added by the user;",
                "profile settings and personal goals."
            ]),
            .paragraph("Health and physical activity data"),
            .paragraph("The app may process:"),
            .bullets([
                "step count;",
                "heart rate (pulse);",
                "blood oxygen level (SpO₂);",
                "blood pressure;",
                "temperature measured by a compatible device;",
                "calorie expenditure;",
                "physical activity metrics;",
                "measurement history."
            ]),
            .paragraph("Data may come from:"),
            .bullets([
                "compatible smartwatches via Bluetooth;",
                "Apple Health with the user’s permission;",
                "information entered by the user."
            ]),
            .paragraph("Availability of individual metrics depends on the connected device’s capabilities and the permissions granted."),
            .paragraph("Technical data"),
            .paragraph("When using the app, the following may be processed:"),
            .bullets([
                "device model;",
                "operating system version;",
                "app version;",
                "device language;",
                "IP address when interacting with cloud services;",
                "technical information about the Bluetooth connection;",
                "diagnostic information needed to detect errors."
            ])
        ]),
        Section(id: "3", title: "3. How we use data", blocks: [
            .paragraph("We use data to:"),
            .bullets([
                "register and maintain the account;",
                "provide app features;",
                "connect and sync smartwatches;",
                "display health and activity metrics;",
                "store measurement history;",
                "build charts and statistics;",
                "track personal goals;",
                "sync data with cloud storage;",
                "keep the account secure;",
                "fix technical issues;",
                "improve app stability and usability."
            ]),
            .paragraph("We do not sell users’ personal data to third parties."),
            .paragraph("Health and activity data are not used for advertising targeting, sale to advertisers, or data brokers.")
        ]),
        Section(id: "4", title: "4. Bluetooth and connected devices", blocks: [
            .paragraph("TamyrFlow uses Bluetooth to discover, connect to, and sync compatible smartwatches."),
            .paragraph("The app receives ready measurement values produced by the connected device."),
            .paragraph("TamyrFlow does not use iPhone sensors to independently measure blood pressure, blood oxygen, or body temperature."),
            .paragraph("The user grants Bluetooth permission and may revoke it in iOS Settings."),
            .paragraph("If permission is turned off, watch sync features may be unavailable.")
        ]),
        Section(id: "5", title: "5. Apple Health and HealthKit", blocks: [
            .paragraph("TamyrFlow may obtain data from Apple Health using HealthKit only after the user grants permission."),
            .paragraph("The app uses Apple Health access only to read supported metrics."),
            .paragraph("TamyrFlow does not write to or modify data in Apple Health."),
            .paragraph("Obtained data is used to display health metrics, physical activity, statistics, and history."),
            .paragraph("Apple Health data is not used for advertising, marketing profiling, or sale to third parties."),
            .paragraph("Transfer of Apple Health data to cloud storage, if such a feature is implemented, is allowed only with the required permissions and in compliance with Apple requirements and applicable law."),
            .paragraph("The user may change or revoke access in Apple Health or iOS Settings.")
        ]),
        Section(id: "6", title: "6. Storage and security of data", blocks: [
            .paragraph("TamyrFlow uses cloud infrastructure to store account data, user settings, and supported app data."),
            .paragraph("We apply technical and organizational measures to protect personal data, including:"),
            .bullets([
                "secure transmission of information;",
                "authentication mechanisms;",
                "restricted access to personal data;",
                "access control for cloud storage;",
                "measures to prevent unauthorized access."
            ]),
            .paragraph("Data is stored for as long as needed to provide app features, meet legal obligations, and handle user requests."),
            .paragraph("After stopping use of the service, the user may request deletion of their personal data."),
            .paragraph("Certain information may be retained if required by applicable law."),
            .paragraph("No system for storing or transmitting information can guarantee absolute security.")
        ]),
        Section(id: "7", title: "7. Sharing data with third parties", blocks: [
            .paragraph("TamyrFlow may use third-party services for storing user data, operating the app, and providing technical support."),
            .paragraph("Information is shared solely to provide app features and ensure stable operation."),
            .paragraph("We do not sell users’ personal data to third parties."),
            .paragraph("Health and physical activity data are not shared with advertising companies and are not used for advertising targeting."),
            .paragraph("When using third-party services, we take appropriate measures to protect users’ personal data.")
        ]),
        Section(id: "8", title: "8. User rights", blocks: [
            .paragraph("Under applicable law, the user has the right to:"),
            .bullets([
                "receive information about personal data processing;",
                "request access to their data;",
                "correct inaccurate information;",
                "withdraw consent to data processing where provided by law;",
                "request deletion of the account and related personal data;",
                "manage Bluetooth and Apple Health permissions;",
                "contact us with privacy questions."
            ]),
            .paragraph("To exercise these rights, the user may use in-app features or contact support.")
        ]),
        Section(id: "9", title: "9. Account deletion", blocks: [
            .paragraph("The user may initiate account deletion directly in the TamyrFlow app."),
            .paragraph("After account deletion is confirmed, related personal data is deleted in accordance with retention periods and legal requirements."),
            .paragraph("Information that must be retained on legal grounds may be kept for the period required by law."),
            .paragraph("Deleting the app from an iPhone does not automatically delete the account or data stored in the cloud."),
            .paragraph("For help deleting an account, the user may contact support.")
        ]),
        Section(id: "10", title: "10. Medical disclaimer", blocks: [
            .paragraph("TamyrFlow is intended for tracking physical activity, general well-being, and displaying data from compatible devices."),
            .paragraph("The app is not intended for self-diagnosis, prescribing treatment, or replacing consultation with a medical professional."),
            .paragraph("Heart rate, blood pressure, blood oxygen, and temperature metrics come from connected devices or sources authorized by the user."),
            .paragraph("Accuracy depends on device characteristics, measurement conditions, and correct use."),
            .paragraph("Displayed information is informational and fitness-oriented."),
            .paragraph("Users should not rely on app data as the sole basis for medical decisions."),
            .paragraph("If you have questions about your health, consult a qualified medical professional.")
        ]),
        Section(id: "11", title: "11. iOS permissions", blocks: [
            .paragraph("To enable certain features, TamyrFlow may request the following permissions."),
            .paragraph("Bluetooth"),
            .paragraph("Used to connect compatible smartwatches and receive measurement metrics."),
            .paragraph("Apple Health"),
            .paragraph("Used to read health and activity metrics the user has allowed."),
            .paragraph("Notifications"),
            .paragraph("May be used for activity reminders and service messages if the feature is available and the user has allowed notifications."),
            .paragraph("Photos"),
            .paragraph("May be used to choose a profile photo if the user uses this feature."),
            .paragraph("All permissions are granted by the user through iOS system prompts."),
            .paragraph("The user may change or revoke permissions in device settings.")
        ]),
        Section(id: "12", title: "12. Changes to this Policy", blocks: [
            .paragraph("We may periodically update this Privacy Policy due to changes in app features, data processing practices, or legal requirements."),
            .paragraph("For material changes, users will be notified by available means."),
            .paragraph("The current Privacy Policy is published on the official TamyrFlow page.")
        ]),
        Section(id: "13", title: "13. Contact", blocks: [
            .paragraph("If you have questions about privacy, processing, or deletion of personal data, you can contact us."),
            .contact(label: "App", value: "TamyrFlow"),
            .contact(label: "Email", value: "tamyrflow@gmail.com"),
            .contact(label: "Phone", value: "+7 706 690 55 06"),
            .contact(label: "Country", value: "Republic of Kazakhstan")
        ])
    ]

    // MARK: - Kazakh

    private static let kazakh: [Section] = [
        Section(id: "1", title: "1. Жалпы ережелер", blocks: [
            .paragraph("TamyrFlow — үйлесімді смарт сағаттардан және Apple Health-тен алынатын денсаулық пен өзін-өзі сезіну көрсеткіштерін көруге, олардың өзгерістерін бақылауға және жеке мақсаттарды басқаруға көмектесетін фитнес пен физикалық белсенділікті қадағалауға арналған мобильді қолданба."),
            .paragraph("Осы Құпиялылық саясаты біз қандай деректерді жинайтынымызды, оларды қалай пайдаланатынымызды, сақтайтынымызды және қорғайтынымызды, сондай-ақ пайдаланушылардың қандай құқықтары бар екенін түсіндіреді."),
            .paragraph("Қолданба Қазақстан Республикасы аумағында таратуға арналған."),
            .paragraph("Жеке деректер Қазақстан Республикасының заңнамасына сәйкес және пайдаланушының қажетті келісімдері негізінде өңделеді.")
        ]),
        Section(id: "2", title: "2. Қандай деректерді жинаймыз", blocks: [
            .paragraph("Біз келесі санаттағы деректерді жинауы және өңдеуі мүмкін."),
            .paragraph("Жеке ақпарат"),
            .bullets([
                "пайдаланушы аты;",
                "тіркеу үшін пайдаланылатын электрондық пошта мекенжайы немесе телефон нөмірі;",
                "жынысы және жасы;",
                "бойы және салмағы;",
                "пайдаланушы қосқан жағдайда профиль фотосуреті;",
                "профиль параметрлері және жеке мақсаттар."
            ]),
            .paragraph("Денсаулық және физикалық белсенділік деректері"),
            .paragraph("Қолданба келесілерді өңдеуі мүмкін:"),
            .bullets([
                "қадам саны;",
                "жүрек соғу жиілігі (пульс);",
                "қандағы оттегі деңгейі (SpO₂);",
                "артериялық қысым;",
                "үйлесімді құрылғы өлшейтін температура;",
                "калория шығыны;",
                "физикалық белсенділік көрсеткіштері;",
                "өлшеулер тарихы."
            ]),
            .paragraph("Деректер мыналардан түсуі мүмкін:"),
            .bullets([
                "үйлесімді смарт сағаттардан Bluetooth арқылы;",
                "пайдаланушы рұқсатымен Apple Health-тен;",
                "пайдаланушының өзі енгізген ақпараттан."
            ]),
            .paragraph("Жеке көрсеткіштердің қолжетімділігі қосылған құрылғы мүмкіндіктеріне және берілген рұқсаттарға байланысты."),
            .paragraph("Техникалық деректер"),
            .paragraph("Қолданбаны пайдалану кезінде мыналар өңделуі мүмкін:"),
            .bullets([
                "құрылғы моделі;",
                "операциялық жүйе нұсқасы;",
                "қолданба нұсқасы;",
                "құрылғы тілі;",
                "бұлттық сервистермен өзара әрекеттесу кезіндегі IP-мекенжай;",
                "Bluetooth қосылымы туралы техникалық мәліметтер;",
                "қателерді анықтау үшін қажет диагностикалық ақпарат."
            ])
        ]),
        Section(id: "3", title: "3. Деректерді қалай пайдаланамыз", blocks: [
            .paragraph("Біз деректерді мыналар үшін пайдаланамыз:"),
            .bullets([
                "аккаунтты тіркеу және қызмет көрсету;",
                "қолданба функцияларын ұсыну;",
                "смарт сағаттарды қосу және синхрондау;",
                "денсаулық пен белсенділік көрсеткіштерін көрсету;",
                "өлшеулер тарихын сақтау;",
                "графиктер мен статистика құру;",
                "жеке мақсаттарды қадағалау;",
                "деректерді бұлттық сақтау орнымен синхрондау;",
                "аккаунт қауіпсіздігін қамтамасыз ету;",
                "техникалық қателерді жою;",
                "қолданба тұрақтылығы мен ыңғайлылығын жақсарту."
            ]),
            .paragraph("Біз пайдаланушылардың жеке деректерін үшінші тұлғаларға сатпаймыз."),
            .paragraph("Денсаулық пен белсенділік деректері жарнамалық таргетингке, жарнама берушілерге немесе деректер брокерлеріне сатуға пайдаланылмайды.")
        ]),
        Section(id: "4", title: "4. Bluetooth және қосылған құрылғылар", blocks: [
            .paragraph("TamyrFlow үйлесімді смарт сағаттарды табу, қосу және синхрондау үшін Bluetooth пайдаланады."),
            .paragraph("Қолданба қосылған құрылғы қалыптастырған дайын өлшеу көрсеткіштерін алады."),
            .paragraph("TamyrFlow артериялық қысымды, қандағы оттегіні немесе дене температурасын өз бетінше өлшеу үшін iPhone сенсорларын пайдаланбайды."),
            .paragraph("Пайдаланушы Bluetooth пайдалануға рұқсатты өзі береді және оны iOS параметрлерінде қайтарып ала алады."),
            .paragraph("Рұқсат өшірілгенде сағатты синхрондау функциялары қолжетімсіз болуы мүмкін.")
        ]),
        Section(id: "5", title: "5. Apple Health және HealthKit", blocks: [
            .paragraph("TamyrFlow HealthKit арқылы Apple Health деректерін пайдаланушы рұқсат бергеннен кейін ғана алуы мүмкін."),
            .paragraph("Қолданба Apple Health-ке қолжетімділікті тек қолдау көрсетілетін көрсеткіштерді оқу үшін пайдаланады."),
            .paragraph("TamyrFlow Apple Health-тегі деректерді жазбайды және өзгертпейді."),
            .paragraph("Алынған деректер денсаулық, физикалық белсенділік, статистика және тарих көрсеткіштерін көрсету үшін пайдаланылады."),
            .paragraph("Apple Health деректері жарнамаға, маркетингтік профильдеуге немесе үшінші тұлғаларға сатуға пайдаланылмайды."),
            .paragraph("Мұндай функция іске асырылған жағдайда Apple Health деректерін бұлттық сақтау орнына беру тек қажетті рұқсаттар болғанда және Apple талаптары мен қолданыстағы заңнаманы сақтай отырып рұқсат етіледі."),
            .paragraph("Пайдаланушы қолжетімділікті Apple Health немесе iOS параметрлері арқылы өзгерте немесе қайтарып ала алады.")
        ]),
        Section(id: "6", title: "6. Деректерді сақтау және қауіпсіздік", blocks: [
            .paragraph("TamyrFlow аккаунт деректерін, пайдаланушы параметрлерін және қолданбаның қолдау көрсетілетін деректерін сақтау үшін бұлттық инфрақұрылымды пайдаланады."),
            .paragraph("Біз жеке деректерді қорғау үшін техникалық және ұйымдастырушылық шараларды қолданамыз, оның ішінде:"),
            .bullets([
                "ақпаратты қорғалған түрде беру;",
                "аутентификация механизмдері;",
                "жеке деректерге қолжетімділікті шектеу;",
                "бұлттық сақтау орнына қолжетімділікті бақылау;",
                "рұқсатсыз қол жеткізудің алдын алу шаралары."
            ]),
            .paragraph("Деректер қолданба функцияларын ұсыну, заңды міндеттемелерді орындау және пайдаланушы сұрауларын өңдеу үшін қажетті мерзім бойы сақталады."),
            .paragraph("Сервисті пайдалануды тоқтатқаннан кейін пайдаланушы жеке деректерін жоюды сұрай алады."),
            .paragraph("Қолданыстағы заңнама талап етсе, жекелеген мәліметтер сақталуы мүмкін."),
            .paragraph("Ақпаратты сақтау мен берудің ешбір жүйесі абсолютті қауіпсіздікті кепілдей алмайды.")
        ]),
        Section(id: "7", title: "7. Деректерді үшінші тараптарға беру", blocks: [
            .paragraph("TamyrFlow пайдаланушы деректерін сақтау, қолданба жұмысын қамтамасыз ету және техникалық қолдау үшін үшінші тарап сервистерін пайдалануы мүмкін."),
            .paragraph("Ақпарат тек қолданба функцияларын ұсыну және оның тұрақты жұмысын қамтамасыз ету мақсатында беріледі."),
            .paragraph("Біз пайдаланушылардың жеке деректерін үшінші тұлғаларға сатпаймыз."),
            .paragraph("Денсаулық пен физикалық белсенділік деректері жарнамалық компанияларға берілмейді және жарнамалық таргетингке пайдаланылмайды."),
            .paragraph("Үшінші тарап сервистерін пайдаланғанда біз пайдаланушылардың жеке деректерін қорғау үшін қажетті шараларды қабылдаймыз.")
        ]),
        Section(id: "8", title: "8. Пайдаланушы құқықтары", blocks: [
            .paragraph("Қолданыстағы заңнамаға сәйкес пайдаланушының құқығы бар:"),
            .bullets([
                "жеке деректерді өңдеу туралы ақпарат алу;",
                "өз деректеріне қол жеткізуді сұрау;",
                "дәл емес ақпаратты түзету;",
                "заңда көзделген жағдайларда деректерді өңдеуге келісімді қайтарып алу;",
                "аккаунтты және байланысты жеке деректерді жоюды сұрау;",
                "Bluetooth және Apple Health рұқсаттарын басқару;",
                "құпиялылық туралы сұрақтармен хабарласу."
            ]),
            .paragraph("Өз құқықтарын жүзеге асыру үшін пайдаланушы қолданба функцияларын пайдалана алады немесе қолдау қызметіне жүгіне алады.")
        ]),
        Section(id: "9", title: "9. Аккаунтты жою", blocks: [
            .paragraph("Пайдаланушы аккаунтты жоюды тікелей TamyrFlow қолданбасында бастай алады."),
            .paragraph("Аккаунтты жою расталғаннан кейін оған байланысты жеке деректер сақтау мерзімдері мен заң талаптарына сәйкес жойылады."),
            .paragraph("Заңды негіздер бойынша сақталуы тиіс ақпарат заңда көзделген мерзім бойы сақталуы мүмкін."),
            .paragraph("Қолданбаны iPhone-нан жою аккаунт пен бұлтта сақталған деректердің автоматты түрде жойылуын білдірмейді."),
            .paragraph("Аккаунтты жоюға көмек алу үшін пайдаланушы қолдау қызметіне жүгіне алады.")
        ]),
        Section(id: "10", title: "10. Медициналық ескерту", blocks: [
            .paragraph("TamyrFlow физикалық белсенділікті, жалпы өзін-өзі сезінуді қадағалауға және үйлесімді құрылғылардың деректерін көрсетуге арналған."),
            .paragraph("Қолданба ауруларды өз бетінше диагностикалауға, ем тағайындауға немесе медициналық маман кеңесін алмастыруға арналмаған."),
            .paragraph("Пульс, артериялық қысым, қандағы оттегі және температура көрсеткіштері қосылған құрылғылардан немесе пайдаланушы рұқсат еткен көздерден түседі."),
            .paragraph("Көрсеткіштердің дәлдігі құрылғы сипаттамаларына, өлшеу жағдайларына және оны дұрыс пайдалануға байланысты."),
            .paragraph("Көрсетілетін ақпарат ақпараттық және фитнес сипатында."),
            .paragraph("Пайдаланушылар қолданба деректерін медициналық шешім қабылдаудың жалғыз негізі ретінде пайдаланбауы керек."),
            .paragraph("Денсаулық жағдайы туралы сұрақтар туындаса, білікті медициналық маманға жүгіну ұсынылады.")
        ]),
        Section(id: "11", title: "11. iOS рұқсаттары", blocks: [
            .paragraph("Жекелеген функциялардың жұмысы үшін TamyrFlow келесі рұқсаттарды сұрауы мүмкін."),
            .paragraph("Bluetooth"),
            .paragraph("Үйлесімді смарт сағаттарды қосу және өлшеу көрсеткіштерін алу үшін пайдаланылады."),
            .paragraph("Apple Health"),
            .paragraph("Пайдаланушы рұқсат еткен денсаулық пен физикалық белсенділік көрсеткіштерін оқу үшін пайдаланылады."),
            .paragraph("Хабарландырулар"),
            .paragraph("Тиісті функция қолжетімді болса және пайдаланушы хабарландыруларға рұқсат берсе, белсенділік туралы еске салулар мен қызметтік хабарламалар үшін пайдаланылуы мүмкін."),
            .paragraph("Фотосуреттер"),
            .paragraph("Пайдаланушы осы функцияны өз бетінше пайдаланса, профиль фотосуретін таңдау үшін пайдаланылуы мүмкін."),
            .paragraph("Барлық рұқсаттар пайдаланушыға iOS жүйелік механизмдері арқылы беріледі."),
            .paragraph("Пайдаланушы рұқсаттарды құрылғы параметрлерінде өзгерте немесе қайтарып ала алады.")
        ]),
        Section(id: "12", title: "12. Саясат өзгерістері", blocks: [
            .paragraph("Біз қолданба функцияларының, деректерді өңдеу тәсілдерінің немесе заңнама талаптарының өзгеруіне байланысты осы Құпиялылық саясатын мерзімді түрде жаңартуымыз мүмкін."),
            .paragraph("Маңызды өзгерістер болғанда пайдаланушылар қолжетімді құралдар арқылы хабардар етіледі."),
            .paragraph("Құпиялылық саясатының өзекті нұсқасы TamyrFlow ресми бетінде жарияланады.")
        ]),
        Section(id: "13", title: "13. Байланыс", blocks: [
            .paragraph("Құпиялылық, жеке деректерді өңдеу немесе жою туралы сұрақтарыңыз болса, бізбен байланыса аласыз."),
            .contact(label: "Қолданба", value: "TamyrFlow"),
            .contact(label: "Email", value: "tamyrflow@gmail.com"),
            .contact(label: "Телефон", value: "+7 706 690 55 06"),
            .contact(label: "Ел", value: "Қазақстан Республикасы")
        ])
    ]
}

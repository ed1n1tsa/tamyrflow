import Foundation

/// Structured Terms of Use — readable scrolling document.
/// Content mirrors landing/legal-data.json (RU/EN/KK).
enum TermsOfUseDocument {
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
        case AppLanguageCode.en.rawValue: return "TamyrFlow Terms of Use"
        case AppLanguageCode.kk.rawValue: return "TamyrFlow пайдалану шарттары"
        default: return "Условия использования TamyrFlow"
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
            .paragraph("TamyrFlow — мобильное приложение для фитнеса и отслеживания физической активности, которое позволяет просматривать показатели здоровья и самочувствия, получаемые с совместимых умных часов и из Apple Health."),
            .paragraph("Настоящие Условия регулируют использование приложения TamyrFlow."),
            .paragraph("Используя приложение, пользователь подтверждает ознакомление с настоящими Условиями и принимает их."),
            .paragraph("Если пользователь не согласен с Условиями, ему следует прекратить использование приложения."),
            .paragraph("Приложение предназначено для пользователей на территории Республики Казахстан.")
        ]),
        Section(id: "2", title: "2. Функции приложения", blocks: [
            .paragraph("TamyrFlow предоставляет возможность:"),
            .bullets([
                "создавать и редактировать личный профиль;",
                "подключать совместимые умные часы через Bluetooth;",
                "просматривать количество шагов;",
                "отслеживать пульс;",
                "просматривать уровень кислорода в крови (SpO₂);",
                "просматривать артериальное давление;",
                "просматривать температуру;",
                "отслеживать расход калорий;",
                "просматривать историю измерений;",
                "устанавливать и отслеживать персональные цели;",
                "получать разрешённые пользователем данные из Apple Health."
            ]),
            .paragraph("Доступность функций зависит от модели устройства, версии приложения и предоставленных разрешений.")
        ]),
        Section(id: "3", title: "3. Регистрация и аккаунт", blocks: [
            .paragraph("Для использования отдельных функций приложения может потребоваться создание аккаунта."),
            .paragraph("Пользователь обязуется предоставлять достоверную информацию и обеспечивать безопасность своей учётной записи."),
            .paragraph("При обнаружении несанкционированного доступа пользователь может обратиться в службу поддержки."),
            .paragraph("Пользователь может инициировать удаление аккаунта через соответствующую функцию приложения.")
        ]),
        Section(id: "4", title: "4. Подключение умных часов", blocks: [
            .paragraph("TamyrFlow использует Bluetooth для подключения совместимых умных часов и получения показателей измерений."),
            .paragraph("Приложение отображает данные, сформированные подключённым устройством."),
            .paragraph("Точность измерений зависит от характеристик часов, условий измерения и правильности их использования."),
            .paragraph("Совместимость со всеми моделями устройств не гарантируется.")
        ]),
        Section(id: "5", title: "5. Apple Health", blocks: [
            .paragraph("TamyrFlow может получать данные из Apple Health с разрешения пользователя."),
            .paragraph("Приложение использует HealthKit только для чтения поддерживаемых показателей."),
            .paragraph("TamyrFlow не записывает и не изменяет данные в Apple Health."),
            .paragraph("Пользователь может отозвать разрешения через настройки iOS.")
        ]),
        Section(id: "6", title: "6. Медицинский дисклеймер", blocks: [
            .paragraph("TamyrFlow предназначен для отслеживания физической активности, общего самочувствия и отображения данных совместимых устройств."),
            .paragraph("Приложение не предназначено для диагностики заболеваний, назначения лечения или замены консультации медицинского специалиста."),
            .paragraph("Показатели пульса, артериального давления, кислорода в крови и температуры поступают с подключённых устройств или других разрешённых источников."),
            .paragraph("Точность показателей зависит от используемого устройства."),
            .paragraph("Данные приложения не следует использовать как единственное основание для принятия медицинских решений."),
            .paragraph("При возникновении вопросов о здоровье рекомендуется обратиться к квалифицированному медицинскому специалисту.")
        ]),
        Section(id: "7", title: "7. Правила использования", blocks: [
            .paragraph("Пользователь обязуется:"),
            .bullets([
                "соблюдать законодательство Республики Казахстан;",
                "не предпринимать попыток несанкционированного доступа;",
                "не вмешиваться в работу приложения;",
                "не использовать приложение для противоправных целей;",
                "не нарушать права других пользователей."
            ])
        ]),
        Section(id: "8", title: "8. Конфиденциальность", blocks: [
            .paragraph("Обработка персональных данных осуществляется в соответствии с Политикой конфиденциальности TamyrFlow."),
            .paragraph("Приложение может обрабатывать информацию аккаунта, показатели здоровья и физической активности, а также технические данные, необходимые для работы сервиса."),
            .paragraph("Политика конфиденциальности доступна в приложении.")
        ]),
        Section(id: "9", title: "9. Хранение данных", blocks: [
            .paragraph("TamyrFlow может использовать облачную инфраструктуру для хранения информации аккаунта, пользовательских настроек и поддерживаемых данных приложения."),
            .paragraph("Для синхронизации может требоваться интернет-соединение."),
            .paragraph("При отсутствии подключения отдельные функции могут быть недоступны.")
        ]),
        Section(id: "10", title: "10. Доступность приложения", blocks: [
            .paragraph("Мы стремимся обеспечивать стабильную работу TamyrFlow."),
            .paragraph("Отдельные функции могут быть временно недоступны из-за технического обслуживания, обновлений, проблем подключения или сбоев сторонних сервисов."),
            .paragraph("Функциональность приложения может обновляться и совершенствоваться.")
        ]),
        Section(id: "11", title: "11. Интеллектуальная собственность", blocks: [
            .paragraph("Название TamyrFlow, дизайн, программный код, графические элементы и другие материалы приложения защищаются применимым законодательством об интеллектуальной собственности."),
            .paragraph("Использование приложения не предоставляет пользователю права собственности на программное обеспечение и материалы."),
            .paragraph("Пользователю предоставляется ограниченное, неисключительное и непередаваемое право использовать приложение в личных целях в соответствии с настоящими Условиями.")
        ]),
        Section(id: "12", title: "12. Ограничение ответственности", blocks: [
            .paragraph("TamyrFlow отображает информацию о физической активности и показателях, получаемых с совместимых устройств."),
            .paragraph("Мы не гарантируем абсолютную точность или непрерывную доступность измерений."),
            .paragraph("В пределах, допускаемых применимым законодательством, ответственность за последствия использования приложения с нарушением настоящих Условий или инструкций производителя устройств может быть ограничена."),
            .paragraph("Настоящие Условия не ограничивают права потребителей, гарантированные законодательством Республики Казахстан.")
        ]),
        Section(id: "13", title: "13. Удаление аккаунта", blocks: [
            .paragraph("Пользователь может прекратить использование приложения в любое время."),
            .paragraph("При наличии аккаунта пользователь может инициировать его удаление непосредственно в приложении."),
            .paragraph("Удаление персональных данных осуществляется в соответствии с Политикой конфиденциальности и применимым законодательством.")
        ]),
        Section(id: "14", title: "14. Изменение условий", blocks: [
            .paragraph("Мы можем обновлять настоящие Условия в связи с изменением функций приложения или законодательства."),
            .paragraph("При существенных изменениях пользователи будут уведомлены доступными средствами.")
        ]),
        Section(id: "15", title: "15. Применимое законодательство", blocks: [
            .paragraph("Настоящие Условия регулируются законодательством Республики Казахстан."),
            .paragraph("Споры разрешаются в соответствии с применимым законодательством Республики Казахстан.")
        ]),
        Section(id: "16", title: "16. Контакты", blocks: [
            .paragraph("По вопросам использования приложения, технической поддержки и обработки персональных данных обращайтесь:"),
            .contact(label: "Приложение", value: "TamyrFlow"),
            .contact(label: "Email", value: "tamyrflow@gmail.com"),
            .contact(label: "Телефон", value: "+7 706 690 55 06"),
            .contact(label: "Страна", value: "Республика Казахстан")
        ])
    ]

    // MARK: - English

    private static let english: [Section] = [
        Section(id: "1", title: "1. General provisions", blocks: [
            .paragraph("TamyrFlow is a mobile fitness and activity-tracking app that lets you view health and well-being metrics from compatible smartwatches and Apple Health."),
            .paragraph("These Terms govern the use of the TamyrFlow app."),
            .paragraph("By using the app, the user confirms that they have read and accept these Terms."),
            .paragraph("If the user does not agree with the Terms, they should stop using the app."),
            .paragraph("The app is intended for users in the Republic of Kazakhstan.")
        ]),
        Section(id: "2", title: "2. App features", blocks: [
            .paragraph("TamyrFlow provides the ability to:"),
            .bullets([
                "create and edit a personal profile;",
                "connect compatible smartwatches via Bluetooth;",
                "view step count;",
                "track heart rate;",
                "view blood oxygen level (SpO₂);",
                "view blood pressure;",
                "view temperature;",
                "track calorie expenditure;",
                "view measurement history;",
                "set and track personal goals;",
                "receive user-authorized data from Apple Health."
            ]),
            .paragraph("Feature availability depends on the device model, app version, and permissions granted.")
        ]),
        Section(id: "3", title: "3. Registration and account", blocks: [
            .paragraph("Creating an account may be required to use certain app features."),
            .paragraph("The user agrees to provide accurate information and keep their account secure."),
            .paragraph("If unauthorized access is detected, the user may contact support."),
            .paragraph("The user may initiate account deletion through the corresponding in-app feature.")
        ]),
        Section(id: "4", title: "4. Connecting a smartwatch", blocks: [
            .paragraph("TamyrFlow uses Bluetooth to connect compatible smartwatches and receive measurement metrics."),
            .paragraph("The app displays data produced by the connected device."),
            .paragraph("Measurement accuracy depends on the watch characteristics, measurement conditions, and correct use."),
            .paragraph("Compatibility with all device models is not guaranteed.")
        ]),
        Section(id: "5", title: "5. Apple Health", blocks: [
            .paragraph("TamyrFlow may obtain data from Apple Health with the user’s permission."),
            .paragraph("The app uses HealthKit only to read supported metrics."),
            .paragraph("TamyrFlow does not write to or modify data in Apple Health."),
            .paragraph("The user may revoke permissions in iOS Settings.")
        ]),
        Section(id: "6", title: "6. Medical disclaimer", blocks: [
            .paragraph("TamyrFlow is intended for tracking physical activity, general well-being, and displaying data from compatible devices."),
            .paragraph("The app is not intended for diagnosing diseases, prescribing treatment, or replacing consultation with a medical professional."),
            .paragraph("Heart rate, blood pressure, blood oxygen, and temperature metrics come from connected devices or other authorized sources."),
            .paragraph("Accuracy of metrics depends on the device used."),
            .paragraph("App data should not be used as the sole basis for medical decisions."),
            .paragraph("If you have health questions, consult a qualified medical professional.")
        ]),
        Section(id: "7", title: "7. Acceptable use", blocks: [
            .paragraph("The user agrees to:"),
            .bullets([
                "comply with the laws of the Republic of Kazakhstan;",
                "not attempt unauthorized access;",
                "not interfere with the operation of the app;",
                "not use the app for unlawful purposes;",
                "not violate the rights of other users."
            ])
        ]),
        Section(id: "8", title: "8. Privacy", blocks: [
            .paragraph("Personal data is processed in accordance with the TamyrFlow Privacy Policy."),
            .paragraph("The app may process account information, health and physical activity metrics, and technical data needed to operate the service."),
            .paragraph("The Privacy Policy is available in the app.")
        ]),
        Section(id: "9", title: "9. Data storage", blocks: [
            .paragraph("TamyrFlow may use cloud infrastructure to store account information, user settings, and supported app data."),
            .paragraph("An internet connection may be required for sync."),
            .paragraph("Without a connection, certain features may be unavailable.")
        ]),
        Section(id: "10", title: "10. Availability", blocks: [
            .paragraph("We aim to keep TamyrFlow running reliably."),
            .paragraph("Certain features may be temporarily unavailable due to maintenance, updates, connectivity issues, or third-party service outages."),
            .paragraph("App functionality may be updated and improved.")
        ]),
        Section(id: "11", title: "11. Intellectual property", blocks: [
            .paragraph("The TamyrFlow name, design, software code, graphics, and other app materials are protected by applicable intellectual property law."),
            .paragraph("Using the app does not grant the user ownership of the software or materials."),
            .paragraph("The user is granted a limited, non-exclusive, non-transferable right to use the app for personal purposes in accordance with these Terms.")
        ]),
        Section(id: "12", title: "12. Limitation of liability", blocks: [
            .paragraph("TamyrFlow displays information about physical activity and metrics obtained from compatible devices."),
            .paragraph("We do not guarantee absolute accuracy or continuous availability of measurements."),
            .paragraph("To the extent permitted by applicable law, liability for consequences of using the app in violation of these Terms or device manufacturer instructions may be limited."),
            .paragraph("These Terms do not limit consumer rights guaranteed by the laws of the Republic of Kazakhstan.")
        ]),
        Section(id: "13", title: "13. Account deletion", blocks: [
            .paragraph("The user may stop using the app at any time."),
            .paragraph("If an account exists, the user may initiate its deletion directly in the app."),
            .paragraph("Deletion of personal data is carried out in accordance with the Privacy Policy and applicable law.")
        ]),
        Section(id: "14", title: "14. Changes to the Terms", blocks: [
            .paragraph("We may update these Terms due to changes in app features or legislation."),
            .paragraph("For material changes, users will be notified by available means.")
        ]),
        Section(id: "15", title: "15. Governing law", blocks: [
            .paragraph("These Terms are governed by the laws of the Republic of Kazakhstan."),
            .paragraph("Disputes are resolved in accordance with the applicable laws of the Republic of Kazakhstan.")
        ]),
        Section(id: "16", title: "16. Contact", blocks: [
            .paragraph("For questions about using the app, technical support, and personal data processing, contact:"),
            .contact(label: "App", value: "TamyrFlow"),
            .contact(label: "Email", value: "tamyrflow@gmail.com"),
            .contact(label: "Phone", value: "+7 706 690 55 06"),
            .contact(label: "Country", value: "Republic of Kazakhstan")
        ])
    ]

    // MARK: - Kazakh

    private static let kazakh: [Section] = [
        Section(id: "1", title: "1. Жалпы ережелер", blocks: [
            .paragraph("TamyrFlow — үйлесімді смарт сағаттардан және Apple Health-тен алынатын денсаулық пен өзін-өзі сезіну көрсеткіштерін көруге мүмкіндік беретін фитнес пен физикалық белсенділікті қадағалауға арналған мобильді қолданба."),
            .paragraph("Осы Шарттар TamyrFlow қолданбасын пайдалануды реттейді."),
            .paragraph("Қолданбаны пайдалана отырып, пайдаланушы осы Шарттармен танысқанын және оларды қабылдайтынын растайды."),
            .paragraph("Пайдаланушы Шарттармен келіспесе, қолданбаны пайдалануды тоқтатуы керек."),
            .paragraph("Қолданба Қазақстан Республикасы аумағындағы пайдаланушыларға арналған.")
        ]),
        Section(id: "2", title: "2. Қолданба функциялары", blocks: [
            .paragraph("TamyrFlow мына мүмкіндіктерді ұсынады:"),
            .bullets([
                "жеке профиль жасау және өңдеу;",
                "үйлесімді смарт сағаттарды Bluetooth арқылы қосу;",
                "қадам санын көру;",
                "пульсті қадағалау;",
                "қандағы оттегі деңгейін (SpO₂) көру;",
                "артериялық қысымды көру;",
                "температураны көру;",
                "калория шығынын қадағалау;",
                "өлшеулер тарихын көру;",
                "жеке мақсаттарды орнату және қадағалау;",
                "пайдаланушы рұқсат еткен деректерді Apple Health-тен алу."
            ]),
            .paragraph("Функциялардың қолжетімділігі құрылғы моделіне, қолданба нұсқасына және берілген рұқсаттарға байланысты.")
        ]),
        Section(id: "3", title: "3. Тіркеу және аккаунт", blocks: [
            .paragraph("Қолданбаның жекелеген функцияларын пайдалану үшін аккаунт жасау қажет болуы мүмкін."),
            .paragraph("Пайдаланушы шынайы ақпарат беруге және өз тіркелгісінің қауіпсіздігін қамтамасыз етуге міндеттенеді."),
            .paragraph("Рұқсатсыз қол жеткізу анықталса, пайдаланушы қолдау қызметіне жүгіне алады."),
            .paragraph("Пайдаланушы аккаунтты жоюды қолданбадағы тиісті функция арқылы бастай алады.")
        ]),
        Section(id: "4", title: "4. Смарт сағатты қосу", blocks: [
            .paragraph("TamyrFlow үйлесімді смарт сағаттарды қосу және өлшеу көрсеткіштерін алу үшін Bluetooth пайдаланады."),
            .paragraph("Қолданба қосылған құрылғы қалыптастырған деректерді көрсетеді."),
            .paragraph("Өлшеулердің дәлдігі сағат сипаттамаларына, өлшеу жағдайларына және оларды дұрыс пайдалануға байланысты."),
            .paragraph("Барлық құрылғы модельдерімен үйлесімділікке кепілдік берілмейді.")
        ]),
        Section(id: "5", title: "5. Apple Health", blocks: [
            .paragraph("TamyrFlow пайдаланушы рұқсатымен Apple Health-тен деректер алуы мүмкін."),
            .paragraph("Қолданба HealthKit-ті тек қолдау көрсетілетін көрсеткіштерді оқу үшін пайдаланады."),
            .paragraph("TamyrFlow Apple Health-тегі деректерді жазбайды және өзгертпейді."),
            .paragraph("Пайдаланушы рұқсаттарды iOS параметрлері арқылы қайтарып ала алады.")
        ]),
        Section(id: "6", title: "6. Медициналық ескерту", blocks: [
            .paragraph("TamyrFlow физикалық белсенділікті, жалпы өзін-өзі сезінуді қадағалауға және үйлесімді құрылғылардың деректерін көрсетуге арналған."),
            .paragraph("Қолданба ауруларды диагностикалауға, ем тағайындауға немесе медициналық маман кеңесін алмастыруға арналмаған."),
            .paragraph("Пульс, артериялық қысым, қандағы оттегі және температура көрсеткіштері қосылған құрылғылардан немесе басқа рұқсат етілген көздерден түседі."),
            .paragraph("Көрсеткіштердің дәлдігі пайдаланылатын құрылғыға байланысты."),
            .paragraph("Қолданба деректерін медициналық шешім қабылдаудың жалғыз негізі ретінде пайдаланбау керек."),
            .paragraph("Денсаулық туралы сұрақтар туындаса, білікті медициналық маманға жүгіну ұсынылады.")
        ]),
        Section(id: "7", title: "7. Пайдалану ережелері", blocks: [
            .paragraph("Пайдаланушы міндеттенеді:"),
            .bullets([
                "Қазақстан Республикасының заңнамасын сақтау;",
                "рұқсатсыз қол жеткізу әрекеттерін жасамау;",
                "қолданба жұмысына араласпау;",
                "қолданбаны құқыққа қайшы мақсаттарға пайдаланбау;",
                "басқа пайдаланушылардың құқықтарын бұзбау."
            ])
        ]),
        Section(id: "8", title: "8. Құпиялылық", blocks: [
            .paragraph("Жеке деректер TamyrFlow Құпиялылық саясатына сәйкес өңделеді."),
            .paragraph("Қолданба аккаунт ақпаратын, денсаулық пен физикалық белсенділік көрсеткіштерін, сондай-ақ сервистің жұмысы үшін қажет техникалық деректерді өңдеуі мүмкін."),
            .paragraph("Құпиялылық саясаты қолданбада қолжетімді.")
        ]),
        Section(id: "9", title: "9. Деректерді сақтау", blocks: [
            .paragraph("TamyrFlow аккаунт ақпаратын, пайдаланушы параметрлерін және қолданбаның қолдау көрсетілетін деректерін сақтау үшін бұлттық инфрақұрылымды пайдалануы мүмкін."),
            .paragraph("Синхрондау үшін интернет-қосылым қажет болуы мүмкін."),
            .paragraph("Қосылым болмаса, жекелеген функциялар қолжетімсіз болуы мүмкін.")
        ]),
        Section(id: "10", title: "10. Қолжетімділік", blocks: [
            .paragraph("Біз TamyrFlow-тың тұрақты жұмысын қамтамасыз етуге тырысамыз."),
            .paragraph("Жекелеген функциялар техникалық қызмет көрсету, жаңартулар, қосылым мәселелері немесе үшінші тарап сервистерінің ақаулары салдарынан уақытша қолжетімсіз болуы мүмкін."),
            .paragraph("Қолданба функционалдығы жаңартылып, жетілдірілуі мүмкін.")
        ]),
        Section(id: "11", title: "11. Зияткерлік меншік", blocks: [
            .paragraph("TamyrFlow атауы, дизайны, бағдарламалық коды, графикалық элементтері және басқа материалдары қолданыстағы зияткерлік меншік заңнамасымен қорғалады."),
            .paragraph("Қолданбаны пайдалану пайдаланушыға бағдарламалық жасақтама мен материалдарға меншік құқығын бермейді."),
            .paragraph("Пайдаланушыға осы Шарттарға сәйкес қолданбаны жеке мақсатта пайдаланудың шектеулі, айрықша емес және берілмейтін құқығы беріледі.")
        ]),
        Section(id: "12", title: "12. Жауапкершілікті шектеу", blocks: [
            .paragraph("TamyrFlow үйлесімді құрылғылардан алынатын физикалық белсенділік пен көрсеткіштер туралы ақпаратты көрсетеді."),
            .paragraph("Біз өлшеулердің абсолютті дәлдігіне немесе үздіксіз қолжетімділігіне кепілдік бермейміз."),
            .paragraph("Қолданыстағы заңнама рұқсат ететін шекте осы Шарттарды немесе құрылғы өндірушісінің нұсқауларын бұза отырып қолданбаны пайдалану салдарлары үшін жауапкершілік шектелуі мүмкін."),
            .paragraph("Осы Шарттар Қазақстан Республикасының заңнамасымен кепілдендірілген тұтынушы құқықтарын шектемейді.")
        ]),
        Section(id: "13", title: "13. Аккаунтты жою", blocks: [
            .paragraph("Пайдаланушы қолданбаны пайдалануды кез келген уақытта тоқтата алады."),
            .paragraph("Аккаунт болса, пайдаланушы оны тікелей қолданбада жоюды бастай алады."),
            .paragraph("Жеке деректерді жою Құпиялылық саясатына және қолданыстағы заңнамаға сәйкес жүргізіледі.")
        ]),
        Section(id: "14", title: "14. Шарттарды өзгерту", blocks: [
            .paragraph("Біз қолданба функцияларының немесе заңнаманың өзгеруіне байланысты осы Шарттарды жаңартуымыз мүмкін."),
            .paragraph("Маңызды өзгерістер болғанда пайдаланушылар қолжетімді құралдар арқылы хабардар етіледі.")
        ]),
        Section(id: "15", title: "15. Қолданылатын заң", blocks: [
            .paragraph("Осы Шарттар Қазақстан Республикасының заңнамасымен реттеледі."),
            .paragraph("Даулар Қазақстан Республикасының қолданыстағы заңнамасына сәйкес шешіледі.")
        ]),
        Section(id: "16", title: "16. Байланыс", blocks: [
            .paragraph("Қолданбаны пайдалану, техникалық қолдау және жеке деректерді өңдеу мәселелері бойынша хабарласыңыз:"),
            .contact(label: "Қолданба", value: "TamyrFlow"),
            .contact(label: "Email", value: "tamyrflow@gmail.com"),
            .contact(label: "Телефон", value: "+7 706 690 55 06"),
            .contact(label: "Ел", value: "Қазақстан Республикасы")
        ])
    ]
}

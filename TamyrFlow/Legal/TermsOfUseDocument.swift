import Foundation

/// Structured Terms of Use — readable scrolling document.
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
        Section(id: "1", title: "1. General", blocks: [
            .paragraph("TamyrFlow is a fitness and activity-tracking mobile app for viewing wellness metrics from compatible smartwatches and Apple Health."),
            .paragraph("These Terms govern use of the TamyrFlow app."),
            .paragraph("By using the app, you confirm that you have read and accept these Terms."),
            .paragraph("If you do not agree, stop using the app."),
            .paragraph("The app is intended for users in the Republic of Kazakhstan.")
        ]),
        Section(id: "2", title: "2. App features", blocks: [
            .paragraph("TamyrFlow lets you:"),
            .bullets([
                "create and edit a personal profile;",
                "connect compatible smartwatches via Bluetooth;",
                "view step count;",
                "track heart rate;",
                "view blood oxygen (SpO₂);",
                "view blood pressure;",
                "view temperature;",
                "track calories burned;",
                "view measurement history;",
                "set and track personal goals;",
                "receive Apple Health data you allow."
            ]),
            .paragraph("Feature availability depends on device model, app version, and permissions granted.")
        ]),
        Section(id: "3", title: "3. Registration and account", blocks: [
            .paragraph("Some features may require an account."),
            .paragraph("You agree to provide accurate information and keep your account secure."),
            .paragraph("If you notice unauthorized access, contact support."),
            .paragraph("You may start account deletion through the in-app option.")
        ]),
        Section(id: "4", title: "4. Connecting a smartwatch", blocks: [
            .paragraph("TamyrFlow uses Bluetooth to connect compatible smartwatches and receive measurements."),
            .paragraph("The app displays data produced by the connected device."),
            .paragraph("Accuracy depends on the watch, measurement conditions, and correct use."),
            .paragraph("Compatibility with every device model is not guaranteed.")
        ]),
        Section(id: "5", title: "5. Apple Health", blocks: [
            .paragraph("TamyrFlow may read Apple Health data with your permission."),
            .paragraph("HealthKit access is read-only for supported metrics."),
            .paragraph("TamyrFlow does not write or change Apple Health data."),
            .paragraph("You may revoke permissions in iOS Settings.")
        ]),
        Section(id: "6", title: "6. Medical disclaimer", blocks: [
            .paragraph("TamyrFlow is for tracking activity, general wellness, and displaying data from compatible devices."),
            .paragraph("It is not for diagnosing disease, prescribing treatment, or replacing medical advice."),
            .paragraph("Heart rate, blood pressure, blood oxygen, and temperature come from connected devices or other allowed sources."),
            .paragraph("Accuracy depends on the device used."),
            .paragraph("Do not rely on app data alone for medical decisions."),
            .paragraph("If you have health questions, consult a qualified medical professional.")
        ]),
        Section(id: "7", title: "7. Acceptable use", blocks: [
            .paragraph("You agree to:"),
            .bullets([
                "comply with the laws of the Republic of Kazakhstan;",
                "not attempt unauthorized access;",
                "not interfere with the app;",
                "not use the app for unlawful purposes;",
                "not infringe other users’ rights."
            ])
        ]),
        Section(id: "8", title: "8. Privacy", blocks: [
            .paragraph("Personal data is processed under the TamyrFlow Privacy Policy."),
            .paragraph("The app may process account information, health and activity metrics, and technical data needed to run the service."),
            .paragraph("The Privacy Policy is available in the app.")
        ]),
        Section(id: "9", title: "9. Data storage", blocks: [
            .paragraph("TamyrFlow may use cloud infrastructure to store account information, settings, and supported app data."),
            .paragraph("Sync may require an internet connection."),
            .paragraph("Without connectivity, some features may be unavailable.")
        ]),
        Section(id: "10", title: "10. Availability", blocks: [
            .paragraph("We aim to keep TamyrFlow stable."),
            .paragraph("Some features may be temporarily unavailable due to maintenance, updates, connectivity issues, or third-party outages."),
            .paragraph("App functionality may be updated and improved.")
        ]),
        Section(id: "11", title: "11. Intellectual property", blocks: [
            .paragraph("The TamyrFlow name, design, code, graphics, and other materials are protected by applicable intellectual property law."),
            .paragraph("Using the app does not give you ownership of the software or materials."),
            .paragraph("You receive a limited, non-exclusive, non-transferable right to use the app for personal purposes under these Terms.")
        ]),
        Section(id: "12", title: "12. Limitation of liability", blocks: [
            .paragraph("TamyrFlow displays activity and metric information from compatible devices."),
            .paragraph("We do not guarantee absolute accuracy or uninterrupted availability of measurements."),
            .paragraph("To the extent allowed by law, liability for consequences of using the app in breach of these Terms or device-maker instructions may be limited."),
            .paragraph("These Terms do not limit consumer rights guaranteed by the laws of the Republic of Kazakhstan.")
        ]),
        Section(id: "13", title: "13. Account deletion", blocks: [
            .paragraph("You may stop using the app at any time."),
            .paragraph("If you have an account, you may start deletion in the app."),
            .paragraph("Personal data deletion follows the Privacy Policy and applicable law.")
        ]),
        Section(id: "14", title: "14. Changes to the Terms", blocks: [
            .paragraph("We may update these Terms when app features or laws change."),
            .paragraph("For material changes, users will be notified by available means.")
        ]),
        Section(id: "15", title: "15. Governing law", blocks: [
            .paragraph("These Terms are governed by the laws of the Republic of Kazakhstan."),
            .paragraph("Disputes are resolved under applicable Kazakhstan law.")
        ]),
        Section(id: "16", title: "16. Contact", blocks: [
            .paragraph("For questions about the app, support, or personal data processing, contact:"),
            .contact(label: "App", value: "TamyrFlow"),
            .contact(label: "Email", value: "tamyrflow@gmail.com"),
            .contact(label: "Phone", value: "+7 706 690 55 06"),
            .contact(label: "Country", value: "Republic of Kazakhstan")
        ])
    ]

    // MARK: - Kazakh

    private static let kazakh: [Section] = [
        Section(id: "1", title: "1. Жалпы ережелер", blocks: [
            .paragraph("TamyrFlow — үйлесімді смарт-сағаттар мен Apple Health көрсеткіштерін қарауға арналған фитнес қолданбасы."),
            .paragraph("Осы Шарттар TamyrFlow пайдалануды реттейді."),
            .paragraph("Қолданбаны пайдалану арқылы сіз Шарттармен танысқаныңызды және қабылдайтыныңызды растайсыз."),
            .paragraph("Келіспесеңіз, қолданбаны пайдалануды тоқтатыңыз."),
            .paragraph("Қолданба Қазақстан Республикасы аумағындағы пайдаланушыларға арналған.")
        ]),
        Section(id: "2", title: "2. Қолданба функциялары", blocks: [
            .paragraph("TamyrFlow мүмкіндік береді:"),
            .bullets([
                "жеке профиль жасау және өңдеу;",
                "Bluetooth арқылы үйлесімді сағат қосу;",
                "қадам санын көру;",
                "пульсті бақылау;",
                "SpO₂, қысым, температураны көру;",
                "калория шығынын бақылау;",
                "өлшеу тарихын көру;",
                "жеке мақсаттар қою;",
                "рұқсат етілген Apple Health деректерін алу."
            ]),
            .paragraph("Функциялар құрылғы моделіне, нұсқаға және рұқсаттарға байланысты.")
        ]),
        Section(id: "3", title: "3. Тіркеу және аккаунт", blocks: [
            .paragraph("Кейбір функциялар үшін аккаунт қажет болуы мүмкін."),
            .paragraph("Сіз нақты ақпарат беруге және аккаунт қауіпсіздігін сақтауға міндеттесесіз."),
            .paragraph("Аккаунтты қолданбадағы тиісті функция арқылы жоюға болады.")
        ]),
        Section(id: "4", title: "4. Сағатты қосу", blocks: [
            .paragraph("TamyrFlow үйлесімді сағаттарды Bluetooth арқылы қосады және өлшемдерді алады."),
            .paragraph("Дәлдік құрылғыға және өлшеу жағдайына байланысты; барлық модельдермен үйлесімділік кепілденбейді.")
        ]),
        Section(id: "5", title: "5. Apple Health", blocks: [
            .paragraph("Apple Health деректері тек сіздің рұқсатыңызбен оқылады."),
            .paragraph("TamyrFlow Apple Health-қа жазбайды және өзгертпейді."),
            .paragraph("Рұқсатты iOS баптауларында кері қайтаруға болады.")
        ]),
        Section(id: "6", title: "6. Медициналық ескерту", blocks: [
            .paragraph("TamyrFlow фитнес пен жалпы әл-ауқатты бақылауға арналған, диагноз немесе емдеу үшін емес."),
            .paragraph("Деректерді медициналық шешімнің жалғыз негізі ретінде пайдаланбаңыз."),
            .paragraph("Денсаулық мәселесінде білікті дәрігерге жүгініңіз.")
        ]),
        Section(id: "7", title: "7. Пайдалану ережелері", blocks: [
            .bullets([
                "ҚР заңнамасын сақтау;",
                "рұқсатсыз қол жеткізуге әрекет жасамау;",
                "қолданба жұмысына кедергі жасамау;",
                "заңсыз мақсаттарға пайдаланбау;",
                "басқа пайдаланушылардың құқығын бұзбау."
            ])
        ]),
        Section(id: "8", title: "8. Құпиялылық", blocks: [
            .paragraph("Жеке деректер TamyrFlow Құпиялылық саясатына сәйкес өңделеді."),
            .paragraph("Саясат қолданбада қолжетімді.")
        ]),
        Section(id: "9", title: "9. Деректерді сақтау", blocks: [
            .paragraph("Аккаунт пен қолданба деректері бұлтта сақталуы мүмкін."),
            .paragraph("Синхрондау үшін интернет қажет болуы мүмкін.")
        ]),
        Section(id: "10", title: "10. Қолжетімділік", blocks: [
            .paragraph("Біз тұрақты жұмысқа ұмтыламыз; техникалық себептермен кей функциялар уақытша қолжетімсіз болуы мүмкін.")
        ]),
        Section(id: "11", title: "11. Зияткерлік меншік", blocks: [
            .paragraph("TamyrFlow атауы, дизайн, код және материалдар зияткерлік меншікпен қорғалады."),
            .paragraph("Қолданбаны пайдалану меншік құқығын бермейді.")
        ]),
        Section(id: "12", title: "12. Жауапкершілікті шектеу", blocks: [
            .paragraph("Өлшемдердің абсолют дәлдігіне немесе үздіксіз қолжетімділігіне кепілдік берілмейді."),
            .paragraph("Шарттар ҚР тұтынушы құқықтарын шектемейді.")
        ]),
        Section(id: "13", title: "13. Аккаунтты жою", blocks: [
            .paragraph("Қолданбаны кез келген уақытта тоқтатуға болады."),
            .paragraph("Аккаунтты қолданбадан жоюға болады; деректер Құпиялылық саясатына сәйкес жойылады.")
        ]),
        Section(id: "14", title: "14. Шарттарды өзгерту", blocks: [
            .paragraph("Шарттар қолданба немесе заң өзгерісіне байланысты жаңартылуы мүмкін.")
        ]),
        Section(id: "15", title: "15. Қолданылатын заң", blocks: [
            .paragraph("Шарттар Қазақстан Республикасының заңнамасымен реттеледі.")
        ]),
        Section(id: "16", title: "16. Байланыс", blocks: [
            .paragraph("Қолдау және деректер бойынша сұрақтар үшін:"),
            .contact(label: "Қолданба", value: "TamyrFlow"),
            .contact(label: "Email", value: "tamyrflow@gmail.com"),
            .contact(label: "Телефон", value: "+7 706 690 55 06"),
            .contact(label: "Ел", value: "Қазақстан Республикасы")
        ])
    ]
}

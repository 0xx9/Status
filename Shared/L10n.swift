import Foundation

enum CopyKey: Hashable {
    case appName
    case yourBoard
    case boardHint
    case preparing
    case paused
    case calm
    case busy
    case strained
    case hot
    case lowBattery
    case insightCalm
    case insightCPUBusy
    case insightMemoryBusy
    case insightCPUStrained
    case insightMemoryStrained
    case insightHot
    case insightLowBattery
    case insightGPUBusy
    case insightCalculating
    case cpu
    case memory
    case disk
    case network
    case battery
    case processes
    case system
    case userTime
    case systemTime
    case cores
    case performance
    case efficiency
    case load
    case gpu
    case used
    case apps
    case wired
    case compressed
    case cached
    case free
    case pressure
    case swap
    case read
    case write
    case down
    case up
    case charging
    case onBatteryPower
    case pluggedIn
    case full
    case calculating
    case remaining
    case untilFull
    case cycles
    case health
    case noBattery
    case uptime
    case thermal
    case model
    case chip
    case os
    case computer
    case thermalNominal
    case thermalFair
    case thermalSerious
    case thermalCritical
    case pressureLow
    case pressureMedium
    case pressureHigh
    case addWidget
    case details
    case settings
    case pause
    case resume
    case refresh
    case quit
    case launchAtLogin
    case launchOn
    case launchOff
    case launchNeedsApproval
    case launchFailed
    case openLoginSettings
    case monitoring
    case live
    case manual
    case liveHint
    case manualHint
    case gentleBattery
    case showDock
    case showDockHint
    case menuBar
    case menuBarIcon
    case menuBarMetrics
    case menuBarHint
    case notifications
    case notifyBattery
    case notifyThermal
    case notifyMemory
    case batteryThreshold
    case notificationsDenied
    case openNotificationSettings
    case language
    case languageSystem
    case languageArabic
    case languageEnglish
    case units
    case bytesUnit
    case bitsUnit
    case pace
    case paceLive
    case paceBalanced
    case paceQuiet
    case moveUp
    case moveDown
    case hideWidget
    case shown
    case add
    case widgets
    case emptyBoard
    case emptyBoardHint
    case allWidgetsAdded
    case copySummary
    case copied
    case searchProcesses
    case sortCPU
    case sortMemory
    case noProcesses
    case version
    case about
    case monitorMenu
    case widgetCPUDetail
    case widgetMemoryDetail
    case widgetDiskDetail
    case widgetNetworkDetail
    case widgetBatteryDetail
    case widgetProcessesDetail
    case widgetSystemDetail
    case topProcesses
    case volumes
    case healthGood
    case healthFair
    case healthPoor
    case general
    case aboutBody
    case sampleEvery
    case quitApp
    case library
    case done
}

struct L10n: Equatable {
    var isArabic: Bool

    static func resolve(_ language: AppLanguage) -> L10n {
        let arabic: Bool
        switch language {
        case .arabic:
            arabic = true
        case .english:
            arabic = false
        case .system:
            arabic = Locale.preferredLanguages.first?.hasPrefix("ar") == true
        }
        return L10n(isArabic: arabic)
    }

    func t(_ key: CopyKey) -> String {
        isArabic ? arabic(key) : english(key)
    }

    func widgetTitle(_ kind: WidgetKind) -> String {
        switch kind {
        case .cpu: return t(.cpu)
        case .memory: return t(.memory)
        case .disk: return t(.disk)
        case .network: return t(.network)
        case .battery: return t(.battery)
        case .processes: return t(.processes)
        case .system: return t(.system)
        }
    }

    func widgetDetail(_ kind: WidgetKind) -> String {
        switch kind {
        case .cpu: return t(.widgetCPUDetail)
        case .memory: return t(.widgetMemoryDetail)
        case .disk: return t(.widgetDiskDetail)
        case .network: return t(.widgetNetworkDetail)
        case .battery: return t(.widgetBatteryDetail)
        case .processes: return t(.widgetProcessesDetail)
        case .system: return t(.widgetSystemDetail)
        }
    }

    func metricTitle(_ metric: MenuBarMetric) -> String {
        switch metric {
        case .cpu: return t(.cpu)
        case .memory: return t(.memory)
        case .battery: return t(.battery)
        case .network: return t(.network)
        case .disk: return t(.disk)
        }
    }

    func moodTitle(_ mood: MachineMood) -> String {
        switch mood {
        case .calm: return t(.calm)
        case .busy: return t(.busy)
        case .strained: return t(.strained)
        case .hot: return t(.hot)
        case .lowBattery: return t(.lowBattery)
        }
    }

    func insightText(_ insight: Insight) -> String {
        switch insight {
        case .calm: return t(.insightCalm)
        case .cpuBusy: return t(.insightCPUBusy)
        case .memoryBusy: return t(.insightMemoryBusy)
        case .cpuStrained: return t(.insightCPUStrained)
        case .memoryStrained: return t(.insightMemoryStrained)
        case .hot: return t(.insightHot)
        case .lowBattery: return t(.insightLowBattery)
        case .gpuBusy: return t(.insightGPUBusy)
        case .calculating: return t(.insightCalculating)
        }
    }

    func thermal(_ level: ThermalLevel) -> String {
        switch level {
        case .nominal: return t(.thermalNominal)
        case .fair: return t(.thermalFair)
        case .serious: return t(.thermalSerious)
        case .critical: return t(.thermalCritical)
        }
    }

    func pressure(_ level: MemoryPressure) -> String {
        switch level {
        case .low: return t(.pressureLow)
        case .medium: return t(.pressureMedium)
        case .high: return t(.pressureHigh)
        }
    }

    func health(_ raw: String?) -> String? {
        guard let raw else { return nil }
        switch raw.lowercased() {
        case "good": return t(.healthGood)
        case "fair": return t(.healthFair)
        case "poor": return t(.healthPoor)
        default: return raw
        }
    }

    private func arabic(_ key: CopyKey) -> String {
        switch key {
        case .appName: return "Status"
        case .yourBoard: return "لوحتك"
        case .boardHint: return "أبقِ ما تتابعه، وأخفِ الباقي."
        case .preparing: return "نقرأ الجهاز…"
        case .paused: return "المراقبة متوقفة"
        case .calm: return "هادئ"
        case .busy: return "يعمل"
        case .strained: return "تحت ضغط"
        case .hot: return "يسخن"
        case .lowBattery: return "البطارية منخفضة"
        case .insightCalm: return "لا شيء يحتاج انتباهك."
        case .insightCPUBusy: return "المعالج يعمل أكثر من المعتاد."
        case .insightMemoryBusy: return "الذاكرة تحت ضغط خفيف."
        case .insightCPUStrained: return "المعالج مرتفع. انظر العمليات."
        case .insightMemoryStrained: return "الذاكرة ممتلئة. أغلق ما لا تحتاجه."
        case .insightHot: return "الحرارة مرتفعة. خفف الحمل قليلاً."
        case .insightLowBattery: return "البطارية منخفضة. وصّل الشاحن."
        case .insightGPUBusy: return "الرسوميات تعمل. بقية الجهاز هادئة."
        case .insightCalculating: return "نجهّز القراءة الأولى."
        case .cpu: return "المعالج"
        case .memory: return "الذاكرة"
        case .disk: return "الأقراص"
        case .network: return "الشبكة"
        case .battery: return "البطارية"
        case .processes: return "العمليات"
        case .system: return "النظام"
        case .userTime: return "المستخدم"
        case .systemTime: return "النظام"
        case .cores: return "الأنوية"
        case .performance: return "أداء"
        case .efficiency: return "كفاءة"
        case .load: return "الحمل"
        case .gpu: return "الرسوميات"
        case .used: return "مستخدمة"
        case .apps: return "التطبيقات"
        case .wired: return "مثبتة"
        case .compressed: return "مضغوطة"
        case .cached: return "مخزّنة"
        case .free: return "حرة"
        case .pressure: return "الضغط"
        case .swap: return "الإبدال"
        case .read: return "قراءة"
        case .write: return "كتابة"
        case .down: return "وارد"
        case .up: return "صادر"
        case .charging: return "يشحن"
        case .onBatteryPower: return "على البطارية"
        case .pluggedIn: return "متصل بالطاقة"
        case .full: return "ممتلئة"
        case .calculating: return "يحسب…"
        case .remaining: return "متبقية"
        case .untilFull: return "حتى الامتلاء"
        case .cycles: return "دورات الشحن"
        case .health: return "الصحة"
        case .noBattery: return "لا توجد بطارية داخلية"
        case .uptime: return "مدة التشغيل"
        case .thermal: return "الحرارة"
        case .model: return "الجهاز"
        case .chip: return "الشريحة"
        case .os: return "النظام"
        case .computer: return "الاسم"
        case .thermalNominal: return "طبيعية"
        case .thermalFair: return "دافئة"
        case .thermalSerious: return "مرتفعة"
        case .thermalCritical: return "حرجة"
        case .pressureLow: return "منخفض"
        case .pressureMedium: return "متوسط"
        case .pressureHigh: return "مرتفع"
        case .addWidget: return "إضافة أداة"
        case .details: return "التفاصيل"
        case .settings: return "الإعدادات"
        case .pause: return "إيقاف مؤقت"
        case .resume: return "استئناف"
        case .refresh: return "تحديث"
        case .quit: return "إنهاء"
        case .launchAtLogin: return "فتح عند تسجيل الدخول"
        case .launchOn: return "يفتح وحده عند دخولك."
        case .launchOff: return "لا يفتح إلا عندما تشغّله."
        case .launchNeedsApproval: return "يحتاج موافقتك من إعدادات النظام."
        case .launchFailed: return "تعذر تفعيل الفتح التلقائي."
        case .openLoginSettings: return "فتح إعدادات الدخول"
        case .monitoring: return "المراقبة"
        case .live: return "مباشرة"
        case .manual: return "يدوية"
        case .liveHint: return "الأرقام تتحدث وحدها."
        case .manualHint: return "تبقى آخر قراءة إلى أن تحدّثها."
        case .gentleBattery: return "أخف على البطارية"
        case .showDock: return "إظهار في شريط التطبيقات"
        case .showDockHint: return "وإلا يبقى في شريط القائمة فقط."
        case .menuBar: return "شريط القائمة"
        case .menuBarIcon: return "إظهار الأيقونة"
        case .menuBarMetrics: return "ما يظهر بجانب الأيقونة"
        case .menuBarHint: return "حتى ثلاثة قراءات. الباقي داخل اللوحة."
        case .notifications: return "التنبيهات"
        case .notifyBattery: return "البطارية منخفضة"
        case .notifyThermal: return "الحرارة مرتفعة"
        case .notifyMemory: return "الذاكرة ممتلئة"
        case .batteryThreshold: return "عتبة البطارية"
        case .notificationsDenied: return "التنبيهات موقوفة من النظام."
        case .openNotificationSettings: return "فتح إعدادات التنبيه"
        case .language: return "اللغة"
        case .languageSystem: return "مثل النظام"
        case .languageArabic: return "العربية"
        case .languageEnglish: return "English"
        case .units: return "وحدات الشبكة"
        case .bytesUnit: return "بايت في الثانية"
        case .bitsUnit: return "بت في الثانية"
        case .pace: return "سرعة التحديث"
        case .paceLive: return "كل ثانية"
        case .paceBalanced: return "كل ثانيتين"
        case .paceQuiet: return "كل خمس ثوانٍ"
        case .moveUp: return "تحريك لأعلى"
        case .moveDown: return "تحريك لأسفل"
        case .hideWidget: return "إخفاء"
        case .shown: return "ظاهرة"
        case .add: return "إضافة"
        case .widgets: return "الأدوات"
        case .emptyBoard: return "لوحتك فارغة"
        case .emptyBoardHint: return "اختر ما تريد أن تراه كل يوم."
        case .allWidgetsAdded: return "كل الأدوات ظاهرة على اللوحة."
        case .copySummary: return "نسخ الحالة"
        case .copied: return "تم النسخ"
        case .searchProcesses: return "ابحث عن عملية"
        case .sortCPU: return "المعالج"
        case .sortMemory: return "الذاكرة"
        case .noProcesses: return "لا توجد عمليات ظاهرة"
        case .version: return "الإصدار"
        case .about: return "عن Status"
        case .monitorMenu: return "مراقبة"
        case .widgetCPUDetail: return "الاستخدام الآن، والدقيقة الأخيرة، وكل نواة."
        case .widgetMemoryDetail: return "ما يُستخدم فعلاً، وما هو مضغوط أو جاهز."
        case .widgetDiskDetail: return "سعة الأقراص، وسرعة القراءة والكتابة."
        case .widgetNetworkDetail: return "الوارد والصادر على الواجهة النشطة."
        case .widgetBatteryDetail: return "الشحن، الوقت المتبقي، والصحة."
        case .widgetProcessesDetail: return "ما الذي يستهلك الجهاز الآن."
        case .widgetSystemDetail: return "الجهاز، مدة التشغيل، وحالة الحرارة."
        case .topProcesses: return "أعلى العمليات"
        case .volumes: return "الأقراص"
        case .healthGood: return "جيدة"
        case .healthFair: return "مقبولة"
        case .healthPoor: return "ضعيفة"
        case .general: return "التشغيل"
        case .aboutBody: return "Status يجلس في شريط القائمة ويقرأ جهازك بهدوء. افتحه بنقرة، رتّب أدواتك، واتركه يعمل معك كل يوم."
        case .sampleEvery: return "القراءة"
        case .quitApp: return "إنهاء Status"
        case .library: return "مكتبة الأدوات"
        case .done: return "تم"
        }
    }

    private func english(_ key: CopyKey) -> String {
        switch key {
        case .appName: return "Status"
        case .yourBoard: return "Your board"
        case .boardHint: return "Keep what you look at. Hide the rest."
        case .preparing: return "Reading the machine…"
        case .paused: return "Monitoring is paused"
        case .calm: return "Calm"
        case .busy: return "Busy"
        case .strained: return "Under strain"
        case .hot: return "Running hot"
        case .lowBattery: return "Battery low"
        case .insightCalm: return "Nothing needs you right now."
        case .insightCPUBusy: return "The processor is working harder than usual."
        case .insightMemoryBusy: return "Memory is under a little pressure."
        case .insightCPUStrained: return "The processor is high. Look at the processes."
        case .insightMemoryStrained: return "Memory is full. Close what you don’t need."
        case .insightHot: return "The machine is hot. Ease the load a little."
        case .insightLowBattery: return "The battery is low. Plug in soon."
        case .insightGPUBusy: return "Graphics are working. The rest of the Mac is quiet."
        case .insightCalculating: return "Taking the first reading."
        case .cpu: return "Processor"
        case .memory: return "Memory"
        case .disk: return "Disks"
        case .network: return "Network"
        case .battery: return "Battery"
        case .processes: return "Processes"
        case .system: return "System"
        case .userTime: return "User"
        case .systemTime: return "System"
        case .cores: return "Cores"
        case .performance: return "Performance"
        case .efficiency: return "Efficiency"
        case .load: return "Load"
        case .gpu: return "Graphics"
        case .used: return "Used"
        case .apps: return "Apps"
        case .wired: return "Wired"
        case .compressed: return "Compressed"
        case .cached: return "Cached"
        case .free: return "Free"
        case .pressure: return "Pressure"
        case .swap: return "Swap"
        case .read: return "Read"
        case .write: return "Write"
        case .down: return "Down"
        case .up: return "Up"
        case .charging: return "Charging"
        case .onBatteryPower: return "On battery"
        case .pluggedIn: return "Plugged in"
        case .full: return "Full"
        case .calculating: return "Calculating…"
        case .remaining: return "left"
        case .untilFull: return "until full"
        case .cycles: return "Cycles"
        case .health: return "Health"
        case .noBattery: return "No internal battery"
        case .uptime: return "Uptime"
        case .thermal: return "Thermal"
        case .model: return "Mac"
        case .chip: return "Chip"
        case .os: return "macOS"
        case .computer: return "Name"
        case .thermalNominal: return "Nominal"
        case .thermalFair: return "Warm"
        case .thermalSerious: return "Hot"
        case .thermalCritical: return "Critical"
        case .pressureLow: return "Low"
        case .pressureMedium: return "Medium"
        case .pressureHigh: return "High"
        case .addWidget: return "Add widget"
        case .details: return "Details"
        case .settings: return "Settings"
        case .pause: return "Pause"
        case .resume: return "Resume"
        case .refresh: return "Refresh"
        case .quit: return "Quit"
        case .launchAtLogin: return "Open at login"
        case .launchOn: return "Opens by itself when you sign in."
        case .launchOff: return "Stays closed until you open it."
        case .launchNeedsApproval: return "macOS needs your approval in System Settings."
        case .launchFailed: return "Couldn’t turn on opening at login."
        case .openLoginSettings: return "Open Login Items"
        case .monitoring: return "Monitoring"
        case .live: return "Live"
        case .manual: return "Manual"
        case .liveHint: return "Numbers keep themselves current."
        case .manualHint: return "The last reading stays until you refresh."
        case .gentleBattery: return "Gentler on battery"
        case .showDock: return "Show in the Dock"
        case .showDockHint: return "Otherwise it lives only in the menu bar."
        case .menuBar: return "Menu bar"
        case .menuBarIcon: return "Show the icon"
        case .menuBarMetrics: return "Readings beside the icon"
        case .menuBarHint: return "Up to three. Everything else stays on the board."
        case .notifications: return "Notifications"
        case .notifyBattery: return "Low battery"
        case .notifyThermal: return "High temperature"
        case .notifyMemory: return "Memory is full"
        case .batteryThreshold: return "Battery threshold"
        case .notificationsDenied: return "Notifications are off in System Settings."
        case .openNotificationSettings: return "Open Notification Settings"
        case .language: return "Language"
        case .languageSystem: return "Match the system"
        case .languageArabic: return "العربية"
        case .languageEnglish: return "English"
        case .units: return "Network units"
        case .bytesUnit: return "Bytes per second"
        case .bitsUnit: return "Bits per second"
        case .pace: return "Refresh"
        case .paceLive: return "Every second"
        case .paceBalanced: return "Every 2 seconds"
        case .paceQuiet: return "Every 5 seconds"
        case .moveUp: return "Move up"
        case .moveDown: return "Move down"
        case .hideWidget: return "Hide"
        case .shown: return "On the board"
        case .add: return "Add"
        case .widgets: return "Widgets"
        case .emptyBoard: return "Your board is empty"
        case .emptyBoardHint: return "Choose what you want to see every day."
        case .allWidgetsAdded: return "Every widget is already on the board."
        case .copySummary: return "Copy status"
        case .copied: return "Copied"
        case .searchProcesses: return "Find a process"
        case .sortCPU: return "Processor"
        case .sortMemory: return "Memory"
        case .noProcesses: return "No processes to show"
        case .version: return "Version"
        case .about: return "About Status"
        case .monitorMenu: return "Monitor"
        case .widgetCPUDetail: return "Usage now, the last minute, and every core."
        case .widgetMemoryDetail: return "What is actually in use, compressed, or ready."
        case .widgetDiskDetail: return "Capacity, plus read and write speed."
        case .widgetNetworkDetail: return "Download and upload on the active interface."
        case .widgetBatteryDetail: return "Charge, time remaining, and health."
        case .widgetProcessesDetail: return "What is using the machine right now."
        case .widgetSystemDetail: return "The Mac, how long it has been up, and heat."
        case .topProcesses: return "Top processes"
        case .volumes: return "Volumes"
        case .healthGood: return "Good"
        case .healthFair: return "Fair"
        case .healthPoor: return "Poor"
        case .general: return "Startup"
        case .aboutBody: return "Status lives in the menu bar and reads your Mac quietly. Click it, arrange the instruments you care about, and leave it running."
        case .sampleEvery: return "Reading"
        case .quitApp: return "Quit Status"
        case .library: return "Widget library"
        case .done: return "Done"
        }
    }
}

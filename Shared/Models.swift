import Foundation

enum WidgetKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case cpu
    case memory
    case disk
    case network
    case battery
    case processes
    case system

    var id: String { rawValue }
}

enum MenuBarMetric: String, Codable, CaseIterable, Identifiable, Sendable {
    case cpu
    case memory
    case battery
    case network
    case disk

    var id: String { rawValue }
}

enum RefreshPace: String, Codable, CaseIterable, Identifiable, Sendable {
    case live
    case balanced
    case quiet

    var id: String { rawValue }
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable, Sendable {
    case system
    case arabic
    case english

    var id: String { rawValue }
}

enum NetworkUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case bytes
    case bits

    var id: String { rawValue }
}

enum MachineMood: String, Equatable, Sendable {
    case calm
    case busy
    case strained
    case hot
    case lowBattery
}

enum Insight: String, Equatable, Sendable {
    case calm
    case cpuBusy
    case memoryBusy
    case cpuStrained
    case memoryStrained
    case hot
    case lowBattery
    case gpuBusy
    case calculating
}

enum MemoryPressure: String, Equatable, Sendable {
    case low
    case medium
    case high
}

enum ThermalLevel: String, Equatable, Sendable {
    case nominal
    case fair
    case serious
    case critical
}

struct CPUTicks: Equatable, Sendable {
    var user: UInt32
    var system: UInt32
    var idle: UInt32
    var nice: UInt32

    static let zero = CPUTicks(user: 0, system: 0, idle: 0, nice: 0)

    var total: UInt32 { user &+ system &+ idle &+ nice }
}

struct CPUUsage: Equatable, Sendable {
    var total: Double
    var user: Double
    var system: Double
}

struct CPUSnapshot: Equatable, Sendable {
    var usage: Double
    var user: Double
    var system: Double
    var cores: [Double]
    var performanceCoreCount: Int
    var efficiencyCoreCount: Int
    var loadAverage: [Double]
    var gpuUsage: Double?
}

struct MemorySnapshot: Equatable, Sendable {
    var total: UInt64
    var used: UInt64
    var apps: UInt64
    var wired: UInt64
    var compressed: UInt64
    var cached: UInt64
    var free: UInt64
    var swapUsed: UInt64
    var pressure: MemoryPressure

    var usedFraction: Double {
        guard total > 0 else { return 0 }
        return min(1, Double(used) / Double(total))
    }
}

struct MemoryInput: Equatable, Sendable {
    var total: UInt64
    var pageSize: UInt64
    var internalPages: UInt64
    var purgeablePages: UInt64
    var wiredPages: UInt64
    var compressedPages: UInt64
    var externalPages: UInt64
    var freePages: UInt64
    var swapUsed: UInt64
}

struct DiskVolume: Equatable, Identifiable, Sendable {
    var id: String { mount }
    var name: String
    var mount: String
    var total: UInt64
    var available: UInt64

    var used: UInt64 { total > available ? total &- available : 0 }
    var usedFraction: Double {
        guard total > 0 else { return 0 }
        return min(1, Double(used) / Double(total))
    }
}

struct Throughput: Equatable, Sendable {
    var downBytesPerSecond: Double
    var upBytesPerSecond: Double

    static let zero = Throughput(downBytesPerSecond: 0, upBytesPerSecond: 0)
}

struct BatterySnapshot: Equatable, Sendable {
    var fraction: Double
    var isCharging: Bool
    var isPlugged: Bool
    var minutesRemaining: Int?
    var minutesToFull: Int?
    var health: String?
    var cycleCount: Int?
    var temperatureC: Double?
}

struct ProcessSnapshot: Equatable, Identifiable, Sendable {
    var pid: Int32
    var name: String
    var cpuFractionOfOneCore: Double
    var memory: UInt64

    var id: Int32 { pid }
}

struct SystemIdentity: Equatable, Sendable {
    var computerName: String
    var marketingName: String
    var modelIdentifier: String
    var chip: String
    var osVersion: String
    var physicalMemory: UInt64
}

struct MetricHistory: Equatable, Sendable {
    var cpu: [Double] = []
    var memory: [Double] = []
    var netDown: [Double] = []
    var netUp: [Double] = []
    var diskRead: [Double] = []
    var diskWrite: [Double] = []

    static let capacity = 180

    mutating func append(
        cpu cpuValue: Double,
        memory memoryValue: Double,
        netDown netDownValue: Double,
        netUp netUpValue: Double,
        diskRead diskReadValue: Double,
        diskWrite diskWriteValue: Double
    ) {
        func push(_ values: inout [Double], _ value: Double) {
            let clean = value.isFinite ? max(0, value) : 0
            values.append(clean)
            if values.count > MetricHistory.capacity {
                values.removeFirst(values.count - MetricHistory.capacity)
            }
        }
        push(&cpu, cpuValue)
        push(&memory, memoryValue)
        push(&netDown, netDownValue)
        push(&netUp, netUpValue)
        push(&diskRead, diskReadValue)
        push(&diskWrite, diskWriteValue)
    }
}

struct SystemSnapshot: Equatable, Sendable {
    var capturedAt: Date
    var cpu: CPUSnapshot
    var memory: MemorySnapshot
    var disks: [DiskVolume]
    var diskIO: Throughput
    var network: Throughput
    var networkInterface: String?
    var ipv4: String?
    var battery: BatterySnapshot?
    var processes: [ProcessSnapshot]
    var thermal: ThermalLevel
    var identity: SystemIdentity
    var uptime: TimeInterval
    var history: MetricHistory
    var mood: MachineMood
    var insight: Insight

    static var empty: SystemSnapshot {
        let identity = SystemIdentity(
            computerName: "Mac",
            marketingName: "Mac",
            modelIdentifier: "",
            chip: "",
            osVersion: "",
            physicalMemory: 0
        )
        let cpu = CPUSnapshot(
            usage: 0, user: 0, system: 0, cores: [],
            performanceCoreCount: 0, efficiencyCoreCount: 0,
            loadAverage: [], gpuUsage: nil
        )
        let memory = MemorySnapshot(
            total: 0, used: 0, apps: 0, wired: 0, compressed: 0,
            cached: 0, free: 0, swapUsed: 0, pressure: .low
        )
        return SystemSnapshot(
            capturedAt: Date(),
            cpu: cpu,
            memory: memory,
            disks: [],
            diskIO: .zero,
            network: .zero,
            networkInterface: nil,
            ipv4: nil,
            battery: nil,
            processes: [],
            thermal: .nominal,
            identity: identity,
            uptime: 0,
            history: MetricHistory(),
            mood: .calm,
            insight: .calculating
        )
    }
}

struct PaceInput: Equatable, Sendable {
    var refresh: RefreshPace
    var gentleOnBattery: Bool
    var onBattery: Bool
    var lowPowerMode: Bool
}

struct AppSettings: Codable, Equatable, Sendable {
    var widgets: [WidgetKind]
    var menuBarMetrics: [MenuBarMetric]
    var showMenuBarIcon: Bool
    var launchAtLogin: Bool
    var monitoringEnabled: Bool
    var refresh: RefreshPace
    var gentleOnBattery: Bool
    var showDock: Bool
    var language: AppLanguage
    var networkUnit: NetworkUnit
    var notifyLowBattery: Bool
    var notifyThermal: Bool
    var notifyMemory: Bool
    var lowBatteryThreshold: Double

    private enum CodingKeys: String, CodingKey {
        case widgets
        case menuBarMetrics
        case showMenuBarIcon
        case launchAtLogin
        case monitoringEnabled
        case refresh
        case gentleOnBattery
        case showDock
        case language
        case networkUnit
        case notifyLowBattery
        case notifyThermal
        case notifyMemory
        case lowBatteryThreshold
    }

    static let standard = AppSettings(
        widgets: [.cpu, .memory, .network, .battery, .processes],
        menuBarMetrics: [.cpu],
        showMenuBarIcon: true,
        launchAtLogin: false,
        monitoringEnabled: true,
        refresh: .live,
        gentleOnBattery: true,
        showDock: false,
        language: .system,
        networkUnit: .bytes,
        notifyLowBattery: true,
        notifyThermal: true,
        notifyMemory: false,
        lowBatteryThreshold: 0.2
    )

    static func normalized(_ settings: AppSettings) -> AppSettings {
        var copy = settings
        var seenWidgets = Set<WidgetKind>()
        copy.widgets = copy.widgets.filter { seenWidgets.insert($0).inserted }
        var seenMetrics = Set<MenuBarMetric>()
        copy.menuBarMetrics = Array(
            copy.menuBarMetrics.filter { seenMetrics.insert($0).inserted }.prefix(3)
        )
        if copy.menuBarMetrics.isEmpty && !copy.showMenuBarIcon {
            copy.showMenuBarIcon = true
        }
        if !copy.lowBatteryThreshold.isFinite {
            copy.lowBatteryThreshold = 0.2
        }
        copy.lowBatteryThreshold = min(max(copy.lowBatteryThreshold, 0.05), 0.5)
        return copy
    }

    init(
        widgets: [WidgetKind],
        menuBarMetrics: [MenuBarMetric],
        showMenuBarIcon: Bool,
        launchAtLogin: Bool,
        monitoringEnabled: Bool,
        refresh: RefreshPace,
        gentleOnBattery: Bool,
        showDock: Bool,
        language: AppLanguage,
        networkUnit: NetworkUnit,
        notifyLowBattery: Bool,
        notifyThermal: Bool,
        notifyMemory: Bool,
        lowBatteryThreshold: Double
    ) {
        self.widgets = widgets
        self.menuBarMetrics = menuBarMetrics
        self.showMenuBarIcon = showMenuBarIcon
        self.launchAtLogin = launchAtLogin
        self.monitoringEnabled = monitoringEnabled
        self.refresh = refresh
        self.gentleOnBattery = gentleOnBattery
        self.showDock = showDock
        self.language = language
        self.networkUnit = networkUnit
        self.notifyLowBattery = notifyLowBattery
        self.notifyThermal = notifyThermal
        self.notifyMemory = notifyMemory
        self.lowBatteryThreshold = lowBatteryThreshold
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base = AppSettings.standard
        let widgets: [WidgetKind]
        if container.contains(.widgets) {
            let raw = try container.decode([String].self, forKey: .widgets)
            widgets = raw.compactMap(WidgetKind.init(rawValue:))
        } else {
            widgets = base.widgets
        }
        let menuBarMetrics: [MenuBarMetric]
        if container.contains(.menuBarMetrics) {
            let raw = try container.decode([String].self, forKey: .menuBarMetrics)
            menuBarMetrics = raw.compactMap(MenuBarMetric.init(rawValue:))
        } else {
            menuBarMetrics = base.menuBarMetrics
        }
        let decoded = AppSettings(
            widgets: widgets,
            menuBarMetrics: menuBarMetrics,
            showMenuBarIcon: try container.decodeIfPresent(Bool.self, forKey: .showMenuBarIcon) ?? base.showMenuBarIcon,
            launchAtLogin: try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? base.launchAtLogin,
            monitoringEnabled: try container.decodeIfPresent(Bool.self, forKey: .monitoringEnabled) ?? base.monitoringEnabled,
            refresh: try container.decodeIfPresent(RefreshPace.self, forKey: .refresh) ?? base.refresh,
            gentleOnBattery: try container.decodeIfPresent(Bool.self, forKey: .gentleOnBattery) ?? base.gentleOnBattery,
            showDock: try container.decodeIfPresent(Bool.self, forKey: .showDock) ?? base.showDock,
            language: try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? base.language,
            networkUnit: try container.decodeIfPresent(NetworkUnit.self, forKey: .networkUnit) ?? base.networkUnit,
            notifyLowBattery: try container.decodeIfPresent(Bool.self, forKey: .notifyLowBattery) ?? base.notifyLowBattery,
            notifyThermal: try container.decodeIfPresent(Bool.self, forKey: .notifyThermal) ?? base.notifyThermal,
            notifyMemory: try container.decodeIfPresent(Bool.self, forKey: .notifyMemory) ?? base.notifyMemory,
            lowBatteryThreshold: try container.decodeIfPresent(Double.self, forKey: .lowBatteryThreshold) ?? base.lowBatteryThreshold
        )
        self = AppSettings.normalized(decoded)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(widgets.map(\.rawValue), forKey: .widgets)
        try container.encode(menuBarMetrics.map(\.rawValue), forKey: .menuBarMetrics)
        try container.encode(showMenuBarIcon, forKey: .showMenuBarIcon)
        try container.encode(launchAtLogin, forKey: .launchAtLogin)
        try container.encode(monitoringEnabled, forKey: .monitoringEnabled)
        try container.encode(refresh, forKey: .refresh)
        try container.encode(gentleOnBattery, forKey: .gentleOnBattery)
        try container.encode(showDock, forKey: .showDock)
        try container.encode(language, forKey: .language)
        try container.encode(networkUnit, forKey: .networkUnit)
        try container.encode(notifyLowBattery, forKey: .notifyLowBattery)
        try container.encode(notifyThermal, forKey: .notifyThermal)
        try container.encode(notifyMemory, forKey: .notifyMemory)
        try container.encode(lowBatteryThreshold, forKey: .lowBatteryThreshold)
    }
}

enum BoardEditing {
    static func add(_ kind: WidgetKind, to widgets: [WidgetKind]) -> [WidgetKind] {
        widgets.contains(kind) ? widgets : widgets + [kind]
    }

    static func remove(_ kind: WidgetKind, from widgets: [WidgetKind]) -> [WidgetKind] {
        widgets.filter { $0 != kind }
    }

    static func move(_ kind: WidgetKind, by offset: Int, in widgets: [WidgetKind]) -> [WidgetKind] {
        guard let index = widgets.firstIndex(of: kind) else { return widgets }
        let target = index + offset
        guard widgets.indices.contains(target) else { return widgets }
        var copy = widgets
        copy.remove(at: index)
        copy.insert(kind, at: target)
        return copy
    }

    static func toggle(_ metric: MenuBarMetric, in metrics: [MenuBarMetric], limit: Int = 3) -> [MenuBarMetric] {
        if let index = metrics.firstIndex(of: metric) {
            var copy = metrics
            copy.remove(at: index)
            return copy
        }
        guard metrics.count < limit else { return metrics }
        return metrics + [metric]
    }
}

struct SampleOptions: Sendable {
    var includeProcesses: Bool
    var processLimit: Int

    static let live = SampleOptions(includeProcesses: true, processLimit: 8)
    static let quiet = SampleOptions(includeProcesses: false, processLimit: 0)
    static let widget = SampleOptions(includeProcesses: false, processLimit: 0)
}

import Foundation

enum MetricMath {
    static func cpuUsage(previous: CPUTicks, current: CPUTicks) -> CPUUsage? {
        let user = current.user &- previous.user
        let system = current.system &- previous.system
        let idle = current.idle &- previous.idle
        let nice = current.nice &- previous.nice
        let total = user &+ system &+ idle &+ nice
        guard total > 0 else { return nil }
        let userShare = Double(user &+ nice) / Double(total)
        let systemShare = Double(system) / Double(total)
        return CPUUsage(total: userShare + systemShare, user: userShare, system: systemShare)
    }

    static func memorySnapshot(_ input: MemoryInput) -> MemorySnapshot {
        let page = max(input.pageSize, 1)
        let appsPages = input.internalPages > input.purgeablePages
            ? input.internalPages - input.purgeablePages
            : 0
        let apps = appsPages * page
        let wired = input.wiredPages * page
        let compressed = input.compressedPages * page
        let total = input.total
        var used = apps + wired + compressed
        if total > 0 {
            used = min(used, total)
        }
        let cachedRaw = (input.externalPages + input.purgeablePages) * page
        let room = total > used ? total - used : 0
        let cached = min(cachedRaw, room)
        let freeRoom = total > used + cached ? total - used - cached : 0
        let freeReported = input.freePages * page
        let free = total > 0 ? freeRoom : freeReported
        return MemorySnapshot(
            total: total,
            used: used,
            apps: min(apps, used),
            wired: min(wired, used),
            compressed: min(compressed, used),
            cached: cached,
            free: free,
            swapUsed: input.swapUsed,
            pressure: pressure(free: free, cached: cached, compressed: compressed, total: total)
        )
    }

    static func pressure(free: UInt64, cached: UInt64, compressed: UInt64, total: UInt64) -> MemoryPressure {
        guard total > 0 else { return .low }
        let available = Double(free &+ cached) / Double(total)
        let compress = Double(compressed) / Double(total)
        if available < 0.08 || compress > 0.35 { return .high }
        if available < 0.18 || compress > 0.20 { return .medium }
        return .low
    }

    static func ratePerSecond(
        previous: UInt64,
        current: UInt64,
        elapsed: TimeInterval,
        maxElapsed: TimeInterval = 8
    ) -> Double {
        guard elapsed > 0.05 else { return 0 }
        guard elapsed <= maxElapsed else { return 0 }
        guard current >= previous else { return 0 }
        return Double(current - previous) / elapsed
    }

    /// Fraction of a single core. 1.0 is 100% of one core, matching Activity Monitor.
    static func processCPUFraction(previousNanos: UInt64, currentNanos: UInt64, elapsedNanos: UInt64) -> Double {
        guard elapsedNanos > 0, currentNanos >= previousNanos else { return 0 }
        let used = currentNanos - previousNanos
        let fraction = Double(used) / Double(elapsedNanos)
        guard fraction.isFinite else { return 0 }
        return min(fraction, 64)
    }

    static func sampleInterval(_ input: PaceInput) -> TimeInterval {
        let base: TimeInterval
        switch input.refresh {
        case .live: base = 1
        case .balanced: base = 2
        case .quiet: base = 5
        }
        if input.lowPowerMode || (input.gentleOnBattery && input.onBattery) {
            return max(base, 2)
        }
        return base
    }

    static func assess(
        cpu: Double,
        gpu: Double?,
        memory: MemoryPressure,
        thermal: ThermalLevel,
        battery: BatterySnapshot?
    ) -> (MachineMood, Insight) {
        if thermal == .serious || thermal == .critical {
            return (.hot, .hot)
        }
        if let battery, !battery.isPlugged, battery.fraction < 0.15 {
            return (.lowBattery, .lowBattery)
        }
        if cpu >= 0.85 {
            return (.strained, .cpuStrained)
        }
        if memory == .high {
            return (.strained, .memoryStrained)
        }
        if let gpu, gpu >= 0.7 {
            return (.busy, .gpuBusy)
        }
        if cpu >= 0.55 {
            return (.busy, .cpuBusy)
        }
        if memory == .medium {
            return (.busy, .memoryBusy)
        }
        return (.calm, .calm)
    }

    static func batteryCelsius(raw: Double) -> Double? {
        guard raw.isFinite, raw > 0 else { return nil }
        let fromDeciKelvin = raw / 10.0 - 273.15
        if (0...90).contains(fromDeciKelvin) { return fromDeciKelvin }
        let fromDeciCelsius = raw / 10.0
        if (10...90).contains(fromDeciCelsius) { return fromDeciCelsius }
        return nil
    }
}

struct MenuBarModel: Equatable, Sendable {
    var title: String
    var toolTip: String
    var symbolName: String
    var showsSparkline: Bool
    var sparkline: [Double]
    var accessibility: String
}

enum MenuBarComposer {
    static func model(
        snapshot: SystemSnapshot?,
        settings: AppSettings,
        paused: Bool,
        arabic: Bool,
        insight: String
    ) -> MenuBarModel {
        guard let snapshot else {
            return MenuBarModel(
                title: settings.showMenuBarIcon ? "" : "…",
                toolTip: insight,
                symbolName: "waveform.path.ecg",
                showsSparkline: false,
                sparkline: [],
                accessibility: insight
            )
        }

        let metrics = settings.menuBarMetrics
        let parts = metrics.map { text(for: $0, snapshot: snapshot, unit: settings.networkUnit) }
        var title = parts.joined(separator: "  ·  ")
        if paused {
            title = title.isEmpty ? (arabic ? "متوقف" : "Paused") : title
        }

        let symbol: String
        if paused {
            symbol = "pause.circle"
        } else {
            switch snapshot.mood {
            case .calm: symbol = "waveform.path.ecg"
            case .busy: symbol = "chart.bar"
            case .strained: symbol = "exclamationmark.circle"
            case .hot: symbol = "thermometer.medium"
            case .lowBattery: symbol = "battery.25percent"
            }
        }

        let singleGraph = metrics.count == 1 && (metrics.first == .cpu || metrics.first == .memory)
        let series = metrics.first == .memory ? snapshot.history.memory : snapshot.history.cpu
        let showSpark = !paused && settings.showMenuBarIcon == false ? false : singleGraph && series.count >= 2 && !paused
        let useSparkAsIcon = showSpark && metrics.count == 1

        return MenuBarModel(
            title: title,
            toolTip: insight,
            symbolName: symbol,
            showsSparkline: useSparkAsIcon,
            sparkline: useSparkAsIcon ? series : [],
            accessibility: insight + (title.isEmpty ? "" : " " + title)
        )
    }

    private static func text(for metric: MenuBarMetric, snapshot: SystemSnapshot, unit: NetworkUnit) -> String {
        switch metric {
        case .cpu:
            return Format.percent(snapshot.cpu.usage)
        case .memory:
            return Format.percent(snapshot.memory.usedFraction)
        case .battery:
            guard let battery = snapshot.battery else { return "AC" }
            return Format.percent(battery.fraction)
        case .network:
            let down = Format.menuRate(snapshot.network.downBytesPerSecond, unit: unit)
            return "↓\(down)"
        case .disk:
            let read = Format.menuRate(snapshot.diskIO.downBytesPerSecond, unit: .bytes)
            return "R\(read)"
        }
    }
}

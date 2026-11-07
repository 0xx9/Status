import SwiftUI

enum BoardStyle {
    case compact
    case expanded
}

struct BoardWidget: View {
    var kind: WidgetKind
    var style: BoardStyle
    @EnvironmentObject private var monitor: Monitor
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.colorScheme) private var scheme

    private var l10n: L10n { settings.l10n }
    private var arabic: Bool { l10n.isArabic }
    private var snapshot: SystemSnapshot? { monitor.snapshot }

    var body: some View {
        Group {
            if style == .compact {
                compact
            } else {
                expanded
            }
        }
    }

    @ViewBuilder
    private var compact: some View {
        HStack(alignment: .center, spacing: 12) {
            compactBody
            menu
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Palette.stroke, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var compactBody: some View {
        switch kind {
        case .cpu: cpuCompact
        case .memory: memoryCompact
        case .disk: diskCompact
        case .network: networkCompact
        case .battery: batteryCompact
        case .processes: processesCompact
        case .system: systemCompact
        }
    }

    private var expanded: some View {
        InstrumentCard(title: l10n.widgetTitle(kind), symbol: symbol) {
            switch kind {
            case .cpu: cpuExpanded
            case .memory: memoryExpanded
            case .disk: diskExpanded
            case .network: networkExpanded
            case .battery: batteryExpanded
            case .processes: processesExpanded
            case .system: systemExpanded
            }
        }
        .overlay(alignment: .topTrailing) {
            menu.padding(12)
        }
    }

    private var symbol: String {
        switch kind {
        case .cpu: return "cpu"
        case .memory: return "memorychip"
        case .disk: return "internaldrive"
        case .network: return "arrow.up.arrow.down"
        case .battery: return "battery.100percent"
        case .processes: return "list.bullet.rectangle"
        case .system: return "macwindow"
        }
    }

    private var menu: some View {
        let widgets = settings.settings.widgets
        let index = widgets.firstIndex(of: kind) ?? 0
        return WidgetMenu(
            canMoveUp: index > 0,
            canMoveDown: index < widgets.count - 1,
            upTitle: l10n.t(.moveUp),
            downTitle: l10n.t(.moveDown),
            hideTitle: l10n.t(.hideWidget),
            moveUp: { settings.move(kind, by: -1) },
            moveDown: { settings.move(kind, by: 1) },
            hide: { settings.remove(kind) }
        )
    }

    private var tone: Color {
        Palette.mood(snapshot?.mood ?? .calm, scheme: scheme)
    }

    private var cpuCompact: some View {
        let cpu = snapshot?.cpu
        return HStack(spacing: 12) {
            ring(cpu?.usage ?? 0, text: Format.percentNumber(cpu?.usage ?? 0))
            VStack(alignment: .leading, spacing: 6) {
                titleRow(l10n.t(.cpu), trailing: Format.percent(cpu?.usage ?? 0, digits: cpu == nil ? 0 : 1))
                Sparkline(values: snapshot?.history.cpu ?? [], color: tone)
                    .frame(height: 22)
                caption(coreCaption)
            }
        }
    }

    private var cpuExpanded: some View {
        let cpu = snapshot?.cpu ?? .init(usage: 0, user: 0, system: 0, cores: [], performanceCoreCount: 0, efficiencyCoreCount: 0, loadAverage: [], gpuUsage: nil)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Figure(value: Format.percentNumber(cpu.usage, digits: 1), unit: "%", size: 42, color: tone)
                Spacer()
                if let gpu = cpu.gpuUsage {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(l10n.t(.gpu))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.tertiary)
                        Text(Format.percent(gpu))
                            .figureFont(16)
                    }
                }
            }
            splitBar(user: cpu.user, system: cpu.system)
            HStack {
                caption("\(l10n.t(.userTime)) \(Format.percent(cpu.user))")
                Spacer()
                caption("\(l10n.t(.systemTime)) \(Format.percent(cpu.system))")
            }
            Sparkline(values: snapshot?.history.cpu ?? [], color: tone)
                .frame(height: 64)
            if !cpu.cores.isEmpty {
                CoreBars(cores: cpu.cores, performanceCount: cpu.performanceCoreCount, color: tone)
                HStack {
                    if cpu.performanceCoreCount > 0 {
                        caption("\(l10n.t(.performance)) \(cpu.performanceCoreCount)")
                    }
                    if cpu.efficiencyCoreCount > 0 {
                        caption("\(l10n.t(.efficiency)) \(cpu.efficiencyCoreCount)")
                    }
                    Spacer()
                    if cpu.loadAverage.count == 3 {
                        caption("\(l10n.t(.load)) \(loadText(cpu.loadAverage))")
                    }
                }
            }
        }
    }

    private var memoryCompact: some View {
        let memory = snapshot?.memory
        return HStack(spacing: 12) {
            ring(memory?.usedFraction ?? 0, text: Format.percentNumber(memory?.usedFraction ?? 0))
            VStack(alignment: .leading, spacing: 6) {
                titleRow(l10n.t(.memory), trailing: Format.percent(memory?.usedFraction ?? 0))
                Sparkline(values: snapshot?.history.memory ?? [], color: tone)
                    .frame(height: 22)
                caption(memoryCaption)
            }
        }
    }

    private var memoryExpanded: some View {
        let memory = snapshot?.memory
        let total = Double(memory?.total ?? 1)
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    RingMeter(progress: memory?.usedFraction ?? 0, color: tone, lineWidth: 9)
                    Figure(value: Format.percentNumber(memory?.usedFraction ?? 0), unit: "%", size: 18, color: tone)
                }
                .frame(width: 84, height: 84)
                VStack(alignment: .leading, spacing: 8) {
                    memoryRow(.apps, bytes: memory?.apps ?? 0, share: share(memory?.apps ?? 0, total: total), opacity: 1)
                    memoryRow(.wired, bytes: memory?.wired ?? 0, share: share(memory?.wired ?? 0, total: total), opacity: 0.72)
                    memoryRow(.compressed, bytes: memory?.compressed ?? 0, share: share(memory?.compressed ?? 0, total: total), opacity: 0.48)
                    memoryRow(.cached, bytes: memory?.cached ?? 0, share: share(memory?.cached ?? 0, total: total), opacity: 0.28)
                }
            }
            if let memory, memory.swapUsed > 0 {
                caption("\(l10n.t(.swap)) \(Format.bytes(memory.swapUsed, base: .binary, arabic: arabic).joined)")
            }
            HStack {
                caption("\(l10n.t(.pressure)) \(l10n.pressure(memory?.pressure ?? .low))")
                Spacer()
                caption("\(l10n.t(.free)) \(Format.bytes(memory?.free ?? 0, base: .binary, arabic: arabic).joined)")
            }
        }
    }

    private var diskCompact: some View {
        VStack(alignment: .leading, spacing: 8) {
            titleRow(l10n.t(.disk), trailing: diskRate)
            if let volume = snapshot?.disks.first {
                UsageBar(fraction: volume.usedFraction, color: tone)
                caption("\(volume.name) · \(Format.bytes(volume.available, base: .decimal, arabic: arabic).joined) \(l10n.t(.free))")
            } else {
                caption(l10n.t(.preparing))
            }
        }
    }

    private var diskExpanded: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                rateBlock(l10n.t(.read), snapshot?.diskIO.downBytesPerSecond ?? 0)
                Spacer()
                rateBlock(l10n.t(.write), snapshot?.diskIO.upBytesPerSecond ?? 0)
            }
            Sparkline(values: snapshot?.history.diskRead ?? [], color: tone, peakScale: true)
                .frame(height: 36)
            ForEach(snapshot?.disks ?? []) { volume in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(volume.name)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Text(Format.percent(volume.usedFraction))
                            .figureFont(12, weight: .medium)
                            .foregroundStyle(.secondary)
                    }
                    UsageBar(fraction: volume.usedFraction, color: tone)
                    caption("\(Format.bytes(volume.used, base: .decimal, arabic: arabic).joined) / \(Format.bytes(volume.total, base: .decimal, arabic: arabic).joined)")
                }
            }
        }
    }

    private var networkCompact: some View {
        VStack(alignment: .leading, spacing: 6) {
            titleRow(l10n.t(.network), trailing: snapshot?.networkInterface ?? "")
            HStack {
                Text("↓ \(rateText(snapshot?.network.downBytesPerSecond ?? 0))")
                    .figureFont(13)
                Spacer()
                Text("↑ \(rateText(snapshot?.network.upBytesPerSecond ?? 0))")
                    .figureFont(13)
                    .foregroundStyle(.secondary)
            }
            Sparkline(values: snapshot?.history.netDown ?? [], color: tone, peakScale: true, filled: false)
                .frame(height: 18)
        }
    }

    private var networkExpanded: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    caption("↓ \(l10n.t(.down))")
                    Figure(
                        value: Format.rate(snapshot?.network.downBytesPerSecond ?? 0, unit: settings.settings.networkUnit, arabic: arabic).value,
                        unit: Format.rate(snapshot?.network.downBytesPerSecond ?? 0, unit: settings.settings.networkUnit, arabic: arabic).unit,
                        size: 28,
                        color: tone
                    )
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    caption("↑ \(l10n.t(.up))")
                    Figure(
                        value: Format.rate(snapshot?.network.upBytesPerSecond ?? 0, unit: settings.settings.networkUnit, arabic: arabic).value,
                        unit: Format.rate(snapshot?.network.upBytesPerSecond ?? 0, unit: settings.settings.networkUnit, arabic: arabic).unit,
                        size: 28
                    )
                }
            }
            Sparkline(values: snapshot?.history.netDown ?? [], color: tone, peakScale: true)
                .frame(height: 56)
            HStack {
                if let name = snapshot?.networkInterface {
                    caption(name)
                }
                Spacer()
                if let ip = snapshot?.ipv4 {
                    caption(ip)
                }
            }
        }
    }

    private var batteryCompact: some View {
        Group {
            if let battery = snapshot?.battery {
                HStack(spacing: 12) {
                    BatteryGlyph(fraction: battery.fraction, charging: battery.isCharging, color: batteryColor(battery))
                    VStack(alignment: .leading, spacing: 4) {
                        titleRow(l10n.t(.battery), trailing: Format.percent(battery.fraction))
                        caption(batteryLine(battery))
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    titleRow(l10n.t(.battery), trailing: "AC")
                    caption(l10n.t(.noBattery))
                }
            }
        }
    }

    private var batteryExpanded: some View {
        Group {
            if let battery = snapshot?.battery {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center, spacing: 14) {
                        BatteryGlyph(fraction: battery.fraction, charging: battery.isCharging, color: batteryColor(battery))
                            .scaleEffect(1.4)
                            .frame(width: 44)
                        Figure(value: Format.percentNumber(battery.fraction), unit: "%", size: 42, color: batteryColor(battery))
                        Spacer()
                        Text(batteryState(battery))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    UsageBar(fraction: battery.fraction, color: batteryColor(battery))
                    HStack {
                        caption(batteryLine(battery))
                        Spacer()
                        if let health = l10n.health(battery.health) {
                            caption("\(l10n.t(.health)) \(health)")
                        }
                    }
                    HStack {
                        if let cycles = battery.cycleCount {
                            caption("\(l10n.t(.cycles)) \(cycles)")
                        }
                        Spacer()
                        if let temp = battery.temperatureC {
                            caption(Format.temperature(temp, arabic: arabic))
                        }
                    }
                }
            } else {
                caption(l10n.t(.noBattery))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            }
        }
    }

    private var processesCompact: some View {
        VStack(alignment: .leading, spacing: 6) {
            titleRow(l10n.t(.processes), trailing: "")
            let rows = Array((snapshot?.processes ?? []).prefix(3))
            if rows.isEmpty {
                caption(l10n.t(.preparing))
            } else {
                ForEach(rows) { process in
                    processRow(process, emphasize: false)
                }
            }
        }
    }

    private var processesExpanded: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.tertiary)
                        .font(.system(size: 12))
                    TextField(l10n.t(.searchProcesses), text: $monitor.processQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                Picker(l10n.t(.sortCPU), selection: $monitor.processSort) {
                    Text(l10n.t(.sortCPU)).tag(ProcessSort.cpu)
                    Text(l10n.t(.sortMemory)).tag(ProcessSort.memory)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            let rows = monitor.filteredProcesses
            if rows.isEmpty {
                caption(l10n.t(.noProcesses))
                    .padding(.vertical, 8)
            } else {
                ForEach(rows) { process in
                    processRow(process, emphasize: true)
                }
            }
        }
    }

    private var systemCompact: some View {
        VStack(alignment: .leading, spacing: 6) {
            titleRow(l10n.t(.system), trailing: snapshot.map { l10n.thermal($0.thermal) } ?? "")
            caption(machineLine)
            caption("\(l10n.t(.uptime)) \(Format.uptime(snapshot?.uptime ?? 0, arabic: arabic))")
        }
    }

    private var systemExpanded: some View {
        let identity = snapshot?.identity
        return VStack(alignment: .leading, spacing: 10) {
            fact(l10n.t(.computer), identity?.computerName ?? "—")
            fact(l10n.t(.model), identity?.marketingName ?? "—")
            fact(l10n.t(.chip), identity?.chip ?? "—")
            fact(l10n.t(.os), identity?.osVersion ?? "—")
            fact(l10n.t(.uptime), Format.uptime(snapshot?.uptime ?? 0, arabic: arabic))
            fact(l10n.t(.thermal), snapshot.map { l10n.thermal($0.thermal) } ?? "—")
            fact(l10n.t(.memory), Format.bytes(identity?.physicalMemory ?? 0, base: .binary, arabic: arabic).joined)
            fact(l10n.t(.sampleEvery), paceText)
        }
    }

    private func ring(_ progress: Double, text: String) -> some View {
        ZStack {
            RingMeter(progress: progress, color: tone, lineWidth: 5)
            Text(text)
                .figureFont(11)
                .foregroundStyle(tone)
        }
        .frame(width: 46, height: 46)
    }

    private func titleRow(_ title: String, trailing: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            Spacer(minLength: 8)
            if !trailing.isEmpty {
                Text(trailing)
                    .figureFont(12, weight: .medium)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    private func fact(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 92, alignment: .leading)
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
    }

    private func processRow(_ process: ProcessSnapshot, emphasize: Bool) -> some View {
        HStack(spacing: 8) {
            Text(process.name)
                .font(.system(size: emphasize ? 13 : 12, weight: .medium))
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(Format.bytes(process.memory, base: .binary, arabic: arabic).joined)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .frame(width: emphasize ? 72 : 58, alignment: .trailing)
            Text(Format.corePercent(process.cpuFractionOfOneCore))
                .figureFont(12, weight: .semibold)
                .foregroundStyle(tone)
                .frame(width: 48, alignment: .trailing)
        }
    }

    private func memoryRow(_ key: CopyKey, bytes: UInt64, share: Double, opacity: Double) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tone.opacity(opacity))
                .frame(width: 7, height: 7)
            Text(l10n.t(key))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            UsageBar(fraction: share, color: tone.opacity(opacity))
            Text(Format.bytes(bytes, base: .binary, arabic: arabic).joined)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .trailing)
        }
    }

    private func splitBar(user: Double, system: Double) -> some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                Capsule().fill(tone).frame(width: geometry.size.width * CGFloat(min(max(user, 0), 1)))
                Capsule().fill(tone.opacity(0.45)).frame(width: geometry.size.width * CGFloat(min(max(system, 0), 1)))
                Capsule().fill(Color.primary.opacity(0.06))
            }
        }
        .frame(height: 6)
    }

    private func rateBlock(_ title: String, _ bytes: Double) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            caption(title)
            Text(rateText(bytes))
                .figureFont(16)
        }
    }

    private func rateText(_ bytes: Double) -> String {
        Format.rate(bytes, unit: settings.settings.networkUnit, arabic: arabic).joined
    }

    private var diskRate: String {
        let read = Format.menuRate(snapshot?.diskIO.downBytesPerSecond ?? 0, unit: .bytes)
        return "↓\(read)"
    }

    private var memoryCaption: String {
        guard let memory = snapshot?.memory else { return l10n.t(.preparing) }
        let used = Format.bytes(memory.used, base: .binary, arabic: arabic).joined
        let total = Format.bytes(memory.total, base: .binary, arabic: arabic).joined
        return "\(used) / \(total) · \(l10n.pressure(memory.pressure))"
    }

    private var coreCaption: String {
        guard let cpu = snapshot?.cpu else { return l10n.t(.preparing) }
        if cpu.performanceCoreCount > 0 || cpu.efficiencyCoreCount > 0 {
            return "\(l10n.t(.performance)) \(cpu.performanceCoreCount) · \(l10n.t(.efficiency)) \(cpu.efficiencyCoreCount)"
        }
        return "\(cpu.cores.count) \(l10n.t(.cores))"
    }

    private var machineLine: String {
        guard let identity = snapshot?.identity else { return l10n.t(.preparing) }
        let name = identity.marketingName.isEmpty ? identity.computerName : identity.marketingName
        if identity.chip.isEmpty { return name }
        return "\(name) · \(identity.chip)"
    }

    private var paceText: String {
        switch settings.settings.refresh {
        case .live: return l10n.t(.paceLive)
        case .balanced: return l10n.t(.paceBalanced)
        case .quiet: return l10n.t(.paceQuiet)
        }
    }

    private func batteryColor(_ battery: BatterySnapshot) -> Color {
        if !battery.isPlugged && battery.fraction < 0.2 {
            return Palette.mood(.lowBattery, scheme: scheme)
        }
        return tone
    }

    private func batteryState(_ battery: BatterySnapshot) -> String {
        if battery.isCharging { return l10n.t(.charging) }
        if battery.isPlugged && battery.fraction > 0.98 { return l10n.t(.full) }
        if battery.isPlugged { return l10n.t(.pluggedIn) }
        return l10n.t(.onBatteryPower)
    }

    private func batteryLine(_ battery: BatterySnapshot) -> String {
        if battery.isCharging, let minutes = battery.minutesToFull, minutes > 0 {
            return "\(Format.minutes(minutes, arabic: arabic)) \(l10n.t(.untilFull))"
        }
        if let minutes = battery.minutesRemaining, minutes > 0, !battery.isPlugged {
            return "\(Format.minutes(minutes, arabic: arabic)) \(l10n.t(.remaining))"
        }
        if battery.isCharging { return l10n.t(.charging) }
        if battery.isPlugged { return l10n.t(.pluggedIn) }
        return l10n.t(.calculating)
    }

    private func share(_ bytes: UInt64, total: Double) -> Double {
        guard total > 0 else { return 0 }
        return min(1, Double(bytes) / total)
    }

    private func loadText(_ values: [Double]) -> String {
        values.map { String(format: "%.2f", $0) }.joined(separator: "  ")
    }
}

struct WidgetLibrary: View {
    @EnvironmentObject private var settings: SettingsStore

    private var l10n: L10n { settings.l10n }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(WidgetKind.allCases) { kind in
                let added = settings.settings.widgets.contains(kind)
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(l10n.widgetTitle(kind))
                            .font(.system(size: 13, weight: .semibold))
                        Text(l10n.widgetDetail(kind))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Button(added ? l10n.t(.shown) : l10n.t(.add)) {
                        if added {
                            settings.remove(kind)
                        } else {
                            settings.add(kind)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(false)
                }
                .padding(10)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}

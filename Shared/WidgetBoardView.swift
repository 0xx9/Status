import SwiftUI
import WidgetKit

struct StatusWidgetFace: View {
    var payload: WidgetPayload
    var family: WidgetFamily

    @Environment(\.colorScheme) private var scheme

    private var l10n: L10n { L10n(isArabic: payload.arabic) }
    private var tone: Color { WidgetInk.color(payload.machineMood, scheme) }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                small
            case .systemLarge:
                large
            case .systemExtraLarge:
                extra
            default:
                medium
            }
        }
        .padding(family == .systemSmall ? 10 : 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 5) {
            header(compact: true)
            HStack(alignment: .center, spacing: 8) {
                WidgetRing(progress: payload.cpu, color: tone, line: 6)
                    .frame(width: 54, height: 54)
                VStack(alignment: .leading, spacing: 0) {
                    Text(figure(payload.cpu))
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(tone)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(l10n.t(.cpu))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            memoryLine
            WidgetSparkline(values: payload.cpuHistory, color: tone)
                .frame(height: 16)
        }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 10) {
            header(compact: false)
            HStack(alignment: .center, spacing: 12) {
                ringStat(payload.cpu, l10n.t(.cpu))
                ringStat(payload.memory, l10n.t(.memory))
                VStack(alignment: .leading, spacing: 6) {
                    flow("↓", payload.netDown, tone)
                    flow("↑", payload.netUp, .secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                batteryStat
            }
            WidgetSparkline(values: payload.cpuHistory, color: tone)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minHeight: 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 12) {
            header(compact: false)
            Text(l10n.insightText(payload.machineInsight))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack(spacing: 8) {
                statCard(l10n.t(.cpu), figure(payload.cpu), payload.cpu)
                statCard(l10n.t(.memory), figure(payload.memory), payload.memory)
                statCard(l10n.t(.down), rate(payload.netDown), nil)
                statCard(l10n.t(.battery), batteryText, payload.battery, tint: batteryColor)
            }
            chartCard
            footer
        }
    }

    private var extra: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                header(compact: false)
                Text(l10n.insightText(payload.machineInsight))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.86))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                chartCard
                footer
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    tile(l10n.t(.cpu), figure(payload.cpu, digits: 1), payload.cpu, payload.cpuHistory)
                    tile(l10n.t(.memory), figure(payload.memory), payload.memory, payload.memoryHistory)
                }
                HStack(spacing: 10) {
                    tile(l10n.t(.network), rate(payload.netDown), nil, payload.netHistory, caption: "↑ \(rate(payload.netUp))")
                    tile(l10n.t(.battery), batteryText, payload.battery, [], caption: payload.charging ? l10n.t(.charging) : nil)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func header(compact: Bool) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Status")
                .font(.system(size: compact ? 13 : 15, weight: .semibold, design: .rounded))
            Spacer(minLength: 4)
            if compact {
                Circle().fill(tone).frame(width: 7, height: 7)
                Text(Format.clockTime(payload.capturedAt))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
            } else {
                HStack(spacing: 6) {
                    Circle().fill(tone).frame(width: 7, height: 7)
                    Text(l10n.moodTitle(payload.machineMood))
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(tone)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(tone.opacity(0.14), in: Capsule())
            }
        }
    }

    private var memoryLine: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(l10n.t(.memory))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(figure(payload.memory))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
            CapsuleBar(fraction: payload.memory, color: tone)
        }
    }

    private func ringStat(_ value: Double, _ title: String) -> some View {
        VStack(spacing: 4) {
            ZStack {
                WidgetRing(progress: value, color: tone, line: 5)
                Text(Format.percentNumber(value))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(tone)
            }
            .frame(width: 40, height: 40)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var batteryStat: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Image(systemName: batterySymbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(batteryColor)
            Text(batteryText)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(minWidth: 44, alignment: .trailing)
    }

    private func statCard(_ title: String, _ value: String, _ progress: Double?, tint: Color? = nil) -> some View {
        let ink = tint ?? tone
        return VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(ink)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            if let progress {
                CapsuleBar(fraction: progress, color: ink)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(scheme == .dark ? 0.10 : 0.05), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(l10n.t(.cpu))
                Spacer()
                Text(l10n.t(.memory))
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary)
            ZStack {
                WidgetSparkline(values: payload.memoryHistory, color: tone.opacity(0.55))
                WidgetSparkline(values: payload.cpuHistory, color: tone)
            }
            .frame(maxHeight: .infinity)
            .frame(minHeight: 72)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.primary.opacity(scheme == .dark ? 0.10 : 0.05), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var footer: some View {
        HStack {
            Text(payload.chip.isEmpty ? payload.name : payload.chip)
            Spacer(minLength: 8)
            Text(Format.clockTime(payload.capturedAt))
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.tertiary)
        .lineLimit(1)
    }

    private func tile(_ title: String, _ value: String, _ progress: Double?, _ history: [Double], caption: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(tone)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            if history.count >= 2 {
                WidgetSparkline(values: history, color: tone, peak: title == l10n.t(.network))
                    .frame(height: 32)
            } else if let progress {
                CapsuleBar(fraction: progress, color: tone)
            }
            if let caption {
                Text(caption)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.primary.opacity(scheme == .dark ? 0.06 : 0.04), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func flow(_ arrow: String, _ bytes: Double, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Text(arrow)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
            Text(rate(bytes))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private func figure(_ value: Double, digits: Int = 0) -> String {
        Format.percent(value, digits: digits)
            .replacingOccurrences(of: "\u{2066}", with: "")
            .replacingOccurrences(of: "\u{2069}", with: "")
    }

    private func rate(_ bytes: Double) -> String {
        Format.rate(bytes, unit: .bytes, arabic: payload.arabic).joined
            .replacingOccurrences(of: "\u{2066}", with: "")
            .replacingOccurrences(of: "\u{2069}", with: "")
    }

    private var batteryText: String {
        guard let battery = payload.battery else { return "AC" }
        return figure(battery)
    }

    private var batteryColor: Color {
        if let battery = payload.battery, !payload.charging, battery < 0.2 {
            return WidgetInk.color(.lowBattery, scheme)
        }
        return tone
    }

    private var batterySymbol: String {
        guard let battery = payload.battery else { return "powerplug" }
        if payload.charging { return "battery.100percent.bolt" }
        switch battery {
        case ..<0.15: return "battery.0percent"
        case ..<0.4: return "battery.25percent"
        case ..<0.65: return "battery.50percent"
        case ..<0.9: return "battery.75percent"
        default: return "battery.100percent"
        }
    }
}

struct WidgetBackdrop: View {
    var mood: MachineMood
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            (scheme == .dark
                ? Color(red: 0.102, green: 0.110, blue: 0.115)
                : Color(red: 0.965, green: 0.960, blue: 0.945))
            Circle()
                .fill(WidgetInk.color(mood, scheme).opacity(scheme == .dark ? 0.38 : 0.22))
                .frame(width: 240, height: 240)
                .blur(radius: 28)
                .offset(x: -40, y: -50)
        }
    }
}

enum WidgetInk {
    static func color(_ mood: MachineMood, _ scheme: ColorScheme) -> Color {
        switch mood {
        case .calm:
            return scheme == .dark
                ? Color(red: 0.49, green: 0.84, blue: 0.72)
                : Color(red: 0.09, green: 0.42, blue: 0.36)
        case .busy:
            return scheme == .dark
                ? Color(red: 0.95, green: 0.74, blue: 0.40)
                : Color(red: 0.70, green: 0.44, blue: 0.08)
        case .strained, .hot:
            return scheme == .dark
                ? Color(red: 0.96, green: 0.58, blue: 0.50)
                : Color(red: 0.73, green: 0.28, blue: 0.22)
        case .lowBattery:
            return scheme == .dark
                ? Color(red: 0.95, green: 0.70, blue: 0.38)
                : Color(red: 0.72, green: 0.42, blue: 0.10)
        }
    }
}

struct WidgetRing: View {
    var progress: Double
    var color: Color
    var line: CGFloat = 6

    var body: some View {
        ZStack {
            Circle().stroke(Color.primary.opacity(0.10), lineWidth: line)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress.isFinite ? progress : 0, 0), 1)))
                .stroke(color, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

struct CapsuleBar: View {
    var fraction: Double
    var color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(color)
                    .frame(width: max(4, geometry.size.width * CGFloat(min(max(fraction, 0), 1))))
            }
        }
        .frame(height: 5)
    }
}

struct WidgetSparkline: View {
    var values: [Double]
    var color: Color
    var peak: Bool = false

    var body: some View {
        Canvas { context, size in
            let series = values.filter(\.isFinite)
            guard series.count >= 2, size.width > 2, size.height > 2 else { return }
            let limit = peak ? max(series.max() ?? 1, 0.000_1) : 1
            func point(_ index: Int) -> CGPoint {
                let x = size.width * CGFloat(index) / CGFloat(series.count - 1)
                let y = size.height - (size.height - 2) * CGFloat(min(max(series[index], 0), limit) / limit)
                return CGPoint(x: x, y: y)
            }
            var line = Path()
            line.move(to: point(0))
            for index in 1..<series.count {
                line.addLine(to: point(index))
            }
            var area = line
            area.addLine(to: CGPoint(x: size.width, y: size.height))
            area.addLine(to: CGPoint(x: 0, y: size.height))
            area.closeSubpath()
            context.fill(
                area,
                with: .linearGradient(
                    Gradient(colors: [color.opacity(0.32), color.opacity(0.02)]),
                    startPoint: CGPoint(x: size.width / 2, y: 0),
                    endPoint: CGPoint(x: size.width / 2, y: size.height)
                )
            )
            context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

extension Format {
    static func clockTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss"
        return ltr(formatter.string(from: date))
    }
}

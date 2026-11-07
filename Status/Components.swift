import SwiftUI

struct Sparkline: View {
    var values: [Double]
    var color: Color
    var peakScale: Bool = false
    var filled: Bool = true

    var body: some View {
        Canvas { context, size in
            let series = values.filter(\.isFinite)
            guard series.count >= 2, size.width > 1, size.height > 1 else { return }
            let peak = peakScale ? max(series.max() ?? 1, 0.000_1) : 1
            func point(_ index: Int) -> CGPoint {
                let x = size.width * CGFloat(index) / CGFloat(series.count - 1)
                let normalized = min(max(series[index], 0), peak) / peak
                let y = size.height - (size.height - 1) * CGFloat(normalized)
                return CGPoint(x: x, y: min(max(y, 0), size.height))
            }
            var line = Path()
            line.move(to: point(0))
            for index in 1..<series.count {
                line.addLine(to: point(index))
            }
            if filled {
                var area = line
                area.addLine(to: CGPoint(x: size.width, y: size.height))
                area.addLine(to: CGPoint(x: 0, y: size.height))
                area.closeSubpath()
                context.fill(
                    area,
                    with: .linearGradient(
                        Gradient(colors: [color.opacity(0.30), color.opacity(0.02)]),
                        startPoint: CGPoint(x: size.width / 2, y: 0),
                        endPoint: CGPoint(x: size.width / 2, y: size.height)
                    )
                )
            }
            context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
        }
    }
}

struct RingMeter: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 7

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.08), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress.isFinite ? progress : 0, 0), 1)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.55), value: progress)
        }
    }
}

struct MoodPill: View {
    var title: String
    var color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.14), in: Capsule())
    }
}

struct InstrumentCard<Content: View>: View {
    var title: String
    var symbol: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(.secondary)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Palette.stroke, lineWidth: 1)
        }
    }
}

struct Figure: View {
    var value: String
    var unit: String
    var size: CGFloat = 28
    var color: Color = .primary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text(value)
                .figureFont(size)
                .foregroundStyle(color)
                .contentTransition(.numericText())
            if !unit.isEmpty {
                Text(unit)
                    .font(.system(size: max(11, size * 0.38), weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}

struct UsageBar: View {
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
        .frame(height: 6)
    }
}

struct StackedMeter: View {
    var parts: [(Double, Color)]

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                    if part.0 > 0.008 {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(part.1)
                            .frame(width: max(4, geometry.size.width * CGFloat(part.0)))
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(height: 8)
        .background(Color.primary.opacity(0.06), in: Capsule())
        .clipShape(Capsule())
    }
}

struct BatteryGlyph: View {
    var fraction: Double
    var charging: Bool
    var color: Color

    var body: some View {
        HStack(spacing: 2) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .strokeBorder(color.opacity(0.85), lineWidth: 1.4)
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(color)
                    .padding(2)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(x: CGFloat(min(max(fraction, 0.04), 1)), y: 1, anchor: .leading)
                if charging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(color)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(width: 26, height: 13)
            RoundedRectangle(cornerRadius: 1)
                .fill(color.opacity(0.85))
                .frame(width: 2, height: 6)
        }
        .accessibilityLabel("\(Int((fraction * 100).rounded()))%")
    }
}

struct SymbolButton: View {
    var systemName: String
    var help: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary.opacity(0.72))
        .help(help)
    }
}

struct CoreBars: View {
    var cores: [Double]
    var performanceCount: Int
    var color: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(cores.enumerated()), id: \.offset) { index, value in
                let efficiency = performanceCount > 0 && index >= performanceCount
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(color.opacity(efficiency ? 0.45 : 0.95))
                    .frame(height: max(3, 52 * CGFloat(min(max(value, 0), 1))))
                    .frame(maxWidth: .infinity, maxHeight: 52, alignment: .bottom)
            }
        }
        .frame(height: 52)
    }
}

struct WidgetMenu: View {
    var canMoveUp: Bool
    var canMoveDown: Bool
    var upTitle: String
    var downTitle: String
    var hideTitle: String
    var moveUp: () -> Void
    var moveDown: () -> Void
    var hide: () -> Void

    var body: some View {
        Menu {
            Button(upTitle, action: moveUp).disabled(!canMoveUp)
            Button(downTitle, action: moveDown).disabled(!canMoveDown)
            Divider()
            Button(hideTitle, action: hide)
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .foregroundStyle(.tertiary)
    }
}

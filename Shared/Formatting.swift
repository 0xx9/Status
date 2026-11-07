import Foundation

enum ByteBase: Sendable {
    case binary
    case decimal

    var step: Double {
        switch self {
        case .binary: return 1024
        case .decimal: return 1000
        }
    }
}

struct Measure: Equatable, Sendable {
    var value: String
    var unit: String

    var joined: String {
        let number = value
            .replacingOccurrences(of: "\u{2066}", with: "")
            .replacingOccurrences(of: "\u{2069}", with: "")
        if unit.isEmpty { return Format.ltr(number) }
        return Format.ltr("\(number) \(unit)")
    }
}

enum Format {
    static func ltr(_ value: String) -> String {
        "\u{2066}\(value)\u{2069}"
    }

    static func percent(_ value: Double, digits: Int = 0) -> String {
        guard value.isFinite else { return ltr("0%") }
        if value > 0, value < 0.005, digits == 0 {
            return ltr("<1%")
        }
        let scaled = value * 100
        let number = rounded(scaled, digits: digits)
        return ltr("\(number)%")
    }

    static func percentNumber(_ value: Double, digits: Int = 0) -> String {
        guard value.isFinite else { return "0" }
        if value > 0, value < 0.005, digits == 0 { return "<1" }
        return rounded(value * 100, digits: digits)
    }

    static func corePercent(_ fractionOfOneCore: Double) -> String {
        guard fractionOfOneCore.isFinite else { return ltr("0%") }
        if fractionOfOneCore > 0, fractionOfOneCore < 0.005 {
            return ltr("<1%")
        }
        return ltr("\(rounded(fractionOfOneCore * 100, digits: 0))%")
    }

    static func bytes(_ value: UInt64, base: ByteBase, arabic: Bool) -> Measure {
        measure(Double(value), base: base, perSecond: false, bits: false, arabic: arabic)
    }

    static func rate(_ bytesPerSecond: Double, unit: NetworkUnit, arabic: Bool) -> Measure {
        let bits = unit == .bits
        let amount = bits ? bytesPerSecond * 8 : bytesPerSecond
        return measure(amount, base: .decimal, perSecond: true, bits: bits, arabic: arabic)
    }

    static func menuRate(_ bytesPerSecond: Double, unit: NetworkUnit) -> String {
        let bits = unit == .bits
        let amount = max(0, bits ? bytesPerSecond * 8 : bytesPerSecond)
        let step = 1000.0
        let suffixes = bits ? ["b", "K", "M", "G"] : ["B", "K", "M", "G"]
        var value = amount
        var index = 0
        while value >= step, index < suffixes.count - 1 {
            value /= step
            index += 1
        }
        let number: String
        if index == 0 {
            number = "\(Int(value.rounded()))"
        } else if value >= 10 {
            number = "\(Int(value.rounded()))"
        } else {
            number = String(format: "%.1f", value)
        }
        return ltr(number + suffixes[index])
    }

    static func uptime(_ interval: TimeInterval, arabic: Bool) -> String {
        clock(max(0, interval), arabic: arabic)
    }

    static func minutes(_ minutes: Int, arabic: Bool) -> String {
        guard minutes >= 0 else { return arabic ? "يحسب…" : "Calculating…" }
        return clock(TimeInterval(minutes * 60), arabic: arabic)
    }

    static func ago(_ interval: TimeInterval, arabic: Bool) -> String {
        if interval < 2 { return arabic ? "الآن" : "Just now" }
        if interval < 60 {
            let seconds = Int(interval.rounded())
            return arabic ? "منذ \(seconds) ث" : "\(seconds)s ago"
        }
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return arabic ? "منذ \(minutes) د" : "\(minutes)m ago"
        }
        let hours = Int(interval / 3600)
        return arabic ? "منذ \(hours) س" : "\(hours)h ago"
    }

    static func temperature(_ celsius: Double, arabic: Bool) -> String {
        let number = rounded(celsius, digits: 0)
        return ltr(arabic ? "\(number)°" : "\(number)°")
    }

    private static func clock(_ interval: TimeInterval, arabic: Bool) -> String {
        let total = Int(interval.rounded())
        let days = total / 86_400
        let hours = (total % 86_400) / 3_600
        let minutes = (total % 3_600) / 60
        if days > 0 {
            return arabic ? ltr("\(days) ي \(hours) س") : ltr("\(days)d \(hours)h")
        }
        if hours > 0 {
            return arabic ? ltr("\(hours) س \(minutes) د") : ltr("\(hours)h \(minutes)m")
        }
        if minutes > 0 {
            return arabic ? ltr("\(minutes) د") : ltr("\(minutes)m")
        }
        return arabic ? ltr("\(total) ث") : ltr("\(total)s")
    }

    private static func measure(
        _ amount: Double,
        base: ByteBase,
        perSecond: Bool,
        bits: Bool,
        arabic: Bool
    ) -> Measure {
        let safe = amount.isFinite ? max(0, amount) : 0
        let step = base.step
        let table: [(Double, String, String)] = bits
            ? [
                (1, "b", "بت"),
                (step, "Kb", "ك.بت"),
                (step * step, "Mb", "م.بت"),
                (step * step * step, "Gb", "غ.بت"),
            ]
            : [
                (1, "B", "ب"),
                (step, "KB", "ك.ب"),
                (step * step, "MB", "م.ب"),
                (step * step * step, "GB", "غ.ب"),
                (step * step * step * step, "TB", "ت.ب"),
            ]
        var chosen = table[0]
        for entry in table where safe >= entry.0 {
            chosen = entry
        }
        let scaled = safe / chosen.0
        let digits = scaled >= 10 || chosen.0 == 1 ? 0 : 1
        let number = rounded(scaled, digits: digits)
        let suffix = arabic ? chosen.2 : chosen.1
        let unit = perSecond ? (arabic ? "\(suffix)/ث" : "\(suffix)/s") : suffix
        return Measure(value: ltr(number), unit: unit)
    }

    private static func rounded(_ value: Double, digits: Int) -> String {
        if digits == 0 {
            return String(Int(value.rounded()))
        }
        return String(format: "%.\(digits)f", value)
    }
}

enum StatusSummary {
    static func make(snapshot: SystemSnapshot, arabic: Bool, unit: NetworkUnit) -> String {
        var lines: [String] = []
        let name = snapshot.identity.marketingName.isEmpty
            ? snapshot.identity.computerName
            : snapshot.identity.marketingName
        lines.append("Status")
        var identity = name
        if !snapshot.identity.chip.isEmpty {
            identity += " · \(snapshot.identity.chip)"
        }
        lines.append(identity)
        lines.append("")
        lines.append(row(arabic ? "المعالج" : "Processor", Format.percent(snapshot.cpu.usage)))
        let used = Format.bytes(snapshot.memory.used, base: .binary, arabic: arabic).joined
        let total = Format.bytes(snapshot.memory.total, base: .binary, arabic: arabic).joined
        lines.append(row(arabic ? "الذاكرة" : "Memory", "\(Format.percent(snapshot.memory.usedFraction)) · \(used) / \(total)"))
        let down = Format.rate(snapshot.network.downBytesPerSecond, unit: unit, arabic: arabic).joined
        let up = Format.rate(snapshot.network.upBytesPerSecond, unit: unit, arabic: arabic).joined
        lines.append(row(arabic ? "الشبكة" : "Network", "↓ \(down)  ↑ \(up)"))
        if let battery = snapshot.battery {
            var batteryText = Format.percent(battery.fraction)
            if battery.isCharging {
                batteryText += arabic ? " · يشحن" : " · Charging"
            } else if let minutes = battery.minutesRemaining, minutes >= 0 {
                batteryText += " · \(Format.minutes(minutes, arabic: arabic))"
            }
            lines.append(row(arabic ? "البطارية" : "Battery", batteryText))
        }
        lines.append(row(
            arabic ? "الحرارة" : "Thermal",
            arabic ? thermalArabic(snapshot.thermal) : thermalEnglish(snapshot.thermal)
        ))
        return lines.joined(separator: "\n")
    }

    private static func row(_ label: String, _ value: String) -> String {
        "\(label)  \(value)"
    }

    private static func thermalArabic(_ level: ThermalLevel) -> String {
        switch level {
        case .nominal: return "طبيعية"
        case .fair: return "دافئة"
        case .serious: return "مرتفعة"
        case .critical: return "حرجة"
        }
    }

    private static func thermalEnglish(_ level: ThermalLevel) -> String {
        switch level {
        case .nominal: return "Nominal"
        case .fair: return "Warm"
        case .serious: return "Hot"
        case .critical: return "Critical"
        }
    }
}

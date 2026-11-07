import Darwin
import Foundation

struct WidgetPayload: Codable, Equatable, Sendable {
    var capturedAt: Date
    var cpu: Double
    var memory: Double
    var netDown: Double
    var netUp: Double
    var battery: Double?
    var charging: Bool
    var mood: String
    var insight: String
    var chip: String
    var name: String
    var arabic: Bool
    var cpuHistory: [Double]
    var memoryHistory: [Double]
    var netHistory: [Double]

    var machineMood: MachineMood { MachineMood(rawValue: mood) ?? .calm }
    var machineInsight: Insight { Insight(rawValue: insight) ?? .calculating }

    static let preview = WidgetPayload(
        capturedAt: Date(),
        cpu: 0.24,
        memory: 0.68,
        netDown: 180_000,
        netUp: 42_000,
        battery: 0.76,
        charging: true,
        mood: MachineMood.calm.rawValue,
        insight: Insight.calm.rawValue,
        chip: "Apple M4",
        name: "Mac",
        arabic: false,
        cpuHistory: (0..<36).map { 0.18 + 0.07 * sin(Double($0) / 3.2) },
        memoryHistory: (0..<36).map { _ in 0.68 },
        netHistory: (0..<36).map { 80_000 + 70_000 * abs(sin(Double($0) / 2.4)) }
    )
}

extension WidgetPayload {
    init(snapshot: SystemSnapshot, arabic: Bool) {
        capturedAt = snapshot.capturedAt
        cpu = snapshot.cpu.usage
        memory = snapshot.memory.usedFraction
        netDown = snapshot.network.downBytesPerSecond
        netUp = snapshot.network.upBytesPerSecond
        battery = snapshot.battery?.fraction
        charging = snapshot.battery?.isCharging ?? false
        mood = snapshot.mood.rawValue
        insight = snapshot.insight.rawValue
        chip = snapshot.identity.chip.isEmpty ? snapshot.identity.marketingName : snapshot.identity.chip
        name = snapshot.identity.marketingName.isEmpty ? snapshot.identity.computerName : snapshot.identity.marketingName
        self.arabic = arabic
        cpuHistory = Array(snapshot.history.cpu.suffix(40))
        memoryHistory = Array(snapshot.history.memory.suffix(40))
        netHistory = Array(snapshot.history.netDown.suffix(40))
    }
}

enum WidgetSnapshotStore {
    static func write(_ payload: WidgetPayload) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        for url in writeURLs() {
            let folder = url.deletingLastPathComponent()
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try? data.write(to: url, options: .atomic)
        }
    }

    static func read() -> WidgetPayload? {
        for url in readURLs() {
            guard let data = try? Data(contentsOf: url),
                  let payload = try? JSONDecoder().decode(WidgetPayload.self, from: data) else { continue }
            return payload
        }
        return nil
    }

    /// The widget is sandboxed, so it cannot read the app's real home folder.
    /// The app also writes a copy into the widget container, which the extension can read.
    private static func writeURLs() -> [URL] {
        var urls = candidateURLs()
        let mirror = URL(fileURLWithPath: "/Users/\(NSUserName())", isDirectory: true)
            .appendingPathComponent("Library/Containers/com.muhsan.status.widgets/Data/Library/Application Support/Status/widget.json")
        urls.append(mirror)
        return urls
    }

    private static func readURLs() -> [URL] {
        var urls = [NSHomeDirectoryURL().appendingPathComponent("Library/Application Support/Status/widget.json")]
        urls.append(contentsOf: candidateURLs())
        return urls
    }

    private static func NSHomeDirectoryURL() -> URL {
        URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
    }

    static func candidateURLs() -> [URL] {
        var homes: [String] = []
        if let entry = getpwuid(getuid()), let dir = entry.pointee.pw_dir {
            homes.append(String(cString: dir))
        }
        homes.append("/Users/\(NSUserName())")
        homes.append(NSHomeDirectory())
        var seen = Set<String>()
        return homes.compactMap { home in
            guard seen.insert(home).inserted else { return nil }
            return URL(fileURLWithPath: home, isDirectory: true)
                .appendingPathComponent("Library/Application Support/Status/widget.json")
        }
    }
}

import Combine
import Foundation
import WidgetKit

enum ProcessSort: String, CaseIterable {
    case cpu
    case memory
}

@MainActor
final class Monitor: ObservableObject {
    @Published private(set) var snapshot: SystemSnapshot?
    @Published private(set) var lastCapture: Date?
    @Published var processQuery = ""
    @Published var processSort: ProcessSort = .cpu

    private let settings: SettingsStore
    private let sampler = Sampler()
    private let queue = DispatchQueue(label: "status.sampler", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var sampling = false
    private var started = false
    private var history = MetricHistory()
    private var alerts = StatusAlerts()
    private var lastWidgetReload = Date.distantPast
    private var cancellables: Set<AnyCancellable> = []

    init(settings: SettingsStore) {
        self.settings = settings
        settings.$settings
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                self?.reschedule()
            }
            .store(in: &cancellables)
    }

    var filteredProcesses: [ProcessSnapshot] {
        let rows = snapshot?.processes ?? []
        let query = processQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = query.isEmpty
            ? rows
            : rows.filter { $0.name.localizedCaseInsensitiveContains(query) }
        switch processSort {
        case .cpu:
            return filtered.sorted { $0.cpuFractionOfOneCore > $1.cpuFractionOfOneCore }
        case .memory:
            return filtered.sorted { $0.memory > $1.memory }
        }
    }

    func start() {
        guard !started else { return }
        started = true
        queue.async { [sampler] in
            sampler.prime()
            Thread.sleep(forTimeInterval: 0.2)
        }
        refreshNow()
        reschedule()
        loadHardwareProfile()
    }

    func refreshNow() {
        tick()
    }

    func refreshNotificationAuthorization(_ update: @escaping (Bool) -> Void) {
        alerts.refreshAuthorization(update)
    }

    func requestNotifications() {
        alerts.requestAccess()
    }

    func setMonitoring(_ enabled: Bool) {
        settings.update { $0.monitoringEnabled = enabled }
        if enabled {
            refreshNow()
        }
        reschedule()
    }

    func reschedule() {
        timer?.cancel()
        timer = nil
        guard settings.settings.monitoringEnabled else { return }
        let interval = currentInterval()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(Int(interval * 200)))
        timer.setEventHandler { [weak self] in
            self?.tick()
        }
        timer.resume()
        self.timer = timer
    }

    private func currentInterval() -> TimeInterval {
        let onBattery = snapshot?.battery.map { !$0.isPlugged } ?? false
        return MetricMath.sampleInterval(PaceInput(
            refresh: settings.settings.refresh,
            gentleOnBattery: settings.settings.gentleOnBattery,
            onBattery: onBattery,
            lowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled
        ))
    }

    private func tick() {
        guard !sampling else { return }
        sampling = true
        let includeProcesses = settings.settings.widgets.contains(.processes)
        let options = SampleOptions(includeProcesses: includeProcesses, processLimit: 8)
        queue.async { [weak self] in
            guard let self else { return }
            let sample = self.sampler.sample(options: options)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.sampling = false
                self.apply(sample)
            }
        }
    }

    private func apply(_ sample: SystemSnapshot) {
        history.append(
            cpu: sample.cpu.usage,
            memory: sample.memory.usedFraction,
            netDown: sample.network.downBytesPerSecond,
            netUp: sample.network.upBytesPerSecond,
            diskRead: sample.diskIO.downBytesPerSecond,
            diskWrite: sample.diskIO.upBytesPerSecond
        )
        var next = sample
        next.history = history
        if let existing = snapshot {
            if next.identity.marketingName == next.identity.modelIdentifier, !existing.identity.marketingName.isEmpty {
                next.identity.marketingName = existing.identity.marketingName
            }
            if existing.identity.chip.count > next.identity.chip.count {
                next.identity.chip = existing.identity.chip
            }
        }
        let reassessment = MetricMath.assess(
            cpu: next.cpu.usage,
            gpu: next.cpu.gpuUsage,
            memory: next.memory.pressure,
            thermal: next.thermal,
            battery: next.battery
        )
        next.mood = reassessment.0
        next.insight = reassessment.1
        snapshot = next
        lastCapture = next.capturedAt
        WidgetSnapshotStore.write(WidgetPayload(snapshot: next, arabic: settings.l10n.isArabic))
        alerts.consider(snapshot: next, settings: settings.settings)
        reloadWidgetsIfNeeded()
    }

    private func reloadWidgetsIfNeeded() {
        let now = Date()
        guard now.timeIntervalSince(lastWidgetReload) > 10 else { return }
        lastWidgetReload = now
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func loadHardwareProfile() {
        queue.async { [weak self] in
            guard let profile = HardwareProfileLoader.load() else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self, var snapshot = self.snapshot else { return }
                if !profile.marketingName.isEmpty {
                    snapshot.identity.marketingName = profile.marketingName
                }
                if !profile.chip.isEmpty {
                    snapshot.identity.chip = profile.chip
                }
                self.snapshot = snapshot
            }
        }
    }
}

enum HardwareProfileLoader {
    static func load() -> (marketingName: String, chip: String, memoryLabel: String)? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPHardwareDataType", "-json"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
        } catch {
            return nil
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = json["SPHardwareDataType"] as? [[String: Any]],
              let row = rows.first else { return nil }
        let marketing = (row["machine_name"] as? String) ?? ""
        let chip = (row["chip_type"] as? String) ?? ""
        let memory = (row["physical_memory"] as? String) ?? ""
        if marketing.isEmpty && chip.isEmpty { return nil }
        return (marketing, chip, memory)
    }
}

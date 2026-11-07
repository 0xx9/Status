import XCTest

final class StatusTests: XCTestCase {
    func testCPUUsageFromTickDelta() {
        let previous = CPUTicks(user: 100, system: 50, idle: 800, nice: 50)
        let current = CPUTicks(user: 180, system: 70, idle: 900, nice: 50)
        let usage = MetricMath.cpuUsage(previous: previous, current: current)
        XCTAssertNotNil(usage)
        XCTAssertEqual(usage?.total ?? 0, 0.5, accuracy: 0.0001)
        XCTAssertEqual(usage?.user ?? 0, 0.4, accuracy: 0.0001)
        XCTAssertEqual(usage?.system ?? 0, 0.1, accuracy: 0.0001)
    }

    func testCPUUsageWrapsCounters() {
        let previous = CPUTicks(user: UInt32.max - 29, system: 0, idle: 0, nice: 0)
        let current = CPUTicks(user: 0, system: 0, idle: 70, nice: 0)
        let usage = MetricMath.cpuUsage(previous: previous, current: current)
        XCTAssertEqual(usage?.total ?? 0, 0.3, accuracy: 0.0001)
    }

    func testZeroCPUDeltaReturnsNil() {
        let ticks = CPUTicks(user: 4, system: 4, idle: 4, nice: 4)
        XCTAssertNil(MetricMath.cpuUsage(previous: ticks, current: ticks))
    }

    func testMemoryBreakdownStaysInsideTotal() {
        let snapshot = MetricMath.memorySnapshot(MemoryInput(
            total: 16_000,
            pageSize: 100,
            internalPages: 80,
            purgeablePages: 10,
            wiredPages: 20,
            compressedPages: 15,
            externalPages: 30,
            freePages: 40,
            swapUsed: 200
        ))
        XCTAssertLessThanOrEqual(snapshot.used + snapshot.cached + snapshot.free, snapshot.total)
        XCTAssertEqual(snapshot.apps, 7_000)
        XCTAssertEqual(snapshot.wired, 2_000)
        XCTAssertEqual(snapshot.compressed, 1_500)
        XCTAssertEqual(snapshot.swapUsed, 200)
        XCTAssertEqual(snapshot.used, 10_500)
    }

    func testMemoryPressureThresholds() {
        XCTAssertEqual(MetricMath.pressure(free: 5, cached: 1, compressed: 1, total: 100), .high)
        XCTAssertEqual(MetricMath.pressure(free: 12, cached: 2, compressed: 1, total: 100), .medium)
        XCTAssertEqual(MetricMath.pressure(free: 40, cached: 20, compressed: 2, total: 100), .low)
        XCTAssertEqual(MetricMath.pressure(free: 50, cached: 10, compressed: 40, total: 100), .high)
    }

    func testRateIgnoresSleepSpikesAndResets() {
        XCTAssertEqual(MetricMath.ratePerSecond(previous: 1_000, current: 3_000, elapsed: 2), 1_000, accuracy: 0.001)
        XCTAssertEqual(MetricMath.ratePerSecond(previous: 1_000, current: 50_000, elapsed: 30), 0)
        XCTAssertEqual(MetricMath.ratePerSecond(previous: 5_000, current: 100, elapsed: 1), 0)
        XCTAssertEqual(MetricMath.ratePerSecond(previous: 0, current: 100, elapsed: 0.01), 0)
    }

    func testProcessCPUIsPerCore() {
        let fraction = MetricMath.processCPUFraction(
            previousNanos: 1_000_000_000,
            currentNanos: 1_500_000_000,
            elapsedNanos: 1_000_000_000
        )
        XCTAssertEqual(fraction, 0.5, accuracy: 0.0001)
    }

    func testSampleIntervalSlowsOnBatteryAndLowPower() {
        let live = PaceInput(refresh: .live, gentleOnBattery: true, onBattery: false, lowPowerMode: false)
        XCTAssertEqual(MetricMath.sampleInterval(live), 1)
        let battery = PaceInput(refresh: .live, gentleOnBattery: true, onBattery: true, lowPowerMode: false)
        XCTAssertEqual(MetricMath.sampleInterval(battery), 2)
        let quiet = PaceInput(refresh: .quiet, gentleOnBattery: true, onBattery: true, lowPowerMode: false)
        XCTAssertEqual(MetricMath.sampleInterval(quiet), 5)
        let lowPower = PaceInput(refresh: .live, gentleOnBattery: false, onBattery: false, lowPowerMode: true)
        XCTAssertEqual(MetricMath.sampleInterval(lowPower), 2)
    }

    func testMoodNamesTheDominantCause() {
        XCTAssertEqual(MetricMath.assess(cpu: 0.1, gpu: nil, memory: .low, thermal: .nominal, battery: nil).0, .calm)
        XCTAssertEqual(MetricMath.assess(cpu: 0.9, gpu: nil, memory: .low, thermal: .nominal, battery: nil).1, .cpuStrained)
        XCTAssertEqual(MetricMath.assess(cpu: 0.2, gpu: nil, memory: .high, thermal: .nominal, battery: nil).1, .memoryStrained)
        XCTAssertEqual(MetricMath.assess(cpu: 0.2, gpu: 0.8, memory: .low, thermal: .nominal, battery: nil).1, .gpuBusy)
        XCTAssertEqual(MetricMath.assess(cpu: 0.2, gpu: nil, memory: .low, thermal: .serious, battery: nil).0, .hot)
        let battery = BatterySnapshot(
            fraction: 0.1, isCharging: false, isPlugged: false,
            minutesRemaining: 10, minutesToFull: nil, health: "Good",
            cycleCount: 12, temperatureC: 30
        )
        XCTAssertEqual(MetricMath.assess(cpu: 0.1, gpu: nil, memory: .low, thermal: .nominal, battery: battery).0, .lowBattery)
    }

    func testBatteryTemperatureConversion() {
        XCTAssertEqual(MetricMath.batteryCelsius(raw: 3032) ?? 0, 30.05, accuracy: 0.2)
        XCTAssertNil(MetricMath.batteryCelsius(raw: 0))
    }

    func testHistoryCapsItself() {
        var history = MetricHistory()
        for index in 0..<200 {
            history.append(cpu: Double(index), memory: 0.5, netDown: 1, netUp: 2, diskRead: 3, diskWrite: 4)
        }
        XCTAssertEqual(history.cpu.count, MetricHistory.capacity)
        XCTAssertEqual(history.cpu.last, 199)
    }

    func testBoardEditing() {
        var widgets = BoardEditing.add(.cpu, to: [])
        widgets = BoardEditing.add(.memory, to: widgets)
        widgets = BoardEditing.add(.cpu, to: widgets)
        XCTAssertEqual(widgets, [.cpu, .memory])
        widgets = BoardEditing.move(.memory, by: -1, in: widgets)
        XCTAssertEqual(widgets, [.memory, .cpu])
        widgets = BoardEditing.remove(.cpu, from: widgets)
        XCTAssertEqual(widgets, [.memory])
        var metrics = BoardEditing.toggle(.cpu, in: [])
        metrics = BoardEditing.toggle(.memory, in: metrics)
        metrics = BoardEditing.toggle(.battery, in: metrics)
        metrics = BoardEditing.toggle(.network, in: metrics)
        XCTAssertEqual(metrics.count, 3)
        XCTAssertFalse(metrics.contains(.network))
        metrics = BoardEditing.toggle(.cpu, in: metrics)
        XCTAssertFalse(metrics.contains(.cpu))
    }

    func testSettingsRoundTripDropsUnknownWidgets() {
        let json = """
        {"widgets":["cpu","nope","battery"],"menuBarMetrics":["cpu","cpu"],"lowBatteryThreshold":9}
        """.data(using: .utf8)!
        let decoded = try? JSONDecoder().decode(AppSettings.self, from: json)
        XCTAssertEqual(decoded?.widgets, [.cpu, .battery])
        XCTAssertEqual(decoded?.menuBarMetrics, [.cpu])
        XCTAssertEqual(decoded?.lowBatteryThreshold, 0.5)
        XCTAssertEqual(decoded?.refresh, .live)
        let data = try? JSONEncoder().encode(AppSettings.standard)
        let again = try? JSONDecoder().decode(AppSettings.self, from: data ?? Data())
        XCTAssertEqual(again, AppSettings.normalized(.standard))
    }

    func testPercentAndRatesKeepLatinDigits() {
        XCTAssertEqual(Format.percent(0.184), "\u{2066}18%\u{2069}")
        XCTAssertEqual(Format.percent(0.004), "\u{2066}<1%\u{2069}")
        XCTAssertEqual(Format.percent(0), "\u{2066}0%\u{2069}")
        let memory = Format.bytes(1_610_612_736, base: .binary, arabic: true)
        XCTAssertEqual(memory.unit, "غ.ب")
        let speed = Format.rate(1_500_000, unit: .bytes, arabic: false)
        XCTAssertTrue(speed.joined.contains("MB/s"))
        XCTAssertEqual(Format.menuRate(1_500_000, unit: .bytes), "\u{2066}1.5M\u{2069}")
        XCTAssertEqual(Format.uptime(9_000, arabic: false), "\u{2066}2h 30m\u{2069}")
        XCTAssertEqual(Format.uptime(7_320, arabic: true), "\u{2066}2 س 2 د\u{2069}")
        XCTAssertEqual(Format.ago(1, arabic: true), "الآن")
    }

    func testSummaryIncludesTheReadings() {
        var snapshot = SystemSnapshot.empty
        snapshot.cpu.usage = 0.18
        snapshot.memory.total = 16 * 1024 * 1024 * 1024
        snapshot.memory.used = 8 * 1024 * 1024 * 1024
        snapshot.identity.marketingName = "Mac"
        snapshot.identity.chip = "Apple M4"
        let arabic = StatusSummary.make(snapshot: snapshot, arabic: true, unit: .bytes)
        XCTAssertTrue(arabic.contains("المعالج"))
        XCTAssertTrue(arabic.contains("Apple M4"))
        let english = StatusSummary.make(snapshot: snapshot, arabic: false, unit: .bytes)
        XCTAssertTrue(english.contains("Processor"))
    }

    func testMenuBarShowsPauseAndSingleSparkline() {
        var snapshot = SystemSnapshot.empty
        snapshot.cpu.usage = 0.2
        snapshot.history.append(cpu: 0.2, memory: 0.4, netDown: 10, netUp: 5, diskRead: 1, diskWrite: 1)
        snapshot.history.append(cpu: 0.3, memory: 0.4, netDown: 12, netUp: 5, diskRead: 1, diskWrite: 1)
        var settings = AppSettings.standard
        settings.menuBarMetrics = [.cpu]
        let live = MenuBarComposer.model(
            snapshot: snapshot, settings: settings, paused: false, arabic: false, insight: "Calm"
        )
        XCTAssertTrue(live.showsSparkline)
        XCTAssertEqual(live.title, Format.percent(0.2))
        let paused = MenuBarComposer.model(
            snapshot: snapshot, settings: settings, paused: true, arabic: true, insight: "متوقف"
        )
        XCTAssertFalse(paused.showsSparkline)
        XCTAssertEqual(paused.symbolName, "pause.circle")
    }

    func testEmptyMenuBarCannotDisappear() {
        var settings = AppSettings.standard
        settings.menuBarMetrics = []
        settings.showMenuBarIcon = false
        let normalized = AppSettings.normalized(settings)
        XCTAssertTrue(normalized.showMenuBarIcon)
    }

    func testLanguageResolution() {
        XCTAssertTrue(L10n.resolve(.arabic).isArabic)
        XCTAssertFalse(L10n.resolve(.english).isArabic)
        XCTAssertEqual(L10n.resolve(.arabic).t(.cpu), "المعالج")
        XCTAssertEqual(L10n.resolve(.english).t(.cpu), "Processor")
    }

    func testWidgetPayloadRoundTripKeepsTheReading() {
        let payload = WidgetPayload.preview
        let data = try? JSONEncoder().encode(payload)
        let decoded = try? JSONDecoder().decode(WidgetPayload.self, from: data ?? Data())
        XCTAssertEqual(decoded?.cpu, payload.cpu)
        XCTAssertEqual(decoded?.cpuHistory.count, payload.cpuHistory.count)
        XCTAssertEqual(decoded?.machineMood, .calm)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("status-widget-\(UUID().uuidString).json")
        try? data?.write(to: url)
        let read = try? Data(contentsOf: url)
        XCTAssertEqual(try? JSONDecoder().decode(WidgetPayload.self, from: read ?? Data()), payload)
        try? FileManager.default.removeItem(at: url)
    }

    func testLiveSampleReadsThisMac() {
        let sampler = Sampler()
        let first = sampler.sample(options: .quiet)
        Thread.sleep(forTimeInterval: 0.25)
        let second = sampler.sample(options: .live)
        XCTAssertGreaterThan(second.memory.total, 1_000_000_000)
        XCTAssertGreaterThan(second.cpu.cores.count, 0)
        XCTAssertGreaterThan(second.uptime, 1)
        XCTAssertFalse(second.identity.osVersion.isEmpty)
        XCTAssertTrue((0...1).contains(second.cpu.usage))
        XCTAssertGreaterThanOrEqual(second.cpu.loadAverage.count, 1)
        XCTAssertNotEqual(first.capturedAt, .distantPast)
    }
}

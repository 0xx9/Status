import Foundation
import IOKit
import IOKit.ps

final class Sampler: @unchecked Sendable {
    private let lock = NSLock()
    private var previousCPU: CPUTicks?
    private var previousCores: [CPUTicks] = []
    private var previousNet = InterfaceTotals()
    private var previousDiskRead: UInt64 = 0
    private var previousDiskWrite: UInt64 = 0
    private var hasDiskBaseline = false
    private var hasNetBaseline = false
    private var lastSample = mach_absolute_time()
    private var timebase = mach_timebase_info_data_t(numer: 1, denom: 1)
    private var processCPU: [Int32: UInt64] = [:]
    private var lastProcessSample = mach_absolute_time()
    private let coreLayout = CoreLayout.current

    init() {
        mach_timebase_info(&timebase)
    }

    func sample(options: SampleOptions) -> SystemSnapshot {
        lock.lock()
        defer { lock.unlock() }

        let now = mach_absolute_time()
        let elapsed = seconds(from: lastSample, to: now)
        lastSample = now

        let cpu = readCPU()
        let memory = readMemory()
        let disks = readDisks()
        let diskIO = readDiskIO(elapsed: elapsed)
        let network = readNetwork(elapsed: elapsed)
        let battery = readBattery()
        let processes = options.includeProcesses ? readProcesses(limit: options.processLimit) : []
        let thermal = readThermal()
        let uptime = readUptime()
        var identity = SystemIdentity.basic()
        identity.physicalMemory = memory.total
        let (mood, insight) = MetricMath.assess(
            cpu: cpu.usage,
            gpu: cpu.gpuUsage,
            memory: memory.pressure,
            thermal: thermal,
            battery: battery
        )

        return SystemSnapshot(
            capturedAt: Date(),
            cpu: cpu,
            memory: memory,
            disks: disks,
            diskIO: diskIO,
            network: network.throughput,
            networkInterface: network.interface,
            ipv4: network.ipv4,
            battery: battery,
            processes: processes,
            thermal: thermal,
            identity: identity,
            uptime: uptime,
            history: MetricHistory(),
            mood: mood,
            insight: insight
        )
    }

    func prime() {
        lock.lock()
        defer { lock.unlock() }
        _ = readCPU()
        _ = readNetwork(elapsed: 0)
        _ = readDiskIO(elapsed: 0)
        if !processCPU.isEmpty || true {
            _ = readProcesses(limit: 1)
        }
    }

    private func seconds(from start: UInt64, to end: UInt64) -> TimeInterval {
        guard end >= start, timebase.denom > 0 else { return 0 }
        let nanos = (end &- start) * UInt64(timebase.numer) / UInt64(timebase.denom)
        return TimeInterval(nanos) / 1_000_000_000
    }

    private func nanos(from start: UInt64, to end: UInt64) -> UInt64 {
        guard end >= start, timebase.denom > 0 else { return 0 }
        return (end &- start) * UInt64(timebase.numer) / UInt64(timebase.denom)
    }

    private func readCPU() -> CPUSnapshot {
        let current = hostTicks() ?? .zero
        let usage: CPUUsage
        if let previousCPU, let value = MetricMath.cpuUsage(previous: previousCPU, current: current) {
            usage = value
        } else {
            usage = CPUUsage(total: 0, user: 0, system: 0)
        }
        previousCPU = current

        let cores = coreTicks()
        var coreUsage: [Double] = []
        if previousCores.count == cores.count {
            for index in cores.indices {
                if let value = MetricMath.cpuUsage(previous: previousCores[index], current: cores[index]) {
                    coreUsage.append(value.total)
                } else {
                    coreUsage.append(0)
                }
            }
        } else {
            coreUsage = Array(repeating: 0, count: cores.count)
        }
        previousCores = cores

        return CPUSnapshot(
            usage: usage.total,
            user: usage.user,
            system: usage.system,
            cores: coreUsage,
            performanceCoreCount: coreLayout.performance,
            efficiencyCoreCount: coreLayout.efficiency,
            loadAverage: loadAverage(),
            gpuUsage: gpuUsage()
        )
    }

    private func hostTicks() -> CPUTicks? {
        var load = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &load) { pointer -> kern_return_t in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        let ticks = load.cpu_ticks
        return CPUTicks(
            user: UInt32(ticks.0),
            system: UInt32(ticks.1),
            idle: UInt32(ticks.2),
            nice: UInt32(ticks.3)
        )
    }

    private func coreTicks() -> [CPUTicks] {
        var processorCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &info,
            &infoCount
        )
        guard result == KERN_SUCCESS, let info else { return [] }
        defer {
            let size = vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: info)), size)
        }
        let states = Int(CPU_STATE_MAX)
        var ticks: [CPUTicks] = []
        ticks.reserveCapacity(Int(processorCount))
        for index in 0..<Int(processorCount) {
            let base = index * states
            func value(_ state: Int) -> UInt32 {
                UInt32(bitPattern: info[base + state])
            }
            ticks.append(CPUTicks(
                user: value(Int(CPU_STATE_USER)),
                system: value(Int(CPU_STATE_SYSTEM)),
                idle: value(Int(CPU_STATE_IDLE)),
                nice: value(Int(CPU_STATE_NICE))
            ))
        }
        return ticks
    }

    private func loadAverage() -> [Double] {
        var values = [Double](repeating: 0, count: 3)
        let count = getloadavg(&values, 3)
        guard count == 3 else { return [] }
        return values
    }

    private func gpuUsage() -> Double? {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }
        var readings: [Double] = []
        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }
            guard let dict = registryDictionary(service),
                  let stats = dict["PerformanceStatistics"] as? [String: Any] else { continue }
            let raw = number(stats["Device Utilization %"] ?? stats["Device Utilization"])
            guard raw > 0 else { continue }
            readings.append(raw > 1.5 ? raw / 100 : raw)
        }
        guard let peak = readings.max(), peak.isFinite else { return nil }
        return min(max(peak, 0), 1)
    }

    private func readMemory() -> MemorySnapshot {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) { pointer -> kern_return_t in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, rebound, &count)
            }
        }
        let page = UInt64(vm_kernel_page_size)
        let total = ProcessInfo.processInfo.physicalMemory
        guard result == KERN_SUCCESS else {
            return MemorySnapshot(
                total: total, used: 0, apps: 0, wired: 0, compressed: 0,
                cached: 0, free: 0, swapUsed: 0, pressure: .low
            )
        }
        let input = MemoryInput(
            total: total,
            pageSize: page,
            internalPages: UInt64(stats.internal_page_count),
            purgeablePages: UInt64(stats.purgeable_count),
            wiredPages: UInt64(stats.wire_count),
            compressedPages: UInt64(stats.compressor_page_count),
            externalPages: UInt64(stats.external_page_count),
            freePages: UInt64(stats.free_count),
            swapUsed: swapUsed()
        )
        return MetricMath.memorySnapshot(input)
    }

    private func swapUsed() -> UInt64 {
        var usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.stride
        let result = sysctlbyname("vm.swapusage", &usage, &size, nil, 0)
        guard result == 0 else { return 0 }
        return usage.xsu_used
    }

    private func readDisks() -> [DiskVolume] {
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey,
            .volumeIsLocalKey,
            .volumeIsBrowsableKey
        ]
        let urls = FileManager.default.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) ?? []
        var volumes: [DiskVolume] = []
        for url in urls {
            let values = try? url.resourceValues(forKeys: Set(keys))
            let name = values?.volumeName ?? url.lastPathComponent
            if name.isEmpty { continue }
            let blocked = ["Preboot", "Recovery", "VM", "Update", "xarts", "iSCPreboot", "Hardware"]
            if blocked.contains(name) { continue }
            let total = UInt64(values?.volumeTotalCapacity ?? 0)
            let available = UInt64(values?.volumeAvailableCapacityForImportantUsage ?? Int64(values?.volumeAvailableCapacity ?? 0))
            guard total > 0 else { continue }
            let mount = url.path
            if volumes.contains(where: { $0.mount == mount }) { continue }
            volumes.append(DiskVolume(name: name, mount: mount, total: total, available: min(available, total)))
        }
        return volumes.sorted { lhs, rhs in
            if lhs.mount == "/" { return true }
            if rhs.mount == "/" { return false }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func readDiskIO(elapsed: TimeInterval) -> Throughput {
        let totals = diskByteTotals()
        let throughput: Throughput
        if hasDiskBaseline {
            throughput = Throughput(
                downBytesPerSecond: MetricMath.ratePerSecond(previous: previousDiskRead, current: totals.read, elapsed: elapsed),
                upBytesPerSecond: MetricMath.ratePerSecond(previous: previousDiskWrite, current: totals.write, elapsed: elapsed)
            )
        } else {
            throughput = .zero
        }
        previousDiskRead = totals.read
        previousDiskWrite = totals.write
        hasDiskBaseline = true
        return throughput
    }

    private func diskByteTotals() -> (read: UInt64, write: UInt64) {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOBlockStorageDriver"), &iterator) == KERN_SUCCESS else {
            return (0, 0)
        }
        defer { IOObjectRelease(iterator) }
        var read: UInt64 = 0
        var write: UInt64 = 0
        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }
            guard let dict = registryDictionary(service) else { continue }
            let stats = (dict["Statistics"] as? [String: Any]) ?? dict
            read += numberUInt(stats["Bytes (Read)"])
            write += numberUInt(stats["Bytes (Write)"])
        }
        return (read, write)
    }

    private func readNetwork(elapsed: TimeInterval) -> (throughput: Throughput, interface: String?, ipv4: String?) {
        let totals = interfaceTotals()
        let throughput: Throughput
        if hasNetBaseline {
            let down = MetricMath.ratePerSecond(previous: previousNet.received, current: totals.received, elapsed: elapsed)
            let up = MetricMath.ratePerSecond(previous: previousNet.sent, current: totals.sent, elapsed: elapsed)
            throughput = Throughput(downBytesPerSecond: down, upBytesPerSecond: up)
        } else {
            throughput = .zero
        }
        previousNet = totals
        hasNetBaseline = true
        return (throughput, totals.primaryName, totals.ipv4)
    }

    private func interfaceTotals() -> InterfaceTotals {
        var pointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&pointer) == 0, let first = pointer else { return InterfaceTotals() }
        defer { freeifaddrs(pointer) }
        var received: UInt64 = 0
        var sent: UInt64 = 0
        var bestName: String?
        var bestBytes: UInt64 = 0
        var ipv4: String?
        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let current = cursor {
            let name = String(cString: current.pointee.ifa_name)
            if let address = current.pointee.ifa_addr, address.pointee.sa_family == UInt8(AF_LINK),
               includedInterface(name), let data = current.pointee.ifa_data {
                let network = data.assumingMemoryBound(to: if_data.self).pointee
                let rx = UInt64(network.ifi_ibytes)
                let tx = UInt64(network.ifi_obytes)
                received += rx
                sent += tx
                let volume = rx &+ tx
                if volume >= bestBytes {
                    bestBytes = volume
                    bestName = name
                }
            }
            if ipv4 == nil, name == "en0", let address = current.pointee.ifa_addr,
               address.pointee.sa_family == UInt8(AF_INET) {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let length = socklen_t(address.pointee.sa_len)
                if getnameinfo(address, length, &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                    ipv4 = String(cString: host)
                }
            }
            cursor = current.pointee.ifa_next
        }
        return InterfaceTotals(received: received, sent: sent, primaryName: bestName, ipv4: ipv4)
    }

    private func includedInterface(_ name: String) -> Bool {
        if name == "lo0" { return false }
        let blocked = ["awdl", "llw", "bridge", "gif", "stf", "utun", "ipsec", "ap1", "anpi", "pktap"]
        return !blocked.contains { name.hasPrefix($0) }
    }

    private func readBattery() -> BatterySnapshot? {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return nil }
        guard let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] else { return nil }
        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }
            let type = description[kIOPSTypeKey] as? String
            if type != kIOPSInternalBatteryType { continue }
            let current = number(description[kIOPSCurrentCapacityKey])
            let maxCapacity = number(description[kIOPSMaxCapacityKey])
            let fraction = maxCapacity > 0 ? min(max(current / maxCapacity, 0), 1) : 0
            let state = description[kIOPSPowerSourceStateKey] as? String
            let plugged = state == kIOPSACPowerValue
            let charging = boolValue(description[kIOPSIsChargingKey])
            let empty = intValue(description[kIOPSTimeToEmptyKey])
            let full = intValue(description[kIOPSTimeToFullChargeKey])
            let health = description[kIOPSBatteryHealthKey] as? String
            let registry = batteryRegistry()
            return BatterySnapshot(
                fraction: fraction,
                isCharging: charging,
                isPlugged: plugged,
                minutesRemaining: empty >= 0 ? empty : nil,
                minutesToFull: full >= 0 ? full : nil,
                health: health,
                cycleCount: registry.cycles,
                temperatureC: registry.temperature
            )
        }
        return nil
    }

    private func batteryRegistry() -> (cycles: Int?, temperature: Double?) {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return (nil, nil) }
        defer { IOObjectRelease(service) }
        guard let dict = registryDictionary(service) else { return (nil, nil) }
        let cycles = intIfPresent(dict["CycleCount"])
        let temperature = MetricMath.batteryCelsius(raw: number(dict["Temperature"]))
        return (cycles, temperature)
    }

    private func readProcesses(limit: Int) -> [ProcessSnapshot] {
        let now = mach_absolute_time()
        let elapsed = nanos(from: lastProcessSample, to: now)
        lastProcessSample = now
        let pidCount = proc_listpids(UInt32(PROC_ALL_PIDS), 0, nil, 0)
        guard pidCount > 0 else { return [] }
        let capacity = Int(pidCount) / MemoryLayout<pid_t>.stride + 16
        var pids = [pid_t](repeating: 0, count: capacity)
        let written = proc_listpids(UInt32(PROC_ALL_PIDS), 0, &pids, Int32(pids.count * MemoryLayout<pid_t>.stride))
        let count = max(0, Int(written) / MemoryLayout<pid_t>.stride)
        var current: [Int32: UInt64] = [:]
        var samples: [ProcessSnapshot] = []
        current.reserveCapacity(count)
        for index in 0..<min(count, pids.count) {
            let pid = pids[index]
            guard pid > 0 else { continue }
            var info = proc_taskinfo()
            let size = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(MemoryLayout<proc_taskinfo>.stride))
            guard size == Int32(MemoryLayout<proc_taskinfo>.stride) else { continue }
            let nanosUsed = info.pti_total_user &+ info.pti_total_system
            current[pid] = nanosUsed
            let fraction: Double
            if elapsed > 50_000_000, elapsed < 8_000_000_000, let previous = processCPU[pid] {
                fraction = MetricMath.processCPUFraction(
                    previousNanos: previous,
                    currentNanos: nanosUsed,
                    elapsedNanos: elapsed
                )
            } else {
                fraction = 0
            }
            var nameBuffer = [CChar](repeating: 0, count: 256)
            let nameLength = proc_name(pid, &nameBuffer, UInt32(nameBuffer.count))
            let name = nameLength > 0 ? String(cString: nameBuffer) : "Process \(pid)"
            let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty else { continue }
            samples.append(ProcessSnapshot(
                pid: pid,
                name: cleaned,
                cpuFractionOfOneCore: fraction,
                memory: info.pti_resident_size
            ))
        }
        processCPU = current
        return Array(samples.sorted { $0.cpuFractionOfOneCore > $1.cpuFractionOfOneCore }.prefix(max(limit, 0)))
    }

    private func readThermal() -> ThermalLevel {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return .nominal
        case .fair: return .fair
        case .serious: return .serious
        case .critical: return .critical
        @unknown default: return .nominal
        }
    }

    private func readUptime() -> TimeInterval {
        var boot = timeval()
        var size = MemoryLayout<timeval>.stride
        guard sysctlbyname("kern.boottime", &boot, &size, nil, 0) == 0 else { return 0 }
        return max(0, Date().timeIntervalSince1970 - TimeInterval(boot.tv_sec))
    }

    private func registryDictionary(_ service: io_registry_entry_t) -> [String: Any]? {
        var properties: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS else {
            return nil
        }
        return properties?.takeRetainedValue() as? [String: Any]
    }

    private func number(_ value: Any?) -> Double {
        switch value {
        case let number as NSNumber: return number.doubleValue
        case let number as Double: return number
        case let number as Int: return Double(number)
        case let number as UInt64: return Double(number)
        default: return 0
        }
    }

    private func numberUInt(_ value: Any?) -> UInt64 {
        switch value {
        case let number as NSNumber: return number.uint64Value
        case let number as UInt64: return number
        case let number as Int: return number > 0 ? UInt64(number) : 0
        default: return 0
        }
    }

    private func intValue(_ value: Any?) -> Int {
        switch value {
        case let number as NSNumber: return number.intValue
        case let number as Int: return number
        default: return -1
        }
    }

    private func intIfPresent(_ value: Any?) -> Int? {
        switch value {
        case let number as NSNumber: return number.intValue
        case let number as Int: return number
        default: return nil
        }
    }

    private func boolValue(_ value: Any?) -> Bool {
        switch value {
        case let number as NSNumber: return number.boolValue
        case let flag as Bool: return flag
        default: return false
        }
    }
}

private struct InterfaceTotals {
    var received: UInt64 = 0
    var sent: UInt64 = 0
    var primaryName: String?
    var ipv4: String?
}

private struct CoreLayout {
    var performance: Int
    var efficiency: Int

    static var current: CoreLayout {
        CoreLayout(
            performance: Self.sysctl("hw.perflevel0.logicalcpu") ?? 0,
            efficiency: Self.sysctl("hw.perflevel1.logicalcpu") ?? 0
        )
    }

    private static func sysctl(_ name: String) -> Int? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.stride
        guard sysctlbyname(name, &value, &size, nil, 0) == 0, value > 0 else { return nil }
        return Int(value)
    }
}

extension SystemIdentity {
    static func basic() -> SystemIdentity {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let os = "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        return SystemIdentity(
            computerName: Host.current().localizedName ?? ProcessInfo.processInfo.hostName,
            marketingName: sysctlString("hw.model") ?? "Mac",
            modelIdentifier: sysctlString("hw.model") ?? "",
            chip: sysctlString("machdep.cpu.brand_string") ?? "",
            osVersion: os,
            physicalMemory: ProcessInfo.processInfo.physicalMemory
        )
    }

    private static func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 1 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        let value = String(cString: buffer).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}


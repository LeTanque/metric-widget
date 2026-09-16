import Darwin

final class CPUSampler {
    private var previous = host_cpu_load_info()
    private var hasPrevious = false

    func usagePercent() -> Double {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride
        )
        let status = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, rebound, &count)
            }
        }
        guard status == KERN_SUCCESS else { return 0 }

        defer {
            previous = info
            hasPrevious = true
        }
        guard hasPrevious else { return 0 }

        let user = Double(info.cpu_ticks.0) - Double(previous.cpu_ticks.0)
        let system = Double(info.cpu_ticks.1) - Double(previous.cpu_ticks.1)
        let idle = Double(info.cpu_ticks.2) - Double(previous.cpu_ticks.2)
        let nice = Double(info.cpu_ticks.3) - Double(previous.cpu_ticks.3)
        let total = user + system + idle + nice
        guard total > 0 else { return 0 }
        return ((user + system + nice) / total) * 100.0
    }
}

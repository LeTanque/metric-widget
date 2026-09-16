import Darwin

enum MemorySampler {
    static func snapshot() -> (used: UInt64, total: UInt64, percent: Double) {
        var total: UInt64 = 0
        var length = MemoryLayout<UInt64>.size
        sysctlbyname("hw.memsize", &total, &length, nil, 0)

        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let status = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, rebound, &count)
            }
        }
        guard status == KERN_SUCCESS, pageSize > 0, total > 0 else {
            return (0, total, 0)
        }

        let usedPages = UInt64(stats.active_count)
            + UInt64(stats.wire_count)
            + UInt64(stats.compressor_page_count)
        let used = usedPages * UInt64(pageSize)
        let percent = min(100, Double(used) / Double(total) * 100)
        return (used, total, percent)
    }
}

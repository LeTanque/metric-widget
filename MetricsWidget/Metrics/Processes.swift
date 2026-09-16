import Darwin

enum ProcessSampler {
    private static let procAllPids: UInt32 = 1
    private static let procPIDTaskInfo: Int32 = 4

    static func top(limit: Int = 8) -> (items: [ProcessMemory], totalRSS: UInt64) {
        let needed = proc_listpids(procAllPids, 0, nil, 0)
        guard needed > 0 else { return ([], 0) }

        let capacity = Int(needed) / MemoryLayout<pid_t>.size
        var pids = [pid_t](repeating: 0, count: max(capacity, 1))
        let filled = proc_listpids(procAllPids, 0, &pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard filled > 0 else { return ([], 0) }

        let count = Int(filled) / MemoryLayout<pid_t>.size
        var items: [ProcessMemory] = []
        items.reserveCapacity(min(count, 256))
        var total: UInt64 = 0
        var nameBuf = [CChar](repeating: 0, count: 64)

        for index in 0..<count {
            let pid = pids[index]
            guard pid > 0 else { continue }

            var info = proc_taskinfo()
            let size = Int32(MemoryLayout<proc_taskinfo>.stride)
            let result = proc_pidinfo(pid, procPIDTaskInfo, 0, &info, size)
            guard result == size else { continue }

            let rss = UInt64(info.pti_resident_size)
            total += rss

            nameBuf.withUnsafeMutableBufferPointer { buffer in
                if let base = buffer.baseAddress {
                    _ = proc_name(pid, base, UInt32(buffer.count))
                }
            }
            let rawName = String(decoding: nameBuf.map { UInt8(bitPattern: $0) }.prefix { $0 != 0 }, as: UTF8.self)
            let name = rawName.isEmpty ? "pid \(pid)" : rawName
            items.append(ProcessMemory(pid: pid, name: name, rss: rss))
        }

        items.sort { $0.rss > $1.rss }
        if items.count > limit {
            items = Array(items.prefix(limit))
        }
        return (items, total)
    }
}

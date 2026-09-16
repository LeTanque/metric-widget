import Darwin

enum DiskSampler {
    static func snapshot() -> (used: UInt64, free: UInt64, total: UInt64) {
        var fs = statfs()
        guard statfs("/", &fs) == 0 else { return (0, 0, 0) }
        let block = UInt64(fs.f_bsize)
        let total = UInt64(fs.f_blocks) * block
        let free = UInt64(fs.f_bavail) * block
        let used = total > free ? total - free : 0
        return (used, free, total)
    }
}

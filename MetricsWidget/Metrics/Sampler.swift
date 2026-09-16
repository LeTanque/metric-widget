import Foundation

final class Sampler {
    private let network = NetworkSampler()
    private let cpu = CPUSampler()

    func sample() -> MetricsSnapshot {
        let cpuPercent = cpu.usagePercent()
        let ram = MemorySampler.snapshot()
        let disk = DiskSampler.snapshot()
        let net = network.sample()
        let procs = ProcessSampler.top(limit: 8)

        return MetricsSnapshot(
            cpuPercent: cpuPercent,
            ramUsedBytes: ram.used,
            ramTotalBytes: ram.total,
            ramPercent: ram.percent,
            diskUsedBytes: disk.used,
            diskFreeBytes: disk.free,
            diskTotalBytes: disk.total,
            interfaceName: net.interfaceName,
            localIP: net.localIP,
            publicIP: net.publicIP,
            uploadBytesPerSec: net.uploadBytesPerSec,
            downloadBytesPerSec: net.downloadBytesPerSec,
            networkHistory: net.history,
            processes: procs.items,
            processMemoryTotal: procs.totalRSS
        )
    }
}

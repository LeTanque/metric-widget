import Foundation

struct ProcessMemory: Identifiable, Hashable, Sendable {
    var id: Int32 { pid }
    var pid: Int32
    var name: String
    var rss: UInt64
}

struct NetworkPoint: Identifiable, Sendable {
    var id: Int
    var upload: Double
    var download: Double
}

struct MetricsSnapshot: Sendable {
    var cpuPercent: Double
    var ramUsedBytes: UInt64
    var ramTotalBytes: UInt64
    var ramPercent: Double
    var diskUsedBytes: UInt64
    var diskFreeBytes: UInt64
    var diskTotalBytes: UInt64
    var interfaceName: String
    var localIP: String
    var publicIP: String
    var uploadBytesPerSec: Double
    var downloadBytesPerSec: Double
    var networkHistory: [NetworkPoint]
    var processes: [ProcessMemory]
    var processMemoryTotal: UInt64

    static let empty = MetricsSnapshot(
        cpuPercent: 0,
        ramUsedBytes: 0,
        ramTotalBytes: 0,
        ramPercent: 0,
        diskUsedBytes: 0,
        diskFreeBytes: 0,
        diskTotalBytes: 0,
        interfaceName: "—",
        localIP: "—",
        publicIP: "—",
        uploadBytesPerSec: 0,
        downloadBytesPerSec: 0,
        networkHistory: [],
        processes: [],
        processMemoryTotal: 0
    )
}

enum ByteFormat {
    static func bytes(_ value: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: Int64(clamping: value))
    }

    static func perSecond(_ bytesPerSec: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.isAdaptive = true
        let clamped = max(0, bytesPerSec)
        return formatter.string(fromByteCount: Int64(clamped.rounded())) + "/s"
    }
}

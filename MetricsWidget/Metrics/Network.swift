import Darwin
import Foundation
import SystemConfiguration

struct NetworkReading: Sendable {
    var interfaceName: String
    var localIP: String
    var publicIP: String
    var uploadBytesPerSec: Double
    var downloadBytesPerSec: Double
    var history: [NetworkPoint]
}

final class NetworkSampler: @unchecked Sendable {
    private let historyLimit = 60
    private var lastIn: UInt64 = 0
    private var lastOut: UInt64 = 0
    private var lastUptime: TimeInterval = 0
    private var history: [NetworkPoint] = []
    private var nextIndex = 0
    private var publicIP = "—"
    private var lastPublicIPFetch = Date.distantPast
    private var publicIPInFlight = false

    func sample() -> NetworkReading {
        refreshPublicIPIfNeeded()

        let iface = Self.primaryInterface() ?? Self.firstUpInterface() ?? "en0"
        let stats = Self.interfaceStats(named: iface)
        let now = ProcessInfo.processInfo.systemUptime

        var upload: Double = 0
        var download: Double = 0
        if lastUptime > 0 {
            let dt = now - lastUptime
            if dt > 0 {
                download = Self.delta(from: lastIn, to: stats.bytesIn) / dt
                upload = Self.delta(from: lastOut, to: stats.bytesOut) / dt
            }
        }

        lastIn = stats.bytesIn
        lastOut = stats.bytesOut
        lastUptime = now

        history.append(NetworkPoint(id: nextIndex, upload: upload, download: download))
        nextIndex += 1
        if history.count > historyLimit {
            history.removeFirst(history.count - historyLimit)
        }

        return NetworkReading(
            interfaceName: iface,
            localIP: stats.ip,
            publicIP: publicIP,
            uploadBytesPerSec: upload,
            downloadBytesPerSec: download,
            history: history
        )
    }

    private static func delta(from old: UInt64, to new: UInt64) -> Double {
        if new >= old { return Double(new - old) }
        return Double(new)
    }

    private func refreshPublicIPIfNeeded() {
        let stale = Date().timeIntervalSince(lastPublicIPFetch) > 15 * 60
        let retrySoon = publicIP == "—" && Date().timeIntervalSince(lastPublicIPFetch) > 30
        guard stale || retrySoon, !publicIPInFlight else { return }

        publicIPInFlight = true
        lastPublicIPFetch = Date()
        guard let url = URL(string: "https://api.ipify.org") else {
            publicIPInFlight = false
            return
        }

        var request = URLRequest(url: url, timeoutInterval: 8)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self else { return }
            var next = "—"
            if let data, let text = String(data: data, encoding: .utf8) {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty, trimmed.count < 64, !trimmed.contains("<") {
                    next = trimmed
                }
            }
            DispatchQueue.main.async {
                self.publicIP = next
                self.publicIPInFlight = false
            }
        }.resume()
    }

    private static func primaryInterface() -> String? {
        guard let store = SCDynamicStoreCreate(nil, "MetricsWidget" as CFString, nil, nil) else {
            return nil
        }
        let key = "State:/Network/Global/IPv4" as CFString
        guard let value = SCDynamicStoreCopyValue(store, key) as? [String: Any] else {
            return nil
        }
        return value["PrimaryInterface"] as? String
    }

    private static func firstUpInterface() -> String? {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0 else { return nil }
        defer { freeifaddrs(ifaddrPtr) }

        var cursor = ifaddrPtr
        while let current = cursor {
            let name = String(cString: current.pointee.ifa_name)
            let flags = Int32(current.pointee.ifa_flags)
            let up = (flags & IFF_UP) != 0 && (flags & IFF_RUNNING) != 0 && (flags & IFF_LOOPBACK) == 0
            if up, let addr = current.pointee.ifa_addr, addr.pointee.sa_family == sa_family_t(AF_INET) {
                return name
            }
            cursor = current.pointee.ifa_next
        }
        return nil
    }

    private static func interfaceStats(named target: String) -> (ip: String, bytesIn: UInt64, bytesOut: UInt64) {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0 else { return ("—", 0, 0) }
        defer { freeifaddrs(ifaddrPtr) }

        var ip = "—"
        var bytesIn: UInt64 = 0
        var bytesOut: UInt64 = 0
        var cursor = ifaddrPtr
        while let current = cursor {
            let name = String(cString: current.pointee.ifa_name)
            if name == target, let addr = current.pointee.ifa_addr {
                if addr.pointee.sa_family == sa_family_t(AF_INET) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    let result = getnameinfo(
                        addr,
                        socklen_t(addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        0,
                        NI_NUMERICHOST
                    )
                    if result == 0 {
                        ip = String(decoding: hostname.map { UInt8(bitPattern: $0) }.prefix { $0 != 0 }, as: UTF8.self)
                    }
                } else if addr.pointee.sa_family == sa_family_t(AF_LINK), let data = current.pointee.ifa_data {
                    let ifdata = data.assumingMemoryBound(to: if_data.self).pointee
                    bytesIn = UInt64(ifdata.ifi_ibytes)
                    bytesOut = UInt64(ifdata.ifi_obytes)
                }
            }
            cursor = current.pointee.ifa_next
        }
        return (ip.isEmpty ? "—" : ip, bytesIn, bytesOut)
    }
}

import Foundation
import os

enum CursorTokenSource: String, Sendable {
    case keychain
    case stateDatabase
}

enum CursorTokenLookup: Sendable, Equatable {
    case token(String, CursorTokenSource)
    case encryptedInDatabase
    case missing
}

enum CursorAuthorizedResult {
    case response(Data, HTTPURLResponse, token: String)
    case encryptedInDatabase
    case missing
    case transportFailure
}

enum CursorAccessToken {
    static let keychainService = "cursor-access-token"
    static let keychainAccount = "cursor-user"
    static let databaseKey = "cursorAuth/accessToken"
    static let encryptedMessage = "Can’t read Cursor token (Cursor now encrypts it)"
    static let signInMessage = "Sign in to the Cursor app on this Mac"
    static let sessionExpiredMessage = "Session expired — sign in to Cursor again"

    private static let cache = CursorAccessTokenCache()
    private static let log = Logger(subsystem: "com.metricswidget.app", category: "cursor-auth")

    static func current() -> CursorTokenLookup {
        if let cached = cache.load() { return cached }
        let lookup = read()
        if case .token = lookup { cache.store(lookup) }
        return lookup
    }

    static func invalidate() {
        cache.store(nil)
    }

    static func read() -> CursorTokenLookup {
        if let stored = KeychainStore.password(account: keychainAccount, service: keychainService)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           isJWT(stored) {
            log.notice("token keychain present length \(stored.count, privacy: .public)")
            return .token(stored, .keychain)
        }
        log.notice("token keychain unavailable")
        guard let stored = CursorStateDatabase.value(forKey: databaseKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !stored.isEmpty
        else {
            log.notice("token database missing")
            return .missing
        }
        if isJWT(stored) {
            log.notice("token database present length \(stored.count, privacy: .public)")
            return .token(stored, .stateDatabase)
        }
        log.notice("token database encrypted length \(stored.count, privacy: .public)")
        return .encryptedInDatabase
    }

    static func isJWT(_ value: String) -> Bool {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        return parts.count == 3 && parts.allSatisfy { !$0.isEmpty }
    }

    static func perform(endpoint: String, _ makeRequest: (String) -> URLRequest) -> CursorAuthorizedResult {
        var lookup = current()
        var retried = false
        while true {
            let token: String
            switch lookup {
            case .token(let value, _): token = value
            case .encryptedInDatabase: return .encryptedInDatabase
            case .missing: return .missing
            }

            let response: URLResponse
            let data: Data
            do {
                (data, response) = try URLSession.shared.synchronousData(for: makeRequest(token))
            } catch {
                log.notice("\(endpoint, privacy: .public) transport failure")
                return .transportFailure
            }
            guard let http = response as? HTTPURLResponse else { return .transportFailure }
            log.notice("\(endpoint, privacy: .public) status \(http.statusCode, privacy: .public)")

            guard http.statusCode == 401 else { return .response(data, http, token: token) }
            invalidate()
            guard !retried else { return .response(data, http, token: token) }
            retried = true
            let fresh = read()
            guard case .token(let freshToken, _) = fresh, freshToken != token else {
                return .response(data, http, token: token)
            }
            cache.store(fresh)
            lookup = fresh
        }
    }
}

private final class CursorAccessTokenCache: @unchecked Sendable {
    private let lock = NSLock()
    private var lookup: CursorTokenLookup?

    func load() -> CursorTokenLookup? {
        lock.lock()
        defer { lock.unlock() }
        return lookup
    }

    func store(_ value: CursorTokenLookup?) {
        lock.lock()
        defer { lock.unlock() }
        lookup = value
    }
}

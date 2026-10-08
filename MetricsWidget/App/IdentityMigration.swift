import Foundation

enum AppIdentity {
    static let bundleID = "com.metricswidget.app"
    static let legacyBundleID = "com.frankmartinez.MetricsWidget"
}

enum IdentityMigration {
    private static let defaultsFlag = "identity.defaultsMigrated"

    static func runIfNeeded() {
        migrateUserDefaults()
        migrateKeychain()
    }

    private static func migrateUserDefaults() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: defaultsFlag) != nil {
            return
        }
        if let old = defaults.persistentDomain(forName: AppIdentity.legacyBundleID) {
            for (key, value) in old {
                if defaults.object(forKey: key) == nil {
                    defaults.set(value, forKey: key)
                }
            }
        }
        defaults.set(true, forKey: defaultsFlag)
    }

    private static func migrateKeychain() {
        let accounts = [KeychainAccount.openAI, KeychainAccount.anthropic]
        for account in accounts {
            if KeychainStore.hasPassword(account: account, service: KeychainStore.service) {
                continue
            }
            if let secret = KeychainStore.password(account: account, service: AppIdentity.legacyBundleID) {
                _ = KeychainStore.setPassword(secret, account: account, service: KeychainStore.service)
            }
        }
    }
}

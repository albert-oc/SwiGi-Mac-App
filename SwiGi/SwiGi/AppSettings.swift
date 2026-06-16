import Foundation

enum AppSettings {
    private static let launchAtLoginKey = "launchAtLogin"

    static var launchAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: launchAtLoginKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: launchAtLoginKey)
            LaunchAtLoginManager.setEnabled(newValue)
        }
    }

    static func applyStoredPreferences() {
        LaunchAtLoginManager.setEnabled(launchAtLogin)
    }
}

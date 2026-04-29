import Foundation
import Observation

@Observable
final class AppPreferences {
    var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: notifKey) }
    }
    var displayName: String {
        didSet { UserDefaults.standard.set(displayName, forKey: nameKey) }
    }

    private let notifKey = "mikoto.prefs.notifications"
    private let nameKey = "mikoto.prefs.displayName"

    init() {
        if UserDefaults.standard.object(forKey: notifKey) == nil {
            UserDefaults.standard.set(true, forKey: notifKey)
        }
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: notifKey)
        self.displayName = UserDefaults.standard.string(forKey: nameKey) ?? ""
    }
}

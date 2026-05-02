import Foundation
import Observation

@Observable
final class AppPreferences {
    var notificationsEnabled: Bool = true {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: notifKey) }
    }
    var displayName: String = "" {
        didSet { UserDefaults.standard.set(displayName, forKey: nameKey) }
    }

    private var userId: String?
    private var notifKey: String { "mikoto.prefs.\(userId ?? "default").notifications" }
    private var nameKey: String { "mikoto.prefs.\(userId ?? "default").displayName" }

    func switchUser(_ userId: String) {
        self.userId = userId
        if UserDefaults.standard.object(forKey: notifKey) == nil {
            UserDefaults.standard.set(true, forKey: notifKey)
        }
        notificationsEnabled = UserDefaults.standard.bool(forKey: notifKey)
        displayName = UserDefaults.standard.string(forKey: nameKey) ?? ""
    }
}

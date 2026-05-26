import Foundation
import Observation

/// User preferences for local notifications.
@MainActor
@Observable
final class NotificationConfig {
    static let shared = NotificationConfig()

    private enum Keys {
        static let repaymentRemindersEnabled = "notifications.repaymentRemindersEnabled"
        static let leadDays = "notifications.leadDays"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.repaymentRemindersEnabled = defaults.bool(forKey: Keys.repaymentRemindersEnabled)
        let storedLead = defaults.integer(forKey: Keys.leadDays)
        self.leadDays = storedLead == 0 ? 1 : storedLead
    }

    var repaymentRemindersEnabled: Bool {
        didSet { defaults.set(repaymentRemindersEnabled, forKey: Keys.repaymentRemindersEnabled) }
    }

    /// How many days before the due date to fire the reminder. Default 1.
    var leadDays: Int {
        didSet { defaults.set(leadDays, forKey: Keys.leadDays) }
    }
}

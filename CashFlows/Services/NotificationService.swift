import Foundation
import UserNotifications

/// Wraps `UNUserNotificationCenter` to schedule local reminders for
/// upcoming repayments. All operations are best-effort: any failure is
/// silently dropped so a notification permission denial or a Vision /
/// network hiccup never blocks the rest of the app.
@MainActor
enum NotificationService {
    private static let identifierPrefix = "repayment-"
    private static let threadIdentifier = "cashflows-repayment"
    private static let reminderHour = 9

    // MARK: - Permission

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Scheduling

    /// Cancels every previously scheduled repayment notification, then schedules
    /// a fresh batch from the supplied pending repayments.
    static func rescheduleAll(
        repayments: [Repayment],
        leadDays: Int = 1,
        now: Date = .now,
        calendar: Calendar = .current
    ) async {
        let center = UNUserNotificationCenter.current()
        await clearAllPending(center: center)

        let granted = await ensureAuthorized()
        guard granted else { return }

        for r in repayments {
            guard r.status == .pending, r.dueDate > now else { continue }
            guard let triggerDate = reminderTrigger(
                for: r.dueDate,
                leadDays: leadDays,
                now: now,
                calendar: calendar
            ) else { continue }

            let content = UNMutableNotificationContent()
            content.title = "\(r.debtPlan?.platform ?? "分期") 还款提醒"
            let amount = Money.format(cents: r.amountCents)
            let dueLabel = leadDays <= 1 ? "明天到期" : "\(leadDays) 天后到期"
            content.body = "\(dueLabel)：第 \(r.periodIndex) 期，应还 \(amount)"
            content.sound = .default
            content.threadIdentifier = threadIdentifier
            content.userInfo = ["repaymentPersistentID": r.persistentModelID.hashValue]

            let comps = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(
                identifier: identifier(for: r),
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    /// Cancels every pending repayment notification.
    static func cancelAll() async {
        await clearAllPending(center: UNUserNotificationCenter.current())
    }

    // MARK: - Helpers

    private static func identifier(for repayment: Repayment) -> String {
        "\(identifierPrefix)\(repayment.persistentModelID.hashValue)"
    }

    private static func clearAllPending(center: UNUserNotificationCenter) async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }
        if !ids.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private static func ensureAuthorized() async -> Bool {
        let status = await authorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return await requestAuthorization()
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private static func reminderTrigger(
        for dueDate: Date,
        leadDays: Int,
        now: Date,
        calendar: Calendar
    ) -> Date? {
        guard let dayBefore = calendar.date(byAdding: .day, value: -leadDays, to: dueDate) else {
            return nil
        }
        var comps = calendar.dateComponents([.year, .month, .day], from: dayBefore)
        comps.hour = reminderHour
        comps.minute = 0
        comps.second = 0
        guard let trigger = calendar.date(from: comps), trigger > now else { return nil }
        return trigger
    }
}

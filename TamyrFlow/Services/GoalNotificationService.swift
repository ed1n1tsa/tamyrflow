import Foundation
import UserNotifications

/// Schedules TamyrFlow local notifications (not Apple Reminders.app).
@MainActor
enum GoalNotificationService {
    private static let center = UNUserNotificationCenter.current()
    private static let progressId = "goals.progress.daily"

    @discardableResult
    static func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        @unknown default:
            return false
        }
    }

    static func rescheduleAll(goals: [Goal], completedCount: Int, totalCount: Int) async {
        await cancelAllGoalNotifications()
        guard totalCount > 0 else { return }

        let allowed = await requestAuthorizationIfNeeded()
        guard allowed else { return }

        for goal in goals where goal.remindersEnabled {
            await scheduleCategoryReminders(for: goal)
        }

        // Evening progress summary (21:00) — matches lock-screen mock.
        await scheduleProgressSummary(completed: completedCount, total: totalCount, hour: 21, minute: 0)
    }

    static func cancelAllGoalNotifications() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix("goals.") }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Category

    private static func scheduleCategoryReminders(for goal: Goal) async {
        guard let time = goal.reminderTime else { return }
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return }
        let hour = parts[0]
        let minute = parts[1]

        let days = goal.reminderDays.isEmpty ? Array(1...7) : goal.reminderDays
        let copy = copy(for: goal.category)

        for isoDay in days {
            var date = DateComponents()
            date.hour = hour
            date.minute = minute
            // ISO 1=Mon…7=Sun → Calendar 1=Sun…7=Sat
            date.weekday = isoWeekdayToCalendar(isoDay)

            let content = UNMutableNotificationContent()
            content.title = copy.title
            content.body = copy.body
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            let id = "goals.\(goal.id.uuidString).d\(isoDay)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    private static func scheduleProgressSummary(completed: Int, total: Int, hour: Int, minute: Int) async {
        var date = DateComponents()
        date.hour = hour
        date.minute = minute

        let content = UNMutableNotificationContent()
        content.title = L10n.Goals.notifyProgressTitle
        content.body = String(format: L10n.Goals.notifyProgressBody, completed, total)
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: progressId, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private static func isoWeekdayToCalendar(_ iso: Int) -> Int {
        // ISO: 1=Mon … 7=Sun → Calendar: 1=Sun, 2=Mon … 7=Sat
        iso == 7 ? 1 : iso + 1
    }

    private static func copy(for category: GoalCategory) -> (title: String, body: String) {
        switch category {
        case .water:
            return (L10n.Goals.notifyWaterTitle, L10n.Goals.notifyWaterBody)
        case .activity:
            return (L10n.Goals.notifyActivityTitle, L10n.Goals.notifyActivityBody)
        case .sleep:
            return (L10n.Goals.notifySleepTitle, L10n.Goals.notifySleepBody)
        case .steps:
            return (L10n.Goals.notifyStepsTitle, L10n.Goals.notifyStepsBody)
        case .weight:
            return (L10n.Goals.notifyWeightTitle, L10n.Goals.notifyWeightBody)
        }
    }
}

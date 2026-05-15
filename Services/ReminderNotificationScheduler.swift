import Foundation
import UserNotifications

enum ReminderNotificationScheduler {
    private static let prefix = "punaise."
    private static var isSelfTesting: Bool {
        CommandLine.arguments.contains("--self-test")
    }

    static func requestAuthorization(for reminders: [Reminder]) {
        guard !isSelfTesting else { return }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            refresh(reminders: reminders)
        }
    }

    static func refresh(reminders: [Reminder]) {
        guard !isSelfTesting else { return }

        let center = UNUserNotificationCenter.current()
        let identifiers = reminders.flatMap { reminder in
            [
                "\(prefix)\(reminder.id).pressure",
                "\(prefix)\(reminder.id).antiForget",
                "\(prefix)\(reminder.id).deadline"
            ]
        }

        center.removePendingNotificationRequests(withIdentifiers: identifiers)

        for reminder in reminders where !reminder.isArchived {
            schedulePressureNotification(for: reminder, center: center)
            scheduleAntiForgetNotification(for: reminder, center: center)
            scheduleDeadlineNotification(for: reminder, center: center)
        }
    }

    private static func schedulePressureNotification(for reminder: Reminder, center: UNUserNotificationCenter) {
        let triggerDate = reminder.deadline.addingTimeInterval(-PunaisePreferences.criticalLeadTime)
        guard triggerDate > Date().addingTimeInterval(30) else { return }

        let content = UNMutableNotificationContent()
        content.title = PunaiseL10n.string("Punaise critique")
        content.body = PunaiseLanguage.current == .english
            ? "\(reminder.displayTitle) is nearing its deadline."
            : "\(reminder.displayTitle) arrive bientôt à échéance."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
            repeats: false
        )

        center.add(
            UNNotificationRequest(
                identifier: "\(prefix)\(reminder.id).pressure",
                content: content,
                trigger: trigger
            )
        )
    }

    private static func scheduleAntiForgetNotification(for reminder: Reminder, center: UNUserNotificationCenter) {
        let triggerDate = reminder.deadline
            .addingTimeInterval(-PunaisePreferences.criticalLeadTime)
            .addingTimeInterval(30 * 60)

        guard reminder.isPinned,
              triggerDate > Date().addingTimeInterval(30),
              triggerDate < reminder.deadline else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = PunaiseL10n.string("Anti-oubli Punaise")
        content.body = PunaiseLanguage.current == .english
            ? "\(reminder.displayTitle) is critical and stays pinned."
            : "\(reminder.displayTitle) est critique et reste punaisée."
        content.sound = .defaultCritical

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate),
            repeats: false
        )

        center.add(
            UNNotificationRequest(
                identifier: "\(prefix)\(reminder.id).antiForget",
                content: content,
                trigger: trigger
            )
        )
    }

    private static func scheduleDeadlineNotification(for reminder: Reminder, center: UNUserNotificationCenter) {
        guard reminder.deadline > Date().addingTimeInterval(30) else { return }

        let content = UNMutableNotificationContent()
        content.title = PunaiseL10n.string("Échéance Punaise")
        content.body = PunaiseLanguage.current == .english
            ? "\(reminder.displayTitle) cannot wait anymore."
            : "\(reminder.displayTitle) ne peut plus attendre."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.deadline),
            repeats: false
        )

        center.add(
            UNNotificationRequest(
                identifier: "\(prefix)\(reminder.id).deadline",
                content: content,
                trigger: trigger
            )
        )
    }
}

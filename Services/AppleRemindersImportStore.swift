import AppKit
import EventKit
import SwiftUI

@MainActor
final class AppleRemindersImportStore: ObservableObject {
    @Published private(set) var authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
    @Published private(set) var candidates: [ReminderCandidate] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let eventStore = EKEventStore()

    var hasAccess: Bool {
        if authorizationStatus == .authorized {
            return true
        }

        if #available(macOS 14.0, *), authorizationStatus == .fullAccess {
            return true
        }

        return false
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func connect() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        guard !hasAccess else {
            refresh()
            return
        }

        errorMessage = nil

        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToReminders { [weak self] granted, error in
                Task { @MainActor in
                    self?.finishAccessRequest(granted: granted, error: error)
                }
            }
        } else {
            eventStore.requestAccess(to: .reminder) { [weak self] granted, error in
                Task { @MainActor in
                    self?.finishAccessRequest(granted: granted, error: error)
                }
            }
        }
    }

    func refresh(daysAhead: Int = 21) {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        guard hasAccess else {
            candidates = []
            return
        }

        isLoading = true
        errorMessage = nil

        let calendars = eventStore.calendars(for: .reminder)
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: Calendar.current.date(byAdding: .day, value: daysAhead, to: Date()),
            calendars: calendars
        )

        eventStore.fetchReminders(matching: predicate) { [weak self] reminders in
            Task { @MainActor in
                guard let self else { return }
                let fetched = (reminders ?? [])
                    .compactMap(self.makeCandidate(from:))
                    .filter(\.isDeadlineLike)
                    .sorted { first, second in
                        if first.deadlineScore != second.deadlineScore {
                            return first.deadlineScore > second.deadlineScore
                        }

                        return first.deadline < second.deadline
                    }
                    .prefix(80)

                self.candidates = Array(fetched)
                self.isLoading = false
            }
        }
    }

    func openReminderPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") {
            NSWorkspace.shared.open(url)
        }
    }

    private func finishAccessRequest(granted: Bool, error: Error?) {
        authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)

        if let error {
            errorMessage = error.localizedDescription
        }

        if granted || hasAccess {
            refresh()
        }
    }

    private func makeCandidate(from reminder: EKReminder) -> ReminderCandidate? {
        guard let deadline = date(from: reminder.dueDateComponents) else {
            return nil
        }

        let fallbackID = [
            reminder.calendar.calendarIdentifier,
            String(deadline.timeIntervalSince1970),
            reminder.title ?? ""
        ].joined(separator: "-")

        let identifier = reminder.calendarItemIdentifier.isEmpty ? fallbackID : reminder.calendarItemIdentifier

        return ReminderCandidate(
            id: identifier,
            title: reminder.title ?? "",
            notes: reminder.notes ?? "",
            listTitle: reminder.calendar.title,
            sourceTitle: reminder.calendar.source.title,
            deadline: deadline,
            priority: reminder.priority,
            url: reminder.url
        )
    }

    private func date(from components: DateComponents?) -> Date? {
        guard var components else { return nil }

        if components.hour == nil {
            components.hour = 18
            components.minute = 0
            components.second = 0
        }

        return Calendar.current.date(from: components)
    }
}

import AppKit
import EventKit
import SwiftUI

@MainActor
final class CalendarImportStore: ObservableObject {
    @Published private(set) var authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    @Published private(set) var events: [CalendarEventCandidate] = []
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

    var needsPermission: Bool {
        authorizationStatus == .notDetermined
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func connect() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        guard !hasAccess else {
            refresh()
            return
        }

        errorMessage = nil

        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                Task { @MainActor in
                    self?.finishAccessRequest(granted: granted, error: error)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                Task { @MainActor in
                    self?.finishAccessRequest(granted: granted, error: error)
                }
            }
        }
    }

    func refresh(daysAhead: Int = 14) {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        guard hasAccess else {
            events = []
            return
        }

        isLoading = true
        errorMessage = nil

        let calendar = Calendar.current
        let now = Date()
        let end = calendar.date(byAdding: .day, value: daysAhead, to: now) ?? now
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(
            withStart: now,
            end: end,
            calendars: calendars
        )

        let fetchedEvents = eventStore.events(matching: predicate)
            .filter { !$0.isDetached }
            .sorted { $0.startDate < $1.startDate }
            .map(makeCandidate(from:))
            .filter(\.isDeadlineLike)
            .prefix(80)

        events = Array(fetchedEvents)
        isLoading = false
    }

    func openCalendarPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }

    private func finishAccessRequest(granted: Bool, error: Error?) {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)

        if let error {
            errorMessage = error.localizedDescription
        }

        if granted || hasAccess {
            refresh()
        }
    }

    private func makeCandidate(from event: EKEvent) -> CalendarEventCandidate {
        let fallbackID = [
            event.calendar.calendarIdentifier,
            String(event.startDate.timeIntervalSince1970),
            event.title ?? ""
        ].joined(separator: "-")

        let identifier = event.calendarItemIdentifier.isEmpty ? fallbackID : event.calendarItemIdentifier

        return CalendarEventCandidate(
            id: identifier,
            title: event.title ?? "",
            notes: event.notes ?? "",
            calendarTitle: event.calendar.title,
            sourceTitle: event.calendar.source.title,
            startDate: event.startDate,
            endDate: event.endDate,
            isAllDay: event.isAllDay,
            location: event.location ?? "",
            url: event.url
        )
    }
}

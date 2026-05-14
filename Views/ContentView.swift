import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var store: ReminderStore
    @ObservedObject var desktopController: DesktopStickyController
    var initialSelection: Reminder.ID?

    @StateObject private var calendarImporter = CalendarImportStore()
    @StateObject private var remindersImporter = AppleRemindersImportStore()
    @State private var selectedID: Reminder.ID?
    @State private var searchText = ""
    @State private var filter: ReminderFilter = .all
    @State private var showsCalendarImport = false
    @State private var showsRemindersImport = false
    @AppStorage(PunaisePreferenceKey.focusUrgenciesOnDesktop) private var focusUrgenciesOnDesktop = false
    @AppStorage(PunaisePreferenceKey.adaptiveDesktop) private var adaptiveDesktop = true
    @AppStorage(PunaisePreferenceKey.autoCleanDesktop) private var autoCleanDesktop = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let visibleReminders = filteredReminders(at: timeline.date)

            HStack(spacing: 0) {
                SidebarView(
                    reminders: visibleReminders,
                    allReminders: store.reminders,
                    selectedID: $selectedID,
                    searchText: $searchText,
                    filter: $filter,
                    now: timeline.date
                )
                .frame(width: 322)

                Divider()
                    .opacity(0.4)

                EditorPane(
                    selectedID: selectedID,
                    store: store,
                    desktopController: desktopController,
                    filter: filter,
                    visibleReminders: visibleReminders,
                    now: timeline.date,
                    onCreate: createReminder,
                    onCreateFromTemplate: createReminder(from:),
                    onCreateFromNaturalLanguage: createReminder(fromNaturalLanguage:),
                    onOpenCalendarImport: {
                        showsCalendarImport = true
                    },
                    onOpenRemindersImport: {
                        showsRemindersImport = true
                    },
                    onCleanDesktop: cleanDesktop,
                    onDelete: deleteSelected,
                    onDuplicate: duplicateSelected,
                    onPostpone: postponeSelected,
                    onComplete: completeSelected
                )
            }
            .background(appBackground)
        }
        .sheet(isPresented: $showsCalendarImport) {
            CalendarImportSheet(
                importer: calendarImporter,
                onImport: importCalendarEvents
            )
        }
        .sheet(isPresented: $showsRemindersImport) {
            AppleRemindersImportSheet(
                importer: remindersImporter,
                onImport: importAppleReminders
            )
        }
        .onAppear(perform: configureOpenHandler)
        .onAppear(perform: syncDesktopPreferences)
        .onChange(of: focusUrgenciesOnDesktop) { _ in
            syncDesktopPreferences()
        }
        .onChange(of: adaptiveDesktop) { _ in
            syncDesktopPreferences()
        }
        .onChange(of: autoCleanDesktop) { _ in
            syncDesktopPreferences()
        }
        .onChange(of: filter) { _ in
            selectedID = filteredReminders(at: Date()).first?.id ?? store.reminders.first?.id
        }
        .onChange(of: store.reminders) { _ in
            if autoCleanDesktop {
                desktopController.cleanDesktop(in: store)
            }
            reconcileSelection()
        }
        .onReceive(NotificationCenter.default.publisher(for: .postitSelectReminder)) { notification in
            selectedID = notification.object as? Reminder.ID
        }
        .onReceive(NotificationCenter.default.publisher(for: .postitOpenCalendarImport)) { _ in
            showsCalendarImport = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .postitOpenRemindersImport)) { _ in
            showsRemindersImport = true
        }
    }

    private var appBackground: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(red: 0.92, green: 0.88, blue: 0.80).opacity(0.38),
                Color(nsColor: .windowBackgroundColor)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func configureOpenHandler() {
        if selectedID == nil {
            selectedID = initialSelection ?? store.reminders.first?.id
        }

        desktopController.onOpenReminder = { id in
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows
                .first(where: { $0.styleMask.contains(.titled) && $0.title == "Punaise" })
                .map { $0.makeKeyAndOrderFront(nil) }
            store.markOpened(id)
            selectedID = id
        }
    }

    private func syncDesktopPreferences() {
        desktopController.focusesUrgenciesOnly = focusUrgenciesOnDesktop
        desktopController.usesAdaptiveDesk = adaptiveDesktop
        if autoCleanDesktop {
            desktopController.cleanDesktop(in: store)
        }
    }

    private func filteredReminders(at now: Date) -> [Reminder] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return store.reminders.filter { reminder in
            guard filter.matches(reminder, now: now) else { return false }
            guard !query.isEmpty else { return true }
            return reminder.title.lowercased().contains(query)
                || reminder.note.lowercased().contains(query)
        }
    }

    private func createReminder() {
        let reminder = store.createReminder()
        selectedID = reminder.id
        desktopController.pin(reminder.id, in: store)
    }

    private func createReminder(from template: PunaiseTemplate) {
        let reminder = store.createReminder(from: template)
        selectedID = reminder.id
        desktopController.pin(reminder.id, in: store)
    }

    private func createReminder(fromNaturalLanguage input: String) {
        guard let reminder = store.createReminder(fromNaturalLanguage: input) else { return }
        selectedID = reminder.id
        desktopController.pin(reminder.id, in: store)
    }

    private func importCalendarEvents(_ events: [CalendarEventCandidate]) {
        var importedIDs: [Reminder.ID] = []

        for event in events {
            let reminder = store.createOrUpdateReminder(fromCalendarEvent: event)
            importedIDs.append(reminder.id)

            if event.shouldPinByDefault {
                desktopController.pin(reminder.id, in: store)
            }
        }

        selectedID = importedIDs.first ?? selectedID
        filter = .all
    }

    private func importAppleReminders(_ candidates: [ReminderCandidate]) {
        var importedIDs: [Reminder.ID] = []

        for candidate in candidates {
            let reminder = store.createOrUpdateReminder(fromAppleReminder: candidate)
            importedIDs.append(reminder.id)

            if candidate.shouldPinByDefault {
                desktopController.pin(reminder.id, in: store)
            }
        }

        selectedID = importedIDs.first ?? selectedID
        filter = .all
    }

    private func cleanDesktop() {
        desktopController.cleanDesktop(in: store)
    }

    private func deleteSelected() {
        guard let selectedID else { return }
        store.delete(selectedID)
        self.selectedID = store.reminders.first?.id
    }

    private func duplicateSelected() {
        guard let selectedID, let copy = store.duplicate(selectedID) else { return }
        self.selectedID = copy.id
        desktopController.pin(copy.id, in: store)
    }

    private func postponeSelected() {
        guard let selectedID else { return }
        store.postpone(selectedID)
    }

    private func completeSelected() {
        guard let selectedID else { return }
        store.complete(selectedID)
        self.selectedID = store.reminders.first?.id
    }

    private func reconcileSelection() {
        if let selectedID, store.reminder(id: selectedID) != nil {
            return
        }

        selectedID = store.reminders.first?.id
    }
}

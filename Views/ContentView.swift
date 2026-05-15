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
    @State private var showsLicenseSheet = false
    @State private var lockedFeature: PunaiseProFeature = .unlimitedPunaises
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(PunaisePreferenceKey.appearance) private var appearance = PunaiseAppearancePreference.system.rawValue
    @AppStorage(PunaisePreferenceKey.focusUrgenciesOnDesktop) private var focusUrgenciesOnDesktop = false
    @AppStorage(PunaisePreferenceKey.adaptiveDesktop) private var adaptiveDesktop = true
    @AppStorage(PunaisePreferenceKey.autoCleanDesktop) private var autoCleanDesktop = false
    @AppStorage(PunaisePreferenceKey.language) private var language = PunaiseLanguage.default.rawValue
    @AppStorage(PunaisePreferenceKey.licenseKey) private var licenseKey = ""

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
                    now: timeline.date,
                    isPro: isPro,
                    activeCount: store.activeReminderCount,
                    onCleanDesktop: cleanDesktop,
                    onShowLicense: showLicense,
                    onTogglePin: togglePinnedFromSidebar,
                    onComplete: completeFromSidebar
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
                    isPro: isPro,
                    activeCount: store.activeReminderCount,
                    onCreate: createReminder,
                    onCreateFromTemplate: createReminder(from:),
                    onCreateFromNaturalLanguage: createReminder(fromNaturalLanguage:),
                    onOpenCalendarImport: openCalendarImport,
                    onOpenRemindersImport: openRemindersImport,
                    onCleanDesktop: cleanDesktop,
                    onShowLicense: showLicense,
                    onDelete: deleteSelected,
                    onDuplicate: duplicateSelected,
                    onPostpone: postponeSelected,
                    onComplete: completeSelected
                )
            }
            .background(appBackground)
        }
        .punaiseLocale(language)
        .punaisePreferredAppearance(appearance)
        .tint(PunaiseTheme(colorScheme: colorScheme).accent)
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
        .sheet(isPresented: $showsLicenseSheet) {
            LicenseActivationSheet(feature: lockedFeature, isPresented: $showsLicenseSheet)
        }
        .onAppear(perform: configureOpenHandler)
        .onAppear {
            store.localizeGeneratedDefaultTitlesForCurrentLanguage()
        }
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
        .onChange(of: language) { _ in
            store.localizeGeneratedDefaultTitlesForCurrentLanguage()
            NotificationCenter.default.post(name: .punaiseLanguageDidChange, object: nil)
        }
        .onChange(of: licenseKey) { _ in
            NotificationCenter.default.post(name: .punaiseLicenseDidChange, object: nil)
            syncDesktopPreferences()
        }
        .onChange(of: filter) { _ in
            selectedID = filteredReminders(at: Date()).first?.id ?? store.reminders.first?.id
        }
        .onChange(of: store.reminders) { _ in
            if isPro && autoCleanDesktop && !desktopController.consumeAutomaticCleanSkipAfterManualMove() {
                desktopController.cleanDesktop(in: store)
            }
            reconcileSelection()
        }
        .onReceive(NotificationCenter.default.publisher(for: .postitSelectReminder)) { notification in
            selectedID = notification.object as? Reminder.ID
        }
        .onReceive(NotificationCenter.default.publisher(for: .postitOpenCalendarImport)) { _ in
            openCalendarImport()
        }
        .onReceive(NotificationCenter.default.publisher(for: .postitOpenRemindersImport)) { _ in
            openRemindersImport()
        }
        .onReceive(NotificationCenter.default.publisher(for: .punaiseShowLicense)) { notification in
            let feature = notification.object as? PunaiseProFeature ?? .unlimitedPunaises
            showLicense(feature)
        }
    }

    private var isPro: Bool {
        PunaiseLicense.isValid(licenseKey)
    }

    private var appBackground: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        return Group {
            if theme.isDark {
                ZStack {
                    LinearGradient(
                        colors: [
                        Color(red: 0.035, green: 0.040, blue: 0.050),
                        Color(red: 0.060, green: 0.072, blue: 0.084),
                        Color(red: 0.040, green: 0.046, blue: 0.054)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    LinearGradient(
                        colors: [
                            theme.accent.opacity(0.10),
                            .clear,
                            theme.linkBlue.opacity(0.07)
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                }
            } else {
                Color.white
            }
        }
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
        desktopController.focusesUrgenciesOnly = isPro && focusUrgenciesOnDesktop
        desktopController.usesAdaptiveDesk = isPro && adaptiveDesktop
        if isPro && autoCleanDesktop && !desktopController.consumeAutomaticCleanSkipAfterManualMove() {
            desktopController.cleanDesktop(in: store)
        }
    }

    private func filteredReminders(at now: Date) -> [Reminder] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return store.reminders.filter { reminder in
            guard filter.matches(reminder, now: now) else { return false }
            guard !query.isEmpty else { return true }

            let searchableText = [
                reminder.title,
                reminder.note,
                reminder.project,
                reminder.tagLine,
                reminder.externalSource?.provider.title ?? "",
                reminder.externalSource?.title ?? "",
                reminder.attachments.map { "\($0.displayTitle) \($0.target)" }.joined(separator: " ")
            ]
            .joined(separator: " ")
            .lowercased()

            return searchableText.contains(query)
        }
    }

    private func createReminder() {
        guard canCreateReminder() else { return }
        let reminder = store.createReminder()
        selectedID = reminder.id
        desktopController.pin(reminder.id, in: store)
    }

    private func createReminder(from template: PunaiseTemplate) {
        guard requirePro(.templates), canCreateReminder() else { return }
        let reminder = store.createReminder(from: template)
        selectedID = reminder.id
        desktopController.pin(reminder.id, in: store)
    }

    private func createReminder(fromNaturalLanguage input: String) {
        guard requirePro(.naturalCapture), canCreateReminder() else { return }
        guard let reminder = store.createReminder(fromNaturalLanguage: input) else { return }
        selectedID = reminder.id
        desktopController.pin(reminder.id, in: store)
    }

    private func importCalendarEvents(_ events: [CalendarEventCandidate]) {
        guard requirePro(.imports) else { return }
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
        guard requirePro(.imports) else { return }
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
        guard requirePro(.smartDesktop) else { return }
        desktopController.cleanDesktop(in: store)
    }

    private func deleteSelected() {
        guard let selectedID else { return }
        store.delete(selectedID)
        self.selectedID = store.reminders.first?.id
    }

    private func duplicateSelected() {
        guard canCreateReminder() else { return }
        guard let selectedID, let copy = store.duplicate(selectedID) else { return }
        self.selectedID = copy.id
        desktopController.pin(copy.id, in: store)
    }

    private func postponeSelected() {
        guard let selectedID else { return }
        store.postpone(selectedID, by: .hour, value: 1)
    }

    private func completeSelected() {
        guard let selectedID else { return }
        store.complete(selectedID)
        self.selectedID = store.reminders.first?.id
    }

    private func togglePinnedFromSidebar(_ id: Reminder.ID) {
        guard let reminder = store.reminder(id: id) else { return }

        if reminder.isPinned {
            store.setPinned(id, isPinned: false)
        } else {
            desktopController.pin(id, in: store)
        }
    }

    private func openCalendarImport() {
        guard requirePro(.imports) else { return }
        showsCalendarImport = true
    }

    private func openRemindersImport() {
        guard requirePro(.imports) else { return }
        showsRemindersImport = true
    }

    private func canCreateReminder() -> Bool {
        if isPro || store.activeReminderCount < PunaiseLicense.freeActiveLimit {
            return true
        }

        showLicense(.unlimitedPunaises)
        return false
    }

    @discardableResult
    private func requirePro(_ feature: PunaiseProFeature) -> Bool {
        if isPro {
            return true
        }

        showLicense(feature)
        return false
    }

    private func showLicense(_ feature: PunaiseProFeature) {
        lockedFeature = feature
        showsLicenseSheet = true
    }

    private func completeFromSidebar(_ id: Reminder.ID) {
        store.complete(id)
        if selectedID == id {
            selectedID = store.reminders.first?.id
        }
    }

    private func reconcileSelection() {
        if let selectedID, store.reminder(id: selectedID) != nil {
            return
        }

        selectedID = store.reminders.first?.id
    }
}

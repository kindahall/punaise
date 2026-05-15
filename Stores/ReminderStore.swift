import Foundation

@MainActor
final class ReminderStore: ObservableObject {
    @Published private(set) var reminders: [Reminder] = [] {
        didSet {
            guard hasLoaded else { return }
            save()
            ReminderNotificationScheduler.refresh(reminders: reminders)
        }
    }

    private let storageURL: URL
    private var hasLoaded = false

    var activeReminderCount: Int {
        reminders.filter { !$0.isArchived }.count
    }

    init(storageURL: URL? = nil) {
        self.storageURL = storageURL ?? Self.defaultStorageURL()
        load()
        ReminderNotificationScheduler.refresh(reminders: reminders)
    }

    func createReminder(
        title: String? = nil,
        note: String = "",
        deadline: Date = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
        urgency: Urgency = .neutral,
        isPinned: Bool = false,
        project: String = "",
        tags: [String] = [],
        template: PunaiseTemplate? = nil,
        attachments: [PunaiseAttachment] = [],
        recurrence: RecurrenceRule = .none
    ) -> Reminder {
        let resolvedTitle = title ?? PunaiseL10n.string("Nouvelle Punaise")
        let reminder = Reminder(
            title: resolvedTitle,
            note: note,
            deadline: deadline,
            urgency: urgency,
            isPinned: isPinned,
            project: project,
            tags: tags,
            template: template,
            attachment: attachments.first,
            attachments: attachments,
            recurrence: recurrence
        )
        reminders.insert(reminder, at: 0)
        return reminder
    }

    func localizeGeneratedDefaultTitlesForCurrentLanguage() {
        let generatedTitles = [
            "Nouvelle Punaise",
            "New Punaise"
        ]
        let localizedTitle = PunaiseL10n.string("Nouvelle Punaise")
        var didChange = false

        for index in reminders.indices where generatedTitles.contains(reminders[index].title) {
            guard reminders[index].title != localizedTitle else { continue }
            reminders[index].title = localizedTitle
            reminders[index].updatedAt = Date()
            didChange = true
        }

        if didChange {
            sortReminders()
        }
    }

    func createReminder(from template: PunaiseTemplate) -> Reminder {
        let deadline = Calendar.current.date(byAdding: .day, value: template == .appel ? 1 : 2, to: Date()) ?? Date()
        return createReminder(
            title: template.defaultTitle,
            note: template.defaultNote,
            deadline: deadline,
            urgency: template.defaultUrgency,
            isPinned: true,
            tags: template.defaultTags,
            template: template
        )
    }

    func createReminder(fromNaturalLanguage input: String) -> Reminder? {
        guard let draft = NaturalPunaiseParser.parse(input) else { return nil }
        return createReminder(
            title: draft.title,
            note: draft.note,
            deadline: draft.deadline,
            urgency: draft.urgency,
            isPinned: true,
            tags: draft.tags,
            template: draft.template,
            attachments: draft.attachments
        )
    }

    func createOrUpdateReminder(fromCalendarEvent event: CalendarEventCandidate) -> Reminder {
        if let existingIndex = reminders.firstIndex(where: { reminder in
            reminder.externalSource?.provider == .googleCalendar
                && reminder.externalSource?.identifier == event.id
        }) {
            let reminderID = reminders[existingIndex].id
            reminders[existingIndex].title = event.displayTitle
            reminders[existingIndex].note = event.generatedNote
            reminders[existingIndex].deadline = event.deadline
            reminders[existingIndex].urgency = event.suggestedUrgency
            reminders[existingIndex].project = event.calendarTitle
            reminders[existingIndex].tags = calendarTags(for: event)
            reminders[existingIndex].updatedAt = Date()
            reminders[existingIndex].externalSource?.title = event.calendarTitle
            reminders[existingIndex].externalSource?.importedAt = Date()
            mergeCalendarAttachment(for: existingIndex, event: event)
            sortReminders()
            return reminders.first { $0.id == reminderID } ?? reminders[0]
        }

        let attachment = calendarAttachment(for: event)
        let reminder = Reminder(
            title: event.displayTitle,
            note: event.generatedNote,
            deadline: event.deadline,
            urgency: event.suggestedUrgency,
            isPinned: event.shouldPinByDefault,
            project: event.calendarTitle,
            tags: calendarTags(for: event),
            attachment: attachment,
            attachments: attachment.map { [$0] } ?? [],
            externalSource: ReminderExternalSource(
                provider: .googleCalendar,
                identifier: event.id,
                title: event.calendarTitle,
                importedAt: Date()
            )
        )
        reminders.insert(reminder, at: 0)
        sortReminders()
        return reminder
    }

    func createOrUpdateReminder(fromAppleReminder candidate: ReminderCandidate) -> Reminder {
        if let existingIndex = reminders.firstIndex(where: { reminder in
            reminder.externalSource?.provider == .appleReminders
                && reminder.externalSource?.identifier == candidate.id
        }) {
            let reminderID = reminders[existingIndex].id
            reminders[existingIndex].title = candidate.displayTitle
            reminders[existingIndex].note = candidate.generatedNote
            reminders[existingIndex].deadline = candidate.deadline
            reminders[existingIndex].urgency = candidate.suggestedUrgency
            reminders[existingIndex].project = candidate.listTitle
            reminders[existingIndex].tags = reminderTags(for: candidate)
            reminders[existingIndex].updatedAt = Date()
            reminders[existingIndex].externalSource?.title = candidate.listTitle
            reminders[existingIndex].externalSource?.importedAt = Date()
            mergeReminderAttachment(for: existingIndex, candidate: candidate)
            sortReminders()
            return reminders.first { $0.id == reminderID } ?? reminders[0]
        }

        let attachment = reminderAttachment(for: candidate)
        let reminder = Reminder(
            title: candidate.displayTitle,
            note: candidate.generatedNote,
            deadline: candidate.deadline,
            urgency: candidate.suggestedUrgency,
            isPinned: candidate.shouldPinByDefault,
            project: candidate.listTitle,
            tags: reminderTags(for: candidate),
            attachment: attachment,
            attachments: attachment.map { [$0] } ?? [],
            externalSource: ReminderExternalSource(
                provider: .appleReminders,
                identifier: candidate.id,
                title: candidate.listTitle,
                importedAt: Date()
            )
        )
        reminders.insert(reminder, at: 0)
        sortReminders()
        return reminder
    }

    func reminder(id: Reminder.ID?) -> Reminder? {
        guard let id else { return nil }
        return reminders.first(where: { $0.id == id })
    }

    func update(_ id: Reminder.ID, mutate: (inout Reminder) -> Void) {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else { return }
        mutate(&reminders[index])
        reminders[index].updatedAt = Date()
        sortReminders()
    }

    func setPinned(_ id: Reminder.ID, isPinned: Bool, position: DesktopPosition? = nil) {
        update(id) { reminder in
            reminder.isPinned = isPinned
            if let position {
                reminder.desktopPosition = position
            }
        }
    }

    func setDesktopPosition(_ id: Reminder.ID, position: DesktopPosition) {
        if let current = reminder(id: id)?.desktopPosition,
           abs(current.x - position.x) <= 1,
           abs(current.y - position.y) <= 1 {
            return
        }

        update(id) { reminder in
            reminder.desktopPosition = position
        }
    }

    func markOpened(_ id: Reminder.ID) {
        update(id) { reminder in
            reminder.lastOpenedAt = Date()
        }
    }

    func setTags(_ id: Reminder.ID, from text: String) {
        update(id) { reminder in
            reminder.tags = text
                .split { $0 == "," || $0 == " " || $0 == "#" }
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        }
    }

    func setAttachment(_ id: Reminder.ID, kind: AttachmentKind, target: String, title: String = "") {
        update(id) { reminder in
            let trimmedTarget = target.trimmingCharacters(in: .whitespacesAndNewlines)
            let attachment = trimmedTarget.isEmpty ? nil : PunaiseAttachment(
                title: title,
                target: trimmedTarget,
                kind: kind
            )
            reminder.attachment = attachment
            reminder.attachments = attachment.map { [$0] } ?? []
        }
    }

    func addAttachment(_ id: Reminder.ID, kind: AttachmentKind, target: String, title: String = "") {
        update(id) { reminder in
            let trimmedTarget = target.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTarget.isEmpty else { return }

            if reminder.attachments.contains(where: { $0.kind == kind && $0.target == trimmedTarget }) {
                return
            }

            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
            let displayTitle = trimmedTitle.isEmpty ? Self.attachmentTitle(for: trimmedTarget, kind: kind) : trimmedTitle
            reminder.attachments.append(
                PunaiseAttachment(
                    title: displayTitle,
                    target: trimmedTarget,
                    kind: kind
                )
            )
            reminder.attachment = reminder.attachments.first
        }
    }

    func removeAttachment(_ id: Reminder.ID, attachmentID: PunaiseAttachment.ID) {
        update(id) { reminder in
            reminder.attachments.removeAll { $0.id == attachmentID }
            reminder.attachment = reminder.attachments.first
        }
    }

    func duplicate(_ id: Reminder.ID) -> Reminder? {
        guard let source = reminder(id: id) else { return nil }
        var copy = source
        copy.id = UUID()
        copy.title = PunaiseLanguage.current == .english ? "\(source.displayTitle) copy" : "\(source.displayTitle) copie"
        copy.createdAt = Date()
        copy.updatedAt = Date()
        copy.desktopPosition = nil
        copy.isArchived = false
        copy.completedAt = nil
        copy.postponeCount = 0
        reminders.insert(copy, at: 0)
        return copy
    }

    func delete(_ id: Reminder.ID) {
        reminders.removeAll { $0.id == id }
    }

    func complete(_ id: Reminder.ID) {
        update(id) { reminder in
            if let nextDate = reminder.recurrence.nextDate(after: max(reminder.deadline, Date())) {
                reminder.deadline = nextDate
                reminder.postponeCount = 0
                reminder.completedAt = nil
                reminder.isArchived = false
            } else {
                reminder.isArchived = true
                reminder.isPinned = false
                reminder.completedAt = Date()
            }
        }
    }

    func postpone(_ id: Reminder.ID, by component: Calendar.Component = .day, value: Int = 1) {
        update(id) { reminder in
            let base = max(reminder.deadline, Date())
            reminder.deadline = Calendar.current.date(byAdding: component, value: value, to: base) ?? reminder.deadline
            reminder.isArchived = false
            reminder.postponeCount += 1
        }
    }

    func cycleQuickDeadline(_ id: Reminder.ID, now: Date = Date()) {
        update(id) { reminder in
            reminder.deadline = Self.nextQuickDeadline(after: reminder.deadline, now: now)
            reminder.isArchived = false
        }
    }

    func toggleArchived(_ id: Reminder.ID) {
        update(id) { reminder in
            reminder.isArchived.toggle()
            if reminder.isArchived {
                reminder.isPinned = false
                reminder.completedAt = Date()
            } else {
                reminder.completedAt = nil
            }
        }
    }

    private static func nextQuickDeadline(after currentDeadline: Date, now: Date) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        func candidate(dayOffset: Int, hour: Int) -> Date {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
        }

        let candidates = [
            candidate(dayOffset: 0, hour: 18),
            candidate(dayOffset: 1, hour: 9),
            candidate(dayOffset: 1, hour: 18),
            candidate(dayOffset: 7, hour: 9)
        ]

        if let currentIndex = candidates.firstIndex(where: { abs($0.timeIntervalSince(currentDeadline)) < 60 }) {
            for offset in 1...candidates.count {
                let next = candidates[(currentIndex + offset) % candidates.count]
                if next > now {
                    return next
                }
            }
        }

        if let nextAfterCurrent = candidates.first(where: { $0 > currentDeadline && $0 > now }) {
            return nextAfterCurrent
        }

        return candidates.first(where: { $0 > now }) ?? candidate(dayOffset: 1, hour: 9)
    }

    func resetToExamples() {
        reminders = []
    }

    var secureBackupStatus: SecureBackupStatus {
        SecureBackupService.backupStatus(storageURL: storageURL)
    }

    func writeSecureBackupNow() -> SecureBackupMessage {
        do {
            let urls = try SecureBackupService.writeBackups(reminders: reminders, storageURL: storageURL)
            if urls.isEmpty {
                return SecureBackupMessage(
                    title: PunaiseL10n.string("Sauvegarde désactivée"),
                    detail: PunaiseL10n.string("Active la sauvegarde chiffrée pour créer un fichier sécurisé.")
                )
            }

            return SecureBackupMessage(
                title: PunaiseL10n.string("Sauvegarde chiffrée prête"),
                detail: PunaiseLanguage.current == .english
                    ? "\(urls.count) location\(urls.count > 1 ? "s" : "") updated."
                    : "\(urls.count) emplacement\(urls.count > 1 ? "s" : "") mis à jour."
            )
        } catch {
            return SecureBackupMessage(
                title: PunaiseL10n.string("Sauvegarde impossible"),
                detail: error.localizedDescription
            )
        }
    }

    func syncFromICloudDriveBackup() -> SecureBackupMessage {
        do {
            guard SecureBackupService.iCloudDriveBackupURL() != nil else {
                return SecureBackupMessage(
                    title: PunaiseL10n.string("iCloud Drive indisponible"),
                    detail: PunaiseL10n.string("Active iCloud Drive sur ce Mac pour utiliser la synchronisation.")
                )
            }

            guard let cloudReminders = try SecureBackupService.importCloudBackupIfNewerThanLocal(storageURL: storageURL) else {
                _ = try SecureBackupService.writeBackups(reminders: reminders, storageURL: storageURL)
                return SecureBackupMessage(
                    title: PunaiseL10n.string("iCloud Drive à jour"),
                    detail: PunaiseL10n.string("La sauvegarde chiffrée actuelle est disponible dans iCloud Drive.")
                )
            }

            reminders = cloudReminders
            return SecureBackupMessage(
                title: PunaiseL10n.string("Synchronisation terminée"),
                detail: PunaiseLanguage.current == .english
                    ? "\(cloudReminders.count) Punaise\(cloudReminders.count > 1 ? "s" : "") restored."
                    : "\(cloudReminders.count) Punaise\(cloudReminders.count > 1 ? "s" : "") récupérée\(cloudReminders.count > 1 ? "s" : "")."
            )
        } catch {
            return SecureBackupMessage(
                title: PunaiseL10n.string("Synchronisation impossible"),
                detail: error.localizedDescription
            )
        }
    }

    func createFirstLaunchPunaise() -> Reminder {
        let deadline = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
        return createReminder(
            title: PunaiseL10n.string("Ma première Punaise"),
            note: PunaiseL10n.string("Un exemple épinglé pour sentir l’urgence monter."),
            deadline: deadline,
            urgency: .urgent,
            isPinned: true,
            project: PunaiseL10n.string("Découverte"),
            tags: [PunaiseL10n.string("première")]
        )
    }

    var dataFolderURL: URL {
        storageURL.deletingLastPathComponent()
    }

    private func sortReminders() {
        reminders.sort { first, second in
            if first.isArchived != second.isArchived {
                return !first.isArchived
            }
            let firstScore = first.pressureScore()
            let secondScore = second.pressureScore()
            if firstScore != secondScore {
                return firstScore > secondScore
            }
            return first.deadline < second.deadline
        }
    }

    private func load() {
        defer { hasLoaded = true }

        do {
            let data = try Data(contentsOf: storageURL)
            reminders = try JSONDecoder.postit.decode([Reminder].self, from: data)
        } catch {
            reminders = []
        }

        importCloudBackupDuringLoadIfNeeded()

        sortReminders()
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: storageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder.postit.encode(reminders)
            try data.write(to: storageURL, options: [.atomic])
            _ = try? SecureBackupService.writeBackups(reminders: reminders, storageURL: storageURL)
        } catch {
            assertionFailure("Unable to save reminders: \(error)")
        }
    }

    private func importCloudBackupDuringLoadIfNeeded() {
        do {
            guard let cloudReminders = try SecureBackupService.importCloudBackupIfNewerThanLocal(storageURL: storageURL) else {
                return
            }

            reminders = cloudReminders
            save()
        } catch {
            assertionFailure("Unable to import iCloud backup: \(error)")
        }
    }

    private static func defaultStorageURL() -> URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        return base
            .appendingPathComponent("Punaise", isDirectory: true)
            .appendingPathComponent("punaises.json")
    }

    private static func attachmentTitle(for target: String, kind: AttachmentKind) -> String {
        switch kind {
        case .file, .folder, .app:
            return URL(fileURLWithPath: target).lastPathComponent
        case .website:
            return target
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
        case .mail:
            return target
        }
    }

    private func calendarTags(for event: CalendarEventCandidate) -> [String] {
        var tags = ["agenda"]
        let source = event.sourceTitle.lowercased()
        if source.contains("google") || source.contains("gmail") {
            tags.append("google")
        }
        return tags
    }

    private func calendarAttachment(for event: CalendarEventCandidate) -> PunaiseAttachment? {
        guard let url = event.url else { return nil }
        return PunaiseAttachment(
            title: PunaiseL10n.string("Événement Agenda"),
            target: url.absoluteString,
            kind: .website
        )
    }

    private func reminderTags(for candidate: ReminderCandidate) -> [String] {
        var tags = ["rappels"]
        let text = "\(candidate.displayTitle) \(candidate.notes) \(candidate.listTitle)".lowercased()

        for keyword in ["client", "facture", "contrat", "livraison", "projet", "administratif"] where text.contains(keyword) {
            tags.append(keyword)
        }

        if candidate.priority >= 1 && candidate.priority <= 4 {
            tags.append("priorité")
        }

        return Array(Set(tags)).sorted()
    }

    private func reminderAttachment(for candidate: ReminderCandidate) -> PunaiseAttachment? {
        guard let url = candidate.url else { return nil }
        return PunaiseAttachment(
            title: PunaiseL10n.string("Rappel Apple"),
            target: url.absoluteString,
            kind: .website
        )
    }

    private func mergeCalendarAttachment(for index: Int, event: CalendarEventCandidate) {
        guard let attachment = calendarAttachment(for: event) else { return }
        if reminders[index].attachments.contains(where: { $0.target == attachment.target }) {
            return
        }
        reminders[index].attachments.append(attachment)
        reminders[index].attachment = reminders[index].attachments.first
    }

    private func mergeReminderAttachment(for index: Int, candidate: ReminderCandidate) {
        guard let attachment = reminderAttachment(for: candidate) else { return }
        if reminders[index].attachments.contains(where: { $0.target == attachment.target }) {
            return
        }

        reminders[index].attachments.append(attachment)
        reminders[index].attachment = reminders[index].attachments.first
    }

}

private extension JSONEncoder {
    static var postit: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var postit: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

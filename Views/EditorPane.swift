import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct EditorPane: View {
    let selectedID: Reminder.ID?
    @ObservedObject var store: ReminderStore
    @ObservedObject var desktopController: DesktopStickyController
    let filter: ReminderFilter
    let visibleReminders: [Reminder]
    let now: Date
    let onCreate: () -> Void
    let onCreateFromTemplate: (PunaiseTemplate) -> Void
    let onCreateFromNaturalLanguage: (String) -> Void
    let onOpenCalendarImport: () -> Void
    let onOpenRemindersImport: () -> Void
    let onCleanDesktop: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    let onPostpone: () -> Void
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            NotebookPaper(cornerRadius: 24)
                .padding(28)

            if let reminder = store.reminder(id: selectedID), let selectedID {
                editor(for: reminder, id: selectedID)
                    .padding(.horizontal, 62)
                    .padding(.vertical, 48)
            } else {
                EmptyStateView(onCreate: onCreate)
            }
        }
    }

    private func editor(for reminder: Reminder, id: Reminder.ID) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                EditorToolbar(
                    reminder: reminder,
                    onCreate: onCreate,
                    onOpenCalendarImport: onOpenCalendarImport,
                    onOpenRemindersImport: onOpenRemindersImport,
                    onTogglePin: {
                        if reminder.isPinned {
                            store.setPinned(id, isPinned: false)
                        } else {
                            desktopController.pin(id, in: store)
                        }
                    },
                    onTemplate: onCreateFromTemplate,
                    onRandomize: {
                        desktopController.randomizePosition(for: id, in: store)
                    },
                    onCleanDesktop: onCleanDesktop,
                    onPostpone: {
                        store.postpone(id)
                    },
                    onComplete: {
                        store.complete(id)
                    },
                    onDelete: onDelete,
                    onDuplicate: onDuplicate
                )
                .padding(.bottom, 20)

                QuickCaptureBar(onSubmit: onCreateFromNaturalLanguage)
                    .padding(.bottom, 14)

                PunaiseContextPanel(
                    filter: filter,
                    reminders: visibleReminders,
                    selectedID: storeSelection,
                    now: now
                )
                .padding(.bottom, 18)

                EditorFields(
                    reminder: reminder,
                    now: now,
                    title: textBinding(id, \.title),
                    note: textBinding(id, \.note),
                    deadline: dateBinding(id),
                    urgency: urgencyBinding(id),
                    project: textBinding(id, \.project),
                    tagsText: tagsBinding(id),
                    recurrence: recurrenceBinding(id),
                    onAddAttachment: { kind, target, title in
                        store.addAttachment(id, kind: kind, target: target, title: title)
                    },
                    onRemoveAttachment: { attachmentID in
                        store.removeAttachment(id, attachmentID: attachmentID)
                    },
                    onPostponeOneHour: {
                        store.postpone(id, by: .hour, value: 1)
                    },
                    onOpenFirstAttachment: {
                        guard let attachment = store.reminder(id: id)?.attachments.first else { return }
                        AttachmentOpening.open(attachment)
                    },
                    onBlockCalendar: {
                        CalendarTimeBlocker.blockThirtyMinutes(for: reminder) { result in
                            if case .failure = result {
                                DispatchQueue.main.async {
                                    NSSound.beep()
                                }
                            }
                        }
                    },
                    onComplete: {
                        store.complete(id)
                    }
                )

                FooterActions(
                    isPinned: reminder.isPinned,
                    onPostpone: onPostpone,
                    onComplete: onComplete,
                    onDelete: onDelete,
                    onDuplicate: onDuplicate
                )
                .padding(.top, 22)
            }
        }
    }

    private func textBinding(_ id: Reminder.ID, _ keyPath: WritableKeyPath<Reminder, String>) -> Binding<String> {
        Binding(
            get: {
                store.reminder(id: id)?[keyPath: keyPath] ?? ""
            },
            set: { newValue in
                store.update(id) { reminder in
                    reminder[keyPath: keyPath] = newValue
                }
            }
        )
    }

    private func dateBinding(_ id: Reminder.ID) -> Binding<Date> {
        Binding(
            get: {
                store.reminder(id: id)?.deadline ?? Date()
            },
            set: { newValue in
                store.update(id) { reminder in
                    reminder.deadline = newValue
                }
            }
        )
    }

    private func urgencyBinding(_ id: Reminder.ID) -> Binding<Urgency> {
        Binding(
            get: {
                store.reminder(id: id)?.urgency ?? .neutral
            },
            set: { newValue in
                store.update(id) { reminder in
                    reminder.urgency = newValue
                }
            }
        )
    }

    private var storeSelection: Binding<Reminder.ID?> {
        Binding(
            get: { selectedID },
            set: { newValue in
                if let newValue {
                    store.markOpened(newValue)
                    NotificationCenter.default.post(name: .postitSelectReminder, object: newValue)
                }
            }
        )
    }

    private func tagsBinding(_ id: Reminder.ID) -> Binding<String> {
        Binding(
            get: {
                store.reminder(id: id)?.tags.joined(separator: ", ") ?? ""
            },
            set: { newValue in
                store.setTags(id, from: newValue)
            }
        )
    }

    private func recurrenceBinding(_ id: Reminder.ID) -> Binding<RecurrenceRule> {
        Binding(
            get: {
                store.reminder(id: id)?.recurrence ?? .none
            },
            set: { newValue in
                store.update(id) { reminder in
                    reminder.recurrence = newValue
                }
            }
        )
    }
}

private struct EditorToolbar: View {
    let reminder: Reminder
    let onCreate: () -> Void
    let onOpenCalendarImport: () -> Void
    let onOpenRemindersImport: () -> Void
    let onTogglePin: () -> Void
    let onTemplate: (PunaiseTemplate) -> Void
    let onRandomize: () -> Void
    let onCleanDesktop: () -> Void
    let onPostpone: () -> Void
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

    @AppStorage(PunaisePreferenceKey.focusUrgenciesOnDesktop) private var focusUrgenciesOnDesktop = false
    @AppStorage(PunaisePreferenceKey.adaptiveDesktop) private var adaptiveDesktop = true

    var body: some View {
        HStack(spacing: 12) {
            PunaiseLogo(size: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text("Punaise")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color(red: 0.08, green: 0.22, blue: 0.40))
                    .lineLimit(1)
                    .fixedSize()

                Text("Épingle ce qui presse.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer()

            Button(action: onCreate) {
                Image(systemName: "plus")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(IconButtonStyle(isActive: true))
            .help("Créer une Punaise")

            Button(action: onOpenCalendarImport) {
                Image(systemName: "calendar.badge.plus")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(IconButtonStyle())
            .help("Créer des Punaises depuis Google Agenda")

            Button(action: onOpenRemindersImport) {
                Image(systemName: "checklist")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(IconButtonStyle())
            .help("Créer des Punaises depuis Apple Reminders")

            Menu {
                ForEach(PunaiseTemplate.allCases) { template in
                    Button {
                        onTemplate(template)
                    } label: {
                        Label(template.title, systemImage: template.systemImage)
                    }
                }
            } label: {
                Image(systemName: "wand.and.stars")
                    .frame(width: 30, height: 30)
            }
            .menuStyle(.borderlessButton)
            .help("Créer depuis un template")

            Button(action: onTogglePin) {
                Image(systemName: reminder.isPinned ? "pin.fill" : "pin")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(IconButtonStyle(isActive: reminder.isPinned))
            .help(reminder.isPinned ? "Désépingler" : "Punaiser sur le bureau")

            Button {
                focusUrgenciesOnDesktop.toggle()
            } label: {
                Image(systemName: "scope")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(IconButtonStyle(isActive: focusUrgenciesOnDesktop))
            .help("Mode Focus")

            Button {
                adaptiveDesktop.toggle()
            } label: {
                Image(systemName: "arrow.up.forward.circle")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(IconButtonStyle(isActive: adaptiveDesktop))
            .help("Bureau adaptatif")

            Menu {
                Button("Dupliquer", action: onDuplicate)
                Button("Déplacer la Punaise", action: onRandomize)
                    .disabled(!reminder.isPinned)
                Button("Bureau propre", action: onCleanDesktop)
                Divider()
                Button("Reporter à demain", action: onPostpone)
                Button("Marquer terminée", action: onComplete)
                Divider()
                Button("Supprimer", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 30, height: 30)
            }
            .menuStyle(.borderlessButton)
            .help("Actions")
        }
    }
}

private struct EditorFields: View {
    let reminder: Reminder
    let now: Date
    @Binding var title: String
    @Binding var note: String
    @Binding var deadline: Date
    @Binding var urgency: Urgency
    @Binding var project: String
    @Binding var tagsText: String
    @Binding var recurrence: RecurrenceRule
    let onAddAttachment: (AttachmentKind, String, String) -> Void
    let onRemoveAttachment: (PunaiseAttachment.ID) -> Void
    let onPostponeOneHour: () -> Void
    let onOpenFirstAttachment: () -> Void
    let onBlockCalendar: () -> Void
    let onComplete: () -> Void
    @State private var showsDeadlineAgenda = false
    @State private var selectedTab: EditorDetailTab = .notes

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Titre")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                TextField("", text: $title)
                    .textFieldStyle(.plain)
                    .font(.custom("Noteworthy", size: 30).weight(.semibold))
                    .foregroundStyle(.primary)
            }

            EditorDetailTabs(selection: $selectedTab)

            switch selectedTab {
            case .notes:
                NoteWritingPanel(note: $note)
            case .urgency:
                urgencySettings
            }
        }
    }

    @ViewBuilder
    private var urgencySettings: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 20) {
                Button {
                    showsDeadlineAgenda = true
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Text("Échéance")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Image(systemName: "calendar")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.orange)
                            Text("Agenda")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.orange)
                        }

                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.16))
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.orange)
                            }
                            .frame(width: 36, height: 36)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(PunaiseDateFormatting.shortDateTime.string(from: deadline))
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Text(PunaiseDateFormatting.relativeDeadline(deadline, now: now))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: 258, height: 58, alignment: .leading)
                        .padding(.horizontal, 14)
                        .background(.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.orange.opacity(0.22), lineWidth: 1)
                        )
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Échéance")
                .accessibilityHint("Ouvre le grand agenda")
                .sheet(isPresented: $showsDeadlineAgenda) {
                    DeadlineAgendaSheet(deadline: $deadline, isPresented: $showsDeadlineAgenda)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("État")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    StatusPill(status: reminder.status(at: now))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Pression")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    PressureScorePill(breakdown: reminder.pressureBreakdown(at: now))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Récurrence")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Picker("", selection: $recurrence) {
                        ForEach(RecurrenceRule.allCases) { rule in
                            Text(rule.title).tag(rule)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }

                Spacer()
            }

            if reminder.status(at: now).isUrgentNow {
                RescuePlanPanel(
                    hasAttachment: !reminder.attachments.isEmpty,
                    onPostponeOneHour: onPostponeOneHour,
                    onOpenFirstAttachment: onOpenFirstAttachment,
                    onBlockCalendar: onBlockCalendar,
                    onComplete: onComplete
                )
            }

            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Projet")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    TextField("Client, perso, finance...", text: $project)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tags")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)

                    TextField("facture, client, livraison", text: $tagsText)
                        .textFieldStyle(.roundedBorder)
                }
            }

            AttachmentEditor(
                attachments: reminder.attachments,
                onAddAttachment: onAddAttachment,
                onRemoveAttachment: onRemoveAttachment
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Urgence choisie")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                UrgencySelector(
                    selection: $urgency,
                    status: reminder.status(at: now)
                )
            }

            PressureBreakdownPanel(breakdown: reminder.pressureBreakdown(at: now))

            ReminderPreview(reminder: reminder, now: now)
                .padding(.top, 2)
        }
    }
}

private struct PressureScorePill: View {
    let breakdown: PunaisePressureBreakdown

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11, weight: .bold))

            Text("\(breakdown.total)/100")
                .font(.system(size: 14, weight: .bold))
                .monospacedDigit()
        }
        .foregroundStyle(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(color.opacity(0.10), in: Capsule())
    }

    private var color: Color {
        switch breakdown.total {
        case 86...:
            return .red
        case 64...:
            return .orange
        case 38...:
            return .yellow
        default:
            return .green
        }
    }
}

private struct RescuePlanPanel: View {
    let hasAttachment: Bool
    let onPostponeOneHour: () -> Void
    let onOpenFirstAttachment: () -> Void
    let onBlockCalendar: () -> Void
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Label("Plan de secours", systemImage: "lifepreserver")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.red)

            Spacer()

            Button {
                onPostponeOneHour()
            } label: {
                Label("1 h", systemImage: "clock.arrow.circlepath")
            }
            .buttonStyle(SecondaryButtonStyle())
            .help("Reporter d’une heure")

            Button {
                onOpenFirstAttachment()
            } label: {
                Label("Contexte", systemImage: "arrow.up.right.square")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!hasAttachment)
            .help("Ouvrir le premier contexte lié")

            Button {
                onBlockCalendar()
            } label: {
                Label("30 min", systemImage: "calendar.badge.clock")
            }
            .buttonStyle(SecondaryButtonStyle())
            .help("Bloquer 30 minutes dans Calendrier")

            Button {
                onComplete()
            } label: {
                Label("Terminer", systemImage: "checkmark.circle")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(12)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.red.opacity(0.16), lineWidth: 1)
        )
    }
}

private struct PressureBreakdownPanel: View {
    let breakdown: PunaisePressureBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Moteur d’urgence")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(breakdown.total)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            VStack(spacing: 8) {
                ForEach(breakdown.factors) { factor in
                    PressureFactorRow(factor: factor, total: max(1, breakdown.rawTotal))
                }
            }
        }
        .padding(12)
        .background(.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.black.opacity(0.06))
        )
    }
}

private struct PressureFactorRow: View {
    let factor: PunaisePressureFactor
    let total: Int

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: factor.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(factor.title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 84, alignment: .leading)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.black.opacity(0.07))

                    Capsule()
                        .fill(Color.orange.opacity(0.74))
                        .frame(width: proxy.size.width * CGFloat(factor.value) / CGFloat(total))
                }
            }
            .frame(height: 6)

            Text("+\(factor.value)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(width: 34, alignment: .trailing)
        }
    }
}

private enum EditorDetailTab: String, CaseIterable, Identifiable {
    case notes
    case urgency

    var id: Self { self }

    var title: String {
        switch self {
        case .notes:
            return "Notes"
        case .urgency:
            return "Urgence"
        }
    }

    var systemImage: String {
        switch self {
        case .notes:
            return "note.text"
        case .urgency:
            return "flame"
        }
    }
}

private struct EditorDetailTabs: View {
    @Binding var selection: EditorDetailTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(EditorDetailTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    Label(tab.title, systemImage: tab.systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(selection == tab ? Color(red: 0.08, green: 0.20, blue: 0.37) : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            (selection == tab ? Color.orange.opacity(0.15) : Color.black.opacity(0.035)),
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(selection == tab ? Color.orange.opacity(0.28) : Color.black.opacity(0.07))
                        )
                }
                .buttonStyle(.plain)
                .help(tab.title)
            }

            Spacer()
        }
    }
}

private struct NoteWritingPanel: View {
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label("Notes", systemImage: "pencil.line")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(note.count) caractères")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(nsColor: .textBackgroundColor).opacity(0.72))

                Canvas { context, size in
                    var lines = Path()
                    for y in stride(from: 42, through: size.height - 18, by: 31) {
                        lines.move(to: CGPoint(x: 18, y: y))
                        lines.addLine(to: CGPoint(x: size.width - 18, y: y))
                    }
                    context.stroke(
                        lines,
                        with: .color(Color(red: 0.31, green: 0.55, blue: 0.82).opacity(0.16)),
                        lineWidth: 1
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Écrire la note...")
                        .font(.custom("Noteworthy", size: 24))
                        .foregroundStyle(.secondary.opacity(0.50))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 17)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $note)
                    .font(.custom("Noteworthy", size: 24))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .frame(minHeight: 220)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.orange.opacity(0.18), lineWidth: 1)
            )
        }
    }
}

private struct AttachmentEditor: View {
    let attachments: [PunaiseAttachment]
    let onAddAttachment: (AttachmentKind, String, String) -> Void
    let onRemoveAttachment: (PunaiseAttachment.ID) -> Void

    @State private var linkText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Pièces jointes")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    chooseFiles()
                } label: {
                    Label("Fichier", systemImage: "paperclip")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    chooseApplications()
                } label: {
                    Label("App", systemImage: "app")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    chooseFolders()
                } label: {
                    Label("Dossier", systemImage: "folder")
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            HStack(spacing: 8) {
                Image(systemName: "link")
                    .foregroundStyle(.secondary)
                TextField("https://site.com ou deep link d’application", text: $linkText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addLink)
                Button("Joindre") {
                    addLink()
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(linkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if attachments.isEmpty {
                Text("Aucune pièce jointe.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(spacing: 6) {
                    ForEach(attachments) { attachment in
                        AttachmentRow(
                            attachment: attachment,
                            onOpen: {
                                AttachmentOpening.open(attachment)
                            },
                            onRemove: {
                                onRemoveAttachment(attachment.id)
                            }
                        )
                    }
                }
            }
        }
    }

    private func addLink() {
        let trimmed = linkText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAddAttachment(.website, trimmed, "")
        linkText = ""
    }

    private func chooseFiles() {
        let panel = NSOpenPanel()
        panel.title = "Joindre des fichiers"
        panel.prompt = "Joindre"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true

        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            onAddAttachment(.file, url.path, url.lastPathComponent)
        }
    }

    private func chooseApplications() {
        let panel = NSOpenPanel()
        panel.title = "Joindre une application"
        panel.prompt = "Joindre"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.applicationBundle]

        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            onAddAttachment(.app, url.path, url.deletingPathExtension().lastPathComponent)
        }
    }

    private func chooseFolders() {
        let panel = NSOpenPanel()
        panel.title = "Joindre un dossier"
        panel.prompt = "Joindre"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true

        guard panel.runModal() == .OK else { return }
        for url in panel.urls {
            onAddAttachment(.folder, url.path, url.lastPathComponent)
        }
    }
}

private struct AttachmentRow: View {
    let attachment: PunaiseAttachment
    let onOpen: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: attachment.kind.systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.displayTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                Text(attachment.target)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onOpen) {
                Image(systemName: "arrow.up.right.square")
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
            .help("Ouvrir")

            Button(role: .destructive, action: onRemove) {
                Image(systemName: "xmark.circle")
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
            .help("Retirer")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.black.opacity(0.035), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.black.opacity(0.06))
        )
    }
}

private enum AttachmentOpening {
    static func open(_ attachment: PunaiseAttachment) {
        switch attachment.kind {
        case .website:
            openWebsite(attachment.target)
        case .file, .folder:
            NSWorkspace.shared.open(URL(fileURLWithPath: attachment.target))
        case .app:
            openApplication(namedOrLocatedAt: attachment.target)
        case .mail:
            openMail(attachment.target)
        }
    }

    private static func openWebsite(_ target: String) {
        let trimmed = target.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlString: String

        if trimmed.contains("://") {
            urlString = trimmed
        } else {
            urlString = "https://\(trimmed)"
        }

        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    private static func openMail(_ target: String) {
        let trimmed = target.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.contains("://"), let url = URL(string: trimmed) {
            NSWorkspace.shared.open(url)
            return
        }

        if let url = URL(string: "mailto:\(trimmed)") {
            NSWorkspace.shared.open(url)
        }
    }

    private static func openApplication(namedOrLocatedAt target: String) {
        let workspace = NSWorkspace.shared
        let trimmed = target.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasSuffix(".app") || trimmed.hasPrefix("/") {
            workspace.open(URL(fileURLWithPath: trimmed))
            return
        }

        let candidates = [
            "/Applications/\(trimmed).app",
            "/System/Applications/\(trimmed).app",
            "/System/Applications/Utilities/\(trimmed).app"
        ]

        for path in candidates where FileManager.default.fileExists(atPath: path) {
            workspace.open(URL(fileURLWithPath: path))
            return
        }
    }
}

private struct ReminderPreview: View {
    let reminder: Reminder
    let now: Date

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            StickyCardView(
                reminder: reminder,
                now: now,
                scale: .preview
            )
            .frame(width: 190, height: 122)
            .rotationEffect(.degrees(reminder.status(at: now) == .overdue ? 1 : -2))

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: reminder.isPinned ? "pin.fill" : "pin")
                        .foregroundStyle(reminder.isPinned ? .blue : .secondary)
                    Text(reminder.isPinned ? "Punaisée sur le bureau" : "Dans le tableau")
                        .font(.system(size: 14, weight: .semibold))
                }

                Text(PunaiseDateFormatting.shortDateTime.string(from: reminder.deadline))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                if !reminder.attachments.isEmpty {
                    Label("\(reminder.attachments.count) pièce\(reminder.attachments.count > 1 ? "s" : "") jointe\(reminder.attachments.count > 1 ? "s" : "")", systemImage: "paperclip")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }
}

private struct FooterActions: View {
    let isPinned: Bool
    let onPostpone: () -> Void
    let onComplete: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onPostpone) {
                Label("Reporter", systemImage: "clock.arrow.circlepath")
            }
            .buttonStyle(SecondaryButtonStyle())

            Button(action: onComplete) {
                Label("Terminer", systemImage: "checkmark.circle")
            }
            .buttonStyle(SecondaryButtonStyle())

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Supprimer")

            Button(action: onDuplicate) {
                Image(systemName: "square.on.square")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Dupliquer")
        }
        .foregroundStyle(.secondary)
    }
}

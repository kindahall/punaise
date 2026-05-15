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
    let isPro: Bool
    let activeCount: Int
    let onCreate: () -> Void
    let onCreateFromTemplate: (PunaiseTemplate) -> Void
    let onCreateFromNaturalLanguage: (String) -> Void
    let onOpenCalendarImport: () -> Void
    let onOpenRemindersImport: () -> Void
    let onCleanDesktop: () -> Void
    let onShowLicense: (PunaiseProFeature) -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    let onPostpone: () -> Void
    let onComplete: () -> Void
    @State private var showsToolbarDeadlineAgenda = false
    @State private var calendarBlockMessage: CalendarBlockMessage?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            NotebookPaper(cornerRadius: 24)
                .padding(28)

            if let reminder = store.reminder(id: selectedID), let selectedID {
                editor(for: reminder, id: selectedID)
                    .padding(.horizontal, 62)
                    .padding(.vertical, 48)
                    .id(selectedID)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.92).combined(with: .opacity),
                        removal: .scale(scale: 1.05).combined(with: .opacity)
                    ))
            } else {
                EmptyStateView(onCreate: onCreate)
                    .transition(.opacity)
            }
        }
        .animation(.interpolatingSpring(stiffness: 230, damping: 24), value: selectedID)
        .onChange(of: selectedID) { _ in
            calendarBlockMessage = nil
        }
        .sheet(isPresented: $showsToolbarDeadlineAgenda) {
            if let selectedID {
                DeadlineAgendaSheet(deadline: dateBinding(selectedID), isPresented: $showsToolbarDeadlineAgenda)
            }
        }
    }

    private func editor(for reminder: Reminder, id: Reminder.ID) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                EditorToolbar(
                    reminder: reminder,
                    isPro: isPro,
                    activeCount: activeCount,
                    onCreate: onCreate,
                    onOpenCalendarImport: onOpenCalendarImport,
                    onOpenRemindersImport: onOpenRemindersImport,
                    onShowLicense: onShowLicense,
                    onTogglePin: {
                        if reminder.isPinned {
                            store.setPinned(id, isPinned: false)
                        } else {
                            desktopController.pin(id, in: store)
                        }
                    },
                    onCycleUrgency: {
                        store.update(id) { reminder in
                            reminder.urgency = reminder.urgency.nextQuickState
                        }
                    },
                    onQuickDeadline: {
                        showsToolbarDeadlineAgenda = true
                    },
                    onCycleDeadline: {
                        store.cycleQuickDeadline(id, now: now)
                    },
                    onTemplate: onCreateFromTemplate,
                    onRandomize: {
                        desktopController.randomizePosition(for: id, in: store)
                    },
                    onCleanDesktop: onCleanDesktop,
                    onPostpone: {
                        store.postpone(id, by: .hour, value: 1)
                    },
                    onComplete: {
                        store.complete(id)
                    },
                    onToggleArchived: {
                        store.toggleArchived(id)
                    },
                    onDelete: onDelete,
                    onDuplicate: onDuplicate
                )
                .padding(.bottom, 20)

                if isPro {
                    QuickCaptureBar(onSubmit: onCreateFromNaturalLanguage)
                        .padding(.bottom, 14)
                } else {
                    ProLockCard(feature: .naturalCapture, compact: true, onShowLicense: onShowLicense)
                        .padding(.bottom, 14)
                }

                PunaiseContextPanel(
                    filter: filter,
                    reminders: visibleReminders,
                    selectedID: storeSelection,
                    now: now,
                    isPro: isPro,
                    onShowLicense: onShowLicense
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
                    isPro: isPro,
                    calendarBlockMessage: calendarBlockMessage,
                    onAddAttachment: { kind, target, title in
                        store.addAttachment(id, kind: kind, target: target, title: title)
                    },
                    onRemoveAttachment: { attachmentID in
                        store.removeAttachment(id, attachmentID: attachmentID)
                    },
                    onPostponeOneHour: {
                        store.postpone(id, by: .hour, value: 1)
                    },
                    onCycleDeadline: {
                        store.cycleQuickDeadline(id, now: now)
                    },
                    onOpenFirstAttachment: {
                        guard let attachment = store.reminder(id: id)?.attachments.first else { return }
                        AttachmentOpening.open(attachment)
                    },
                    onBlockCalendar: {
                        calendarBlockMessage = CalendarBlockMessage(
                            title: PunaiseL10n.string("Création du créneau"),
                            detail: PunaiseL10n.string("Punaise ajoute 30 minutes dans Calendrier."),
                            state: .pending
                        )
                        CalendarTimeBlocker.blockThirtyMinutes(for: reminder) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success:
                                    calendarBlockMessage = CalendarBlockMessage(
                                        title: PunaiseL10n.string("Créneau ajouté"),
                                        detail: PunaiseL10n.string("30 minutes sont bloquées dans Calendrier."),
                                        state: .success
                                    )
                                case .failure(let error):
                                    calendarBlockMessage = CalendarBlockMessage(
                                        title: PunaiseL10n.string("Calendrier inaccessible"),
                                        detail: error.localizedDescription,
                                        state: .failure
                                    )
                                    NSSound.beep()
                                }
                            }
                        }
                    },
                    onComplete: {
                        store.complete(id)
                    },
                    onToggleArchived: {
                        store.toggleArchived(id)
                    },
                    onShowLicense: onShowLicense
                )

                FooterActions(
                    isArchived: reminder.isArchived,
                    onPostpone: onPostpone,
                    onComplete: onComplete,
                    onToggleArchived: {
                        store.toggleArchived(id)
                    },
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
    let isPro: Bool
    let activeCount: Int
    let onCreate: () -> Void
    let onOpenCalendarImport: () -> Void
    let onOpenRemindersImport: () -> Void
    let onShowLicense: (PunaiseProFeature) -> Void
    let onTogglePin: () -> Void
    let onCycleUrgency: () -> Void
    let onQuickDeadline: () -> Void
    let onCycleDeadline: () -> Void
    let onTemplate: (PunaiseTemplate) -> Void
    let onRandomize: () -> Void
    let onCleanDesktop: () -> Void
    let onPostpone: () -> Void
    let onComplete: () -> Void
    let onToggleArchived: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

    @AppStorage(PunaisePreferenceKey.focusUrgenciesOnDesktop) private var focusUrgenciesOnDesktop = false
    @AppStorage(PunaisePreferenceKey.adaptiveDesktop) private var adaptiveDesktop = true
    @AppStorage(PunaisePreferenceKey.lastTemplate) private var lastTemplateRaw = PunaiseTemplate.facture.rawValue
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        HStack(spacing: 12) {
            PunaiseLogo(size: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text("Punaise")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(theme.brand)
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
                Label("Nouvelle", systemImage: "plus")
                    .fixedSize()
            }
            .buttonStyle(PrimaryButtonStyle())
            .help("Créer une Punaise")

            Button(action: onTogglePin) {
                Label(reminder.isPinned ? "Sur bureau" : "Punaiser", systemImage: reminder.isPinned ? "pin.fill" : "pin")
                    .fixedSize()
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(reminder.isArchived)
            .help(reminder.isPinned ? "Désépingler" : "Punaiser sur le bureau")

            Button(action: onQuickDeadline) {
                Label("Échéance", systemImage: "calendar")
                    .fixedSize()
            }
            .buttonStyle(SecondaryButtonStyle())
            .help("Choisir la date et l’heure")

            Menu {
                Button(action: onCycleUrgency) {
                    Label("\(PunaiseL10n.string("Urgence")) : \(reminder.urgency.nextQuickState.title)", systemImage: reminder.urgency.systemImage)
                }

                Button(action: onCycleDeadline) {
                    Label("Échéance rapide suivante", systemImage: "forward.end")
                }
                .disabled(reminder.isArchived)

                Button {
                    runPro(.templates) {
                        applyTemplate(lastTemplate)
                    }
                } label: {
                    Label("\(PunaiseL10n.string("Template")) : \(lastTemplate.title)", systemImage: "wand.and.stars")
                }

                Menu {
                    ForEach(PunaiseTemplate.allCases) { template in
                        Button {
                            runPro(.templates) {
                                applyTemplate(template)
                            }
                        } label: {
                            Label(template.title, systemImage: template.systemImage)
                        }
                    }
                } label: {
                    Label("Choisir un template", systemImage: "square.grid.3x3")
                }

                Button {
                    runPro(.smartDesktop, action: onCleanDesktop)
                } label: {
                    Label("Ranger le bureau", systemImage: "square.grid.2x2")
                }

                Divider()

                Button {
                    runPro(.smartDesktop) {
                        focusUrgenciesOnDesktop.toggle()
                    }
                } label: {
                    Label(focusUrgenciesOnDesktop ? "Désactiver Focus" : "Mode Focus", systemImage: "scope")
                }

                Button {
                    runPro(.smartDesktop) {
                        adaptiveDesktop.toggle()
                    }
                } label: {
                    Label(adaptiveDesktop ? "Bureau adaptatif activé" : "Bureau adaptatif", systemImage: "arrow.up.forward.circle")
                }

                Divider()
                Button {
                    runPro(.imports, action: onOpenCalendarImport)
                } label: {
                    Label("Importer Google Agenda", systemImage: "tray.and.arrow.down")
                }
                Button {
                    runPro(.imports, action: onOpenRemindersImport)
                } label: {
                    Label("Importer Apple Reminders", systemImage: "checklist")
                }
                Divider()
                Button("Dupliquer", action: onDuplicate)
                Button("Déplacer la Punaise", action: onRandomize)
                    .disabled(!reminder.isPinned)
                Button("Reporter d’1 h", action: onPostpone)
                    .disabled(reminder.isArchived)
                Button("Marquer terminée", action: onComplete)
                    .disabled(reminder.isArchived)
                Button(reminder.isArchived ? "Restaurer" : "Archiver", action: onToggleArchived)
                Divider()
                Button("Supprimer", role: .destructive, action: onDelete)
            } label: {
                Label("Plus", systemImage: "ellipsis.circle")
                    .fixedSize()
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.brand)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.inputSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(theme.hairline)
                    )
                    .shadow(color: theme.shadow.opacity(0.35), radius: 7, y: 4)
            }
            .menuIndicator(.hidden)
            .help("Actions")
        }
    }

    private var lastTemplate: PunaiseTemplate {
        PunaiseTemplate(rawValue: lastTemplateRaw) ?? .facture
    }

    private func applyTemplate(_ template: PunaiseTemplate) {
        lastTemplateRaw = template.rawValue
        onTemplate(template)
    }

    private func runPro(_ feature: PunaiseProFeature, action: () -> Void) {
        guard isPro else {
            onShowLicense(feature)
            return
        }

        action()
    }

    private func urgencyTint(theme: PunaiseTheme) -> Color {
        switch reminder.urgency {
        case .urgent:
            return theme.urgencyRed
        case .neutral:
            return theme.linkBlue
        case .relaxed:
            return theme.calmGreen
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
    let isPro: Bool
    let calendarBlockMessage: CalendarBlockMessage?
    let onAddAttachment: (AttachmentKind, String, String) -> Void
    let onRemoveAttachment: (PunaiseAttachment.ID) -> Void
    let onPostponeOneHour: () -> Void
    let onCycleDeadline: () -> Void
    let onOpenFirstAttachment: () -> Void
    let onBlockCalendar: () -> Void
    let onComplete: () -> Void
    let onToggleArchived: () -> Void
    let onShowLicense: (PunaiseProFeature) -> Void
    @State private var showsDeadlineAgenda = false
    @State private var selectedTab: EditorDetailTab = .notes
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Titre")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                TextField("", text: $title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(theme.inputSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(theme.hairline)
                    )
            }

            EditorDetailTabs(selection: $selectedTab)

            switch selectedTab {
            case .notes:
                NoteWritingPanel(note: $note)
            case .urgency:
                urgencySettings
            case .tracking:
                if isPro {
                    ReminderTrackingPanel(
                        reminder: reminder,
                        now: now,
                        onCycleDeadline: onCycleDeadline,
                        onToggleArchived: onToggleArchived
                    )
                } else {
                    ProLockCard(feature: .advancedUrgency, onShowLicense: onShowLicense)
                }
            }
        }
    }

    @ViewBuilder
    private var urgencySettings: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

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
                        .background(theme.inputSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.orange.opacity(0.22), lineWidth: 1)
                        )
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(BouncyPlainButtonStyle())
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

                    if isPro {
                        PressureScorePill(breakdown: reminder.pressureBreakdown(at: now))
                    } else {
                        Button {
                            onShowLicense(.advancedUrgency)
                        } label: {
                            Label("Pro", systemImage: "lock")
                                .fixedSize()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
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

                Button(action: onCycleDeadline) {
                    Label("Prochaine", systemImage: "forward.end")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(reminder.isArchived)
                .help("Basculer vers la prochaine échéance rapide")

                Spacer()
            }

            if !reminder.isArchived && reminder.status(at: now).isUrgentNow && isPro {
                RescuePlanPanel(
                    hasAttachment: !reminder.attachments.isEmpty,
                    message: calendarBlockMessage,
                    onPostponeOneHour: onPostponeOneHour,
                    onOpenFirstAttachment: onOpenFirstAttachment,
                    onBlockCalendar: onBlockCalendar,
                    onComplete: onComplete
                )
            } else if !reminder.isArchived && reminder.status(at: now).isUrgentNow {
                ProLockCard(feature: .advancedUrgency, compact: true, onShowLicense: onShowLicense)
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

            if isPro {
                AttachmentEditor(
                    attachments: reminder.attachments,
                    onAddAttachment: onAddAttachment,
                    onRemoveAttachment: onRemoveAttachment
                )
            } else {
                ProLockCard(feature: .context, compact: true, onShowLicense: onShowLicense)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Urgence choisie")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                UrgencySelector(
                    selection: $urgency,
                    status: reminder.status(at: now)
                )
            }

            if isPro {
                PressureBreakdownPanel(breakdown: reminder.pressureBreakdown(at: now))
            } else {
                ProLockCard(feature: .advancedUrgency, compact: true, onShowLicense: onShowLicense)
            }

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

private struct CalendarBlockMessage {
    let title: String
    let detail: String
    let state: CalendarBlockState
}

private enum CalendarBlockState {
    case pending
    case success
    case failure

    var systemImage: String {
        switch self {
        case .pending:
            return "hourglass"
        case .success:
            return "checkmark.circle.fill"
        case .failure:
            return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .pending:
            return .orange
        case .success:
            return .green
        case .failure:
            return .red
        }
    }
}

private struct RescuePlanPanel: View {
    let hasAttachment: Bool
    let message: CalendarBlockMessage?
    let onPostponeOneHour: () -> Void
    let onOpenFirstAttachment: () -> Void
    let onBlockCalendar: () -> Void
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                    Label("30 min", systemImage: "calendar.badge.plus")
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

            if let message {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(message.title)
                            .font(.system(size: 12, weight: .bold))
                        Text(message.detail)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: message.state.systemImage)
                        .foregroundStyle(message.state.color)
                }
                .labelStyle(.titleAndIcon)
            }
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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

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
        .background(theme.inputSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(theme.hairline)
        )
    }
}

private struct PressureFactorRow: View {
    let factor: PunaisePressureFactor
    let total: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

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
                        .fill(theme.hoverSurface)

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
    case tracking

    var id: Self { self }

    var title: String {
        switch self {
        case .notes:
            return "Notes"
        case .urgency:
            return PunaiseL10n.string("Urgence")
        case .tracking:
            return PunaiseL10n.string("Suivi")
        }
    }

    var systemImage: String {
        switch self {
        case .notes:
            return "note.text"
        case .urgency:
            return "flame"
        case .tracking:
            return "waveform.path.ecg"
        }
    }
}

private struct EditorDetailTabs: View {
    @Binding var selection: EditorDetailTab
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        HStack(spacing: 6) {
            ForEach(EditorDetailTab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    Label(tab.title, systemImage: tab.systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(selection == tab ? theme.brand : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            (selection == tab ? theme.accent.opacity(theme.isDark ? 0.22 : 0.15) : theme.inputSurface),
                            in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(selection == tab ? theme.accent.opacity(0.32) : theme.hairline)
                        )
                }
                .buttonStyle(BouncyPlainButtonStyle())
                .help(tab.title)
            }

            Spacer()
        }
    }
}

private struct ReminderTrackingPanel: View {
    let reminder: Reminder
    let now: Date
    let onCycleDeadline: () -> Void
    let onToggleArchived: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)
        let antiForget = reminder.antiForgetStage(at: now)

        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                TrackingMetricCard(
                    title: "Anti-oubli",
                    value: antiForget.title,
                    systemImage: "bell.badge",
                    tint: antiForget == .quiet ? theme.calmGreen : .orange
                )

                TrackingMetricCard(
                    title: "Reports",
                    value: "\(reminder.postponeCount)",
                    systemImage: "clock.arrow.circlepath",
                    tint: reminder.postponeCount == 0 ? theme.linkBlue : .orange
                )

                TrackingMetricCard(
                    title: "Ouverte",
                    value: reminder.lastOpenedAt.map { PunaiseDateFormatting.compactDateTime.string(from: $0) } ?? PunaiseL10n.string("Jamais"),
                    systemImage: "eye",
                    tint: theme.linkBlue
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                TrackingInfoRow(
                    systemImage: reminder.isArchived ? "archivebox.fill" : "archivebox",
                    title: "État",
                    value: reminder.isArchived ? PunaiseL10n.string("Archivée") : PunaiseL10n.string("Active"),
                    detail: reminder.completedAt.map { "\(PunaiseL10n.string("Terminée le")) \(PunaiseDateFormatting.shortDateTime.string(from: $0))" }
                )

                if let source = reminder.externalSource {
                    TrackingInfoRow(
                        systemImage: source.provider.systemImage,
                        title: source.provider.title,
                        value: source.title,
                        detail: "\(PunaiseL10n.string("Importé le")) \(PunaiseDateFormatting.shortDateTime.string(from: source.importedAt))"
                    )
                }

                TrackingInfoRow(
                    systemImage: "repeat",
                    title: "Récurrence",
                    value: reminder.recurrence.title,
                    detail: nil
                )

                TrackingInfoRow(
                    systemImage: "calendar.badge.clock",
                    title: "Créée",
                    value: PunaiseDateFormatting.shortDateTime.string(from: reminder.createdAt),
                    detail: "\(PunaiseL10n.string("Modifiée le")) \(PunaiseDateFormatting.shortDateTime.string(from: reminder.updatedAt))"
                )
            }
            .padding(12)
            .background(theme.inputSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(theme.hairline)
            )

            HStack(spacing: 10) {
                Button(action: onCycleDeadline) {
                    Label("Échéance suivante", systemImage: "forward.end")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(reminder.isArchived)

                Button(action: onToggleArchived) {
                    Label(reminder.isArchived ? "Restaurer" : "Archiver", systemImage: reminder.isArchived ? "arrow.uturn.backward.circle" : "archivebox")
                }
                .buttonStyle(SecondaryButtonStyle())

                Spacer()
            }
        }
    }
}

private struct TrackingMetricCard: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(tint)

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(theme.isDark ? 0.15 : 0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.18))
        )
    }
}

private struct TrackingInfoRow: View {
    let systemImage: String
    let title: String
    let value: String
    let detail: String?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(value)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }

                if let detail {
                    Text(detail)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

private struct NoteWritingPanel: View {
    @Binding var note: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label("Notes", systemImage: "pencil.line")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(characterCountText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(theme.inputSurface)

                if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Écrire la note...")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.50))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 17)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $note)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
            }
            .frame(minHeight: 220)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(theme.accent.opacity(0.18), lineWidth: 1)
            )
        }
    }

    private var characterCountText: String {
        PunaiseLanguage.current == .english
            ? "\(note.count) character\(note.count > 1 ? "s" : "")"
            : "\(note.count) caractères"
    }
}

private struct AttachmentEditor: View {
    let attachments: [PunaiseAttachment]
    let onAddAttachment: (AttachmentKind, String, String) -> Void
    let onRemoveAttachment: (PunaiseAttachment.ID) -> Void

    @State private var linkText = ""
    @State private var mailText = ""

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

            HStack(spacing: 8) {
                Image(systemName: "envelope")
                    .foregroundStyle(.secondary)
                TextField("mail@exemple.com ou message://...", text: $mailText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addMail)
                Button("Joindre") {
                    addMail()
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(mailText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

    private func addMail() {
        let trimmed = mailText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onAddAttachment(.mail, trimmed, "")
        mailText = ""
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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

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
            .buttonStyle(BouncyPlainButtonStyle(pressedScale: 0.84))
            .help("Ouvrir")

            Button(role: .destructive, action: onRemove) {
                Image(systemName: "xmark.circle")
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(BouncyPlainButtonStyle(pressedScale: 0.84))
            .help("Retirer")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(theme.inputSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(theme.hairline)
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
                    Text(reminder.isPinned ? PunaiseL10n.string("Punaisée sur le bureau") : PunaiseL10n.string("Dans le tableau"))
                        .font(.system(size: 14, weight: .semibold))
                }

                Text(PunaiseDateFormatting.shortDateTime.string(from: reminder.deadline))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                if !reminder.attachments.isEmpty {
                    Label(attachmentCountText, systemImage: "paperclip")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    private var attachmentCountText: String {
        let count = reminder.attachments.count
        return PunaiseLanguage.current == .english
            ? "\(count) attachment\(count > 1 ? "s" : "")"
            : "\(count) pièce\(count > 1 ? "s" : "") jointe\(count > 1 ? "s" : "")"
    }
}

private struct FooterActions: View {
    let isArchived: Bool
    let onPostpone: () -> Void
    let onComplete: () -> Void
    let onToggleArchived: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onPostpone) {
                Label("Reporter 1 h", systemImage: "clock.arrow.circlepath")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(isArchived)
            .help("Reporter d’une heure")

            Button(action: isArchived ? onToggleArchived : onComplete) {
                Label(PunaiseL10n.string(isArchived ? "Restaurer" : "Terminer"), systemImage: isArchived ? "arrow.uturn.backward.circle" : "checkmark.circle")
            }
            .buttonStyle(SecondaryButtonStyle())

            Spacer()

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(BouncyPlainButtonStyle(pressedScale: 0.84))
            .help("Supprimer")

            Button(action: onDuplicate) {
                Image(systemName: "square.on.square")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(BouncyPlainButtonStyle(pressedScale: 0.84))
            .help("Dupliquer")
        }
        .foregroundStyle(.secondary)
    }
}

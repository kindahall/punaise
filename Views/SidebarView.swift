import SwiftUI

struct SidebarView: View {
    let reminders: [Reminder]
    let allReminders: [Reminder]
    @Binding var selectedID: Reminder.ID?
    @Binding var searchText: String
    @Binding var filter: ReminderFilter
    let now: Date
    let isPro: Bool
    let activeCount: Int
    let onCleanDesktop: () -> Void
    let onShowLicense: (PunaiseProFeature) -> Void
    let onTogglePin: (Reminder.ID) -> Void
    let onComplete: (Reminder.ID) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(PunaisePreferenceKey.language) private var language = PunaiseLanguage.default.rawValue
    @Namespace private var selectionAnimation

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        VStack(spacing: 14) {
            header
            pressureMeter
            searchField
            filterPicker
            reminderList
        }
        .background {
            theme.sidebarBase
            Rectangle()
                .fill(.regularMaterial)
                .opacity(theme.isDark ? 0.20 : 0)
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(theme.hairline)
                .frame(width: 1)
        }
    }

    private var header: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                PunaiseLogo(size: 28)

                Text("Punaise")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(theme.brand)

                Spacer()

                LanguageToggleButton()
                AppearanceToggleButton()
            }

            Text("Épingle ce qui presse.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    private var pressureMeter: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)
        let active = allReminders.filter { !$0.isArchived }
        let urgentCount = active.filter { $0.status(at: now).isUrgentNow }.count
        let overdueCount = active.filter { $0.status(at: now) == .overdue }.count
        let postponedCount = active.filter { $0.postponeCount > 0 }.count
        let pressure = active.map { $0.pressureScore(at: now) }.max() ?? 0

        return Group {
            if isPro {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Pression mentale")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(pressure)/100")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(pressure > 84 ? .red : .secondary)
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(theme.hoverSurface)
                            Capsule()
                                .fill(pressureColor(pressure))
                                .frame(width: proxy.size.width * CGFloat(pressure) / 100)
                        }
                    }
                    .frame(height: 7)

                    Text(pressureSummary(urgentCount: urgentCount))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        PressureStatChip(title: "Ouvertes", value: active.count, color: .blue)
                        PressureStatChip(title: "Critiques", value: urgentCount, color: .red)
                        PressureStatChip(title: "Noires", value: overdueCount, color: .black)
                        PressureStatChip(title: "Reportées", value: postponedCount, color: .orange)
                    }
                    .id(language)

                    Button(action: onCleanDesktop) {
                        Label("Bureau propre", systemImage: "square.grid.2x2")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.top, 2)
                }
                .padding(12)
                .background(theme.panelSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(theme.hairline)
                )
                .padding(.horizontal, 20)
            } else {
                FreeUsageCard(activeCount: activeCount, onShowLicense: onShowLicense)
            }
        }
    }

    private var searchField: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        return HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Chercher une Punaise...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(theme.inputSurface, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(theme.hairline)
        )
        .padding(.horizontal, 20)
    }

    private var filterPicker: some View {
        Picker("", selection: $filter) {
            ForEach(ReminderFilter.allCases) { filter in
                Text(LocalizedStringKey(filter.titleKey)).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .id(language)
    }

    private var reminderList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 4) {
                ForEach(reminders) { reminder in
                    SidebarReminderRow(
                        reminder: reminder,
                        now: now,
                        isSelected: selectedID == reminder.id,
                        namespace: selectionAnimation,
                        onTogglePin: {
                            onTogglePin(reminder.id)
                        },
                        onComplete: {
                            onComplete(reminder.id)
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedID = reminder.id
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
            .padding(.top, 4)
        }
    }

    private func pressureSummary(urgentCount: Int) -> String {
        if urgentCount == 0 {
            return PunaiseL10n.string("Rien ne crie pour l’instant.")
        }

        if PunaiseLanguage.current == .english {
            return "\(urgentCount) Punaise\(urgentCount > 1 ? "s" : "") in front of you."
        }

        return "\(urgentCount) Punaise\(urgentCount > 1 ? "s" : "") devant tes yeux."
    }

    private func pressureColor(_ pressure: Int) -> Color {
        switch pressure {
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

private struct PressureStatChip: View {
    let title: String
    let value: Int
    let color: Color
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)
        let foreground = resolvedForeground(theme: theme)
        let background = resolvedBackground(theme: theme)

        VStack(spacing: 1) {
            Text("\(value)")
                .font(.system(size: 12, weight: .bold))
                .monospacedDigit()
            Text(LocalizedStringKey(title))
                .font(.system(size: 8, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(background, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(foreground.opacity(theme.isDark ? 0.18 : 0.10))
        )
    }

    private func resolvedForeground(theme: PunaiseTheme) -> Color {
        guard title == "Noires" else { return color }
        return theme.isDark ? Color(red: 0.86, green: 0.88, blue: 0.92) : .black
    }

    private func resolvedBackground(theme: PunaiseTheme) -> Color {
        guard title == "Noires" else {
            return color.opacity(theme.isDark ? 0.16 : 0.10)
        }

        return theme.isDark
            ? Color.white.opacity(0.105)
            : Color.black.opacity(0.10)
    }
}

private struct SidebarReminderRow: View {
    let reminder: Reminder
    let now: Date
    let isSelected: Bool
    let namespace: Namespace.ID
    let onTogglePin: () -> Void
    let onComplete: () -> Void

    @State private var isHovered = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)
        let status = reminder.status(at: now)
        let tint = rowColor(for: reminder, status: status)

        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(tint)
                .frame(width: 15, height: 15)
                .shadow(color: tint.opacity(theme.isDark ? 0.34 : 0.18), radius: 5)

            VStack(alignment: .leading, spacing: 5) {
                Text(reminder.displayTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)

                HStack(spacing: 5) {
                    Text(PunaiseDateFormatting.relativeDeadline(reminder.deadline, now: now))
                    Text("•")
                    Text(status.title)
                }
                .font(.system(size: 12))
                .foregroundStyle(status == .overdue ? .red : .secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text("\(reminder.pressureScore(at: now))")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(status == .overdue ? .white : tint)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    (status == .overdue ? Color.black : tint.opacity(theme.isDark ? 0.18 : 0.12)),
                    in: Capsule()
                )

            SidebarMetadataBadges(reminder: reminder)

            if isHovered || isSelected {
                Button(action: onComplete) {
                    Image(systemName: "checkmark.circle")
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(BouncyPlainButtonStyle(pressedScale: 0.82))
                .foregroundStyle(theme.calmGreen)
                .help("Terminer")
            }

            Button(action: onTogglePin) {
                Image(systemName: reminder.isPinned ? "pin.fill" : "pin")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(BouncyPlainButtonStyle(pressedScale: 0.82))
            .foregroundStyle(reminder.isPinned ? tint : .secondary)
            .help(reminder.isPinned ? "Désépingler" : "Punaiser")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background {
            if isSelected {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(theme.selectedSurface)
                    .matchedGeometryEffect(id: "selection", in: namespace)
                    .shadow(color: theme.linkBlue.opacity(theme.isDark ? 0.24 : 0.18), radius: 10, y: 4)
            } else if isHovered {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(theme.hoverSurface)
            }
        }
        .overlay(alignment: .leading) {
            if isSelected {
                Capsule()
                    .fill(theme.linkBlue)
                    .frame(width: 3, height: 28)
                    .padding(.leading, 3)
                    .transition(.opacity)
            }
        }
        .onHover { isHovered = $0 }
        .scaleEffect(isHovered && !isSelected ? 1.018 : 1.0)
        .animation(.interpolatingSpring(stiffness: 320, damping: 20), value: isHovered)
        .animation(.interpolatingSpring(stiffness: 300, damping: 22), value: isSelected)
    }

    private func rowColor(for reminder: Reminder, status: ReminderStatus) -> Color {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        switch status {
        case .overdue:
            return .black
        case .critical:
            return theme.urgencyRed
        case .pressing:
            return theme.urgencyOrange
        case .watching:
            switch reminder.urgency {
            case .urgent:
                return theme.urgencyYellow
            case .neutral:
                return theme.linkBlue
            case .relaxed:
                return theme.calmGreen
            }
        case .calm:
            switch reminder.urgency {
            case .urgent:
                return theme.urgencyYellow
            case .neutral:
                return theme.linkBlue
            case .relaxed:
                return theme.calmGreen
            }
        }
    }
}

private struct SidebarMetadataBadges: View {
    let reminder: Reminder

    var body: some View {
        HStack(spacing: 4) {
            if let source = reminder.externalSource {
                Image(systemName: source.provider.systemImage)
                    .help("Importé depuis \(source.provider.title)")
            }

            if reminder.recurrence != .none {
                Image(systemName: "repeat")
                    .help(reminder.recurrence.title)
            }

            if !reminder.attachments.isEmpty {
                Image(systemName: "paperclip")
                    .help("\(reminder.attachments.count) pièce\(reminder.attachments.count > 1 ? "s" : "") jointe\(reminder.attachments.count > 1 ? "s" : "")")
            }
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.secondary)
        .frame(minWidth: 0)
    }
}

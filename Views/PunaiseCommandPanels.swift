import SwiftUI

struct QuickCaptureBar: View {
    @State private var input = ""
    let onSubmit: (String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.circle.fill")
                .foregroundStyle(.orange)

            TextField("appeler fournisseur demain 18h urgent", text: $input)
                .textFieldStyle(.plain)
                .onSubmit(submit)

            Button(action: submit) {
                Label("Punaiser", systemImage: "pin.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.black.opacity(0.08))
        )
    }

    private func submit() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit(trimmed)
        input = ""
    }
}

struct PunaiseContextPanel: View {
    let filter: ReminderFilter
    let reminders: [Reminder]
    @Binding var selectedID: Reminder.ID?
    let now: Date

    var body: some View {
        Group {
            switch filter {
            case .all:
                BoardPanel(reminders: reminders, selectedID: $selectedID, now: now)
            case .pinned:
                DesktopPanel(reminders: reminders, selectedID: $selectedID, now: now)
            case .urgentNow:
                UrgencyNowPanel(reminders: reminders, selectedID: $selectedID, now: now)
            case .history:
                HistoryPanel(reminders: reminders, selectedID: $selectedID, now: now)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct BoardPanel: View {
    let reminders: [Reminder]
    @Binding var selectedID: Reminder.ID?
    let now: Date

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                PanelTitle(title: "Tableau des Punaises", subtitle: "Punaise rend l’urgence visible.")
                ForEach(reminders.prefix(4)) { reminder in
                    CompactPunaiseRow(reminder: reminder, selectedID: $selectedID, now: now)
                }
            }

            Divider().opacity(0.35)

            MiniCalendarPanel(reminders: reminders, now: now)
                .frame(width: 190)
        }
        .panelChrome()
    }
}

private struct DesktopPanel: View {
    let reminders: [Reminder]
    @Binding var selectedID: Reminder.ID?
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle(title: "Bureau Mac", subtitle: "Les Punaises épinglées restent devant toi.")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(reminders.prefix(5)) { reminder in
                        Button {
                            selectedID = reminder.id
                        } label: {
                            StickyCardView(reminder: reminder, now: now, scale: .mini)
                                .frame(width: 132, height: 88)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .panelChrome()
    }
}

private struct UrgencyNowPanel: View {
    let reminders: [Reminder]
    @Binding var selectedID: Reminder.ID?
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle(title: "Urgences maintenant", subtitle: "Ce qui presse remonte visuellement.")

            let grouped = remindersByStatus
            ForEach([ReminderStatus.overdue, .critical, .pressing], id: \.self) { status in
                if let items = grouped[status], !items.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        StatusDot(status: status)
                            .padding(.top, 7)
                        VStack(spacing: 6) {
                            ForEach(items.prefix(3)) { reminder in
                                CompactPunaiseRow(reminder: reminder, selectedID: $selectedID, now: now)
                            }
                        }
                    }
                }
            }
        }
        .panelChrome()
    }

    private var remindersByStatus: [ReminderStatus: [Reminder]] {
        Dictionary(grouping: reminders) { reminder in
            reminder.status(at: now)
        }
    }
}

private struct HistoryPanel: View {
    let reminders: [Reminder]
    @Binding var selectedID: Reminder.ID?
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PanelTitle(title: "Historique", subtitle: "Les Punaises terminées sortent du bureau.")

            if reminders.isEmpty {
                Text("Aucune Punaise terminée.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(reminders.prefix(4)) { reminder in
                    CompactPunaiseRow(reminder: reminder, selectedID: $selectedID, now: now)
                }
            }
        }
        .panelChrome()
    }
}

private struct MiniCalendarPanel: View {
    let reminders: [Reminder]
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mini calendrier")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)

            ForEach(Self.offsets, id: \.self) { offset in
                MiniCalendarDayRow(offset: offset, reminders: reminders, now: now)
            }
        }
    }

    private static let offsets = [0, 1, 2, 3, 4]
}

private struct MiniCalendarDayRow: View {
    let offset: Int
    let reminders: [Reminder]
    let now: Date

    var body: some View {
        let day = Calendar.current.date(byAdding: .day, value: offset, to: now) ?? now
        let count = reminders.filter { Calendar.current.isDate($0.deadline, inSameDayAs: day) }.count

        HStack {
            Text(dayLabel(day, offset: offset))
                .font(.system(size: 12, weight: .semibold))
            Spacer()
            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(count == 0 ? Color.secondary : Color.orange)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.black.opacity(0.05), in: Capsule())
        }
    }

    private func dayLabel(_ date: Date, offset: Int) -> String {
        if offset == 0 { return "Aujourd’hui" }
        if offset == 1 { return "Demain" }
        return PunaiseDateFormatting.weekdayShort.string(from: date)
    }
}

private struct CompactPunaiseRow: View {
    let reminder: Reminder
    @Binding var selectedID: Reminder.ID?
    let now: Date

    var body: some View {
        Button {
            selectedID = reminder.id
        } label: {
            HStack(spacing: 10) {
                StatusDot(status: reminder.status(at: now))

                VStack(alignment: .leading, spacing: 2) {
                    Text(reminder.displayTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("\(PunaiseDateFormatting.relativeDeadline(reminder.deadline, now: now)) · \(reminder.urgency.title)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("\(reminder.pressureScore(at: now))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct PanelTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
            Spacer()
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

private struct StatusDot: View {
    let status: ReminderStatus

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .shadow(color: color.opacity(status == .critical ? 0.55 : 0.15), radius: status == .critical ? 5 : 2)
    }

    private var color: Color {
        switch status {
        case .calm:
            return .green
        case .watching:
            return .yellow
        case .pressing:
            return .orange
        case .critical:
            return .red
        case .overdue:
            return .black
        }
    }
}

private extension View {
    func panelChrome() -> some View {
        self
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.black.opacity(0.08))
            )
    }
}

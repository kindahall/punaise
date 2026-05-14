import SwiftUI

struct SidebarView: View {
    let reminders: [Reminder]
    let allReminders: [Reminder]
    @Binding var selectedID: Reminder.ID?
    @Binding var searchText: String
    @Binding var filter: ReminderFilter
    let now: Date

    var body: some View {
        VStack(spacing: 14) {
            header
            pressureMeter
            searchField
            filterPicker
            reminderList
        }
        .background(.regularMaterial)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                PunaiseLogo(size: 28)

                Text("Punaise")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(red: 0.09, green: 0.22, blue: 0.39))

                Spacer()
            }

            Text("Épingle ce qui presse.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    private var pressureMeter: some View {
        let active = allReminders.filter { !$0.isArchived }
        let urgentCount = active.filter { $0.status(at: now).isUrgentNow }.count
        let overdueCount = active.filter { $0.status(at: now) == .overdue }.count
        let postponedCount = active.filter { $0.postponeCount > 0 }.count
        let pressure = active.map { $0.pressureScore(at: now) }.max() ?? 0

        return VStack(alignment: .leading, spacing: 8) {
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
                        .fill(.black.opacity(0.08))
                    Capsule()
                        .fill(pressureColor(pressure))
                        .frame(width: proxy.size.width * CGFloat(pressure) / 100)
                }
            }
            .frame(height: 7)

            Text(urgentCount == 0 ? "Rien ne crie pour l’instant." : "\(urgentCount) Punaise\(urgentCount > 1 ? "s" : "") devant tes yeux.")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 6) {
                PressureStatChip(title: "Ouvertes", value: active.count, color: .blue)
                PressureStatChip(title: "Critiques", value: urgentCount, color: .red)
                PressureStatChip(title: "Noires", value: overdueCount, color: .black)
                PressureStatChip(title: "Reportées", value: postponedCount, color: .orange)
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.black.opacity(0.08))
        )
        .padding(.horizontal, 20)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Chercher une Punaise...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(.black.opacity(0.08))
        )
        .padding(.horizontal, 20)
    }

    private var filterPicker: some View {
        Picker("", selection: $filter) {
            ForEach(ReminderFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
    }

    private var reminderList: some View {
        List(selection: $selectedID) {
            ForEach(reminders) { reminder in
                SidebarReminderRow(reminder: reminder, now: now)
                    .tag(Optional(reminder.id))
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, 8)
        .padding(.bottom, 12)
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

    var body: some View {
        VStack(spacing: 1) {
            Text("\(value)")
                .font(.system(size: 12, weight: .bold))
                .monospacedDigit()
            Text(title)
                .font(.system(size: 8, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

private struct SidebarReminderRow: View {
    let reminder: Reminder
    let now: Date

    var body: some View {
        let status = reminder.status(at: now)

        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(rowColor(for: reminder, status: status))
                .frame(width: 15, height: 15)

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
                .foregroundStyle(status == .overdue ? .white : rowColor(for: reminder, status: status))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    (status == .overdue ? Color.black : rowColor(for: reminder, status: status).opacity(0.12)),
                    in: Capsule()
                )

            if reminder.isPinned {
                Image(systemName: "pin.fill")
                    .foregroundStyle(rowColor(for: reminder, status: status))
                    .help("Punaisée sur le bureau")
            }
        }
        .padding(.vertical, 8)
    }

    private func rowColor(for reminder: Reminder, status: ReminderStatus) -> Color {
        switch status {
        case .overdue:
            return .black
        case .critical:
            return Color(red: 0.94, green: 0.10, blue: 0.09)
        case .pressing:
            return Color(red: 0.93, green: 0.42, blue: 0.08)
        case .watching:
            return Color(red: 0.88, green: 0.62, blue: 0.12)
        case .calm:
            switch reminder.urgency {
            case .urgent:
                return Color(red: 0.82, green: 0.55, blue: 0.14)
            case .neutral:
                return Color(red: 0.23, green: 0.55, blue: 0.86)
            case .relaxed:
                return Color(red: 0.37, green: 0.75, blue: 0.27)
            }
        }
    }
}

import SwiftUI

struct DeadlineAgendaSheet: View {
    @Binding var deadline: Date
    @Binding var isPresented: Bool

    @State private var displayedMonth: Date
    @State private var hour: Int
    @State private var minute: Int

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    init(deadline: Binding<Date>, isPresented: Binding<Bool>) {
        _deadline = deadline
        _isPresented = isPresented
        let date = deadline.wrappedValue
        _displayedMonth = State(initialValue: Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date)) ?? date)
        _hour = State(initialValue: Calendar.current.component(.hour, from: date))
        _minute = State(initialValue: Calendar.current.component(.minute, from: date))
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            HStack(alignment: .top, spacing: 22) {
                monthCalendar
                    .frame(width: 560)

                Divider()

                sidePanel
                    .frame(width: 260)
            }
            .padding(24)

            Divider()

            footer
        }
        .frame(width: 900, height: 680)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(red: 1.0, green: 0.86, blue: 0.52).opacity(0.16),
                    Color(nsColor: .windowBackgroundColor)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            PunaiseLogo(size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text("Échéance")
                    .font(.system(size: 24, weight: .semibold))
                Text(PunaiseDateFormatting.shortDateTime.string(from: deadline))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(IconButtonStyle())
            .help("Fermer")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    private var monthCalendar: some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    moveMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(IconButtonStyle())

                Spacer()

                Text(PunaiseDateFormatting.monthYear.string(from: displayedMonth).capitalized)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color(red: 0.08, green: 0.22, blue: 0.40))

                Spacer()

                Button {
                    moveMonth(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(IconButtonStyle())
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 10) {
                ForEach(weekdaySymbols, id: \.self) { weekday in
                    Text(weekday.prefix(2).uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(height: 22)
                }

                ForEach(calendarDays) { day in
                    DeadlineDayCell(
                        day: day,
                        selectedDate: deadline,
                        displayedMonth: displayedMonth,
                        onSelect: { selectedDay in
                            setDay(selectedDay.date)
                        }
                    )
                }
            }
        }
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.black.opacity(0.08))
        )
    }

    private var sidePanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Heure")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Stepper(value: $hour, in: 0...23, step: 1) {
                        Text(String(format: "%02d", hour))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .frame(width: 52)
                    }

                    Text(":")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.secondary)

                    Stepper(value: $minute, in: 0...55, step: 5) {
                        Text(String(format: "%02d", minute))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .frame(width: 52)
                    }
                }
                .onChange(of: hour) { _ in applyTime() }
                .onChange(of: minute) { _ in applyTime() }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Rapide")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)

                QuickDeadlineButton(title: "Aujourd’hui 18:00") {
                    setQuickDate(dayOffset: 0, hour: 18, minute: 0)
                }

                QuickDeadlineButton(title: "Demain 09:00") {
                    setQuickDate(dayOffset: 1, hour: 9, minute: 0)
                }

                QuickDeadlineButton(title: "Demain 18:00") {
                    setQuickDate(dayOffset: 1, hour: 18, minute: 0)
                }

                QuickDeadlineButton(title: "Dans 1 semaine") {
                    setQuickDate(dayOffset: 7, hour: 9, minute: 0)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text("Sélection")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                Text(PunaiseDateFormatting.shortDateTime.string(from: deadline))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(PunaiseDateFormatting.relativeDeadline(deadline, now: Date()))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var footer: some View {
        HStack {
            Button {
                setQuickDate(dayOffset: 0, hour: Calendar.current.component(.hour, from: Date()), minute: roundedMinute(Calendar.current.component(.minute, from: Date())))
            } label: {
                Label("Maintenant", systemImage: "clock")
            }
            .buttonStyle(SecondaryButtonStyle())

            Spacer()

            Button("Annuler") {
                isPresented = false
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Button {
                isPresented = false
            } label: {
                Label("Valider l’échéance", systemImage: "checkmark")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var calendarDays: [DeadlineCalendarDay] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
            let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
            let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end.addingTimeInterval(-1))
        else {
            return []
        }

        var days: [DeadlineCalendarDay] = []
        var current = firstWeek.start

        while current < lastWeek.end {
            days.append(DeadlineCalendarDay(date: current))
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        return days
    }

    private func moveMonth(_ value: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }

    private func setDay(_ date: Date) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        deadline = calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: calendar.date(from: components) ?? date
        ) ?? date
    }

    private func applyTime() {
        deadline = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: deadline) ?? deadline
    }

    private func setQuickDate(dayOffset: Int, hour: Int, minute: Int) {
        let base = calendar.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
        self.hour = hour
        self.minute = minute
        deadline = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        displayedMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: deadline)) ?? displayedMonth
    }

    private func roundedMinute(_ value: Int) -> Int {
        min(55, max(0, Int((Double(value) / 5.0).rounded()) * 5))
    }
}

private struct DeadlineCalendarDay: Identifiable {
    let date: Date
    var id: Date { date }
}

private struct DeadlineDayCell: View {
    let day: DeadlineCalendarDay
    let selectedDate: Date
    let displayedMonth: Date
    let onSelect: (DeadlineCalendarDay) -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button {
            onSelect(day)
        } label: {
            VStack(spacing: 3) {
                Text(PunaiseDateFormatting.dayNumber.string(from: day.date))
                    .font(.system(size: 18, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .monospacedDigit()

                Circle()
                    .fill(isToday ? Color.orange : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .foregroundStyle(foreground)
            .frame(height: 62)
            .frame(maxWidth: .infinity)
            .background(background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.orange.opacity(0.50) : Color.black.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }

    private var isSelected: Bool {
        calendar.isDate(day.date, inSameDayAs: selectedDate)
    }

    private var isToday: Bool {
        calendar.isDateInToday(day.date)
    }

    private var isCurrentMonth: Bool {
        calendar.component(.month, from: day.date) == calendar.component(.month, from: displayedMonth)
    }

    private var background: Color {
        if isSelected {
            return Color.orange.opacity(0.18)
        }
        if isToday {
            return Color.orange.opacity(0.08)
        }
        return Color.black.opacity(0.025)
    }

    private var foreground: Color {
        if isSelected {
            return .orange
        }
        return isCurrentMonth ? .primary : .secondary.opacity(0.45)
    }
}

private struct QuickDeadlineButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(SecondaryButtonStyle())
    }
}

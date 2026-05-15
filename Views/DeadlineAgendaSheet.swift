import SwiftUI

struct DeadlineAgendaSheet: View {
    @Binding var deadline: Date
    @Binding var isPresented: Bool

    @State private var displayedMonth: Date
    @State private var hour: Int
    @State private var minute: Int
    @Environment(\.colorScheme) private var colorScheme

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.locale = PunaiseLanguage.current.locale
        return calendar
    }

    private var weekdaySymbols: [String] {
        calendar.shortWeekdaySymbols
    }

    init(deadline: Binding<Date>, isPresented: Binding<Bool>) {
        _deadline = deadline
        _isPresented = isPresented
        let date = deadline.wrappedValue
        _displayedMonth = State(initialValue: Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date)) ?? date)
        _hour = State(initialValue: Calendar.current.component(.hour, from: date))
        _minute = State(initialValue: Calendar.current.component(.minute, from: date))
    }

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        VStack(spacing: 0) {
            header

            HStack(alignment: .top, spacing: 22) {
                monthCalendar
                    .frame(width: 540)

                Divider()

                sidePanel
                    .frame(width: 268)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxHeight: .infinity, alignment: .top)

            Divider()

            footer
        }
        .frame(width: 880, height: 620)
        .background {
            theme.windowBase
            if theme.isDark {
                LinearGradient(
                    colors: [
                        theme.accent.opacity(0.10),
                        .clear,
                        theme.linkBlue.opacity(0.07)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            PunaiseLogo(size: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(PunaiseL10n.string("Échéance"))
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
            .help(PunaiseL10n.string("Fermer"))
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var monthCalendar: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        return VStack(spacing: 10) {
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Button {
                    moveMonth(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(IconButtonStyle())
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(weekdaySymbols, id: \.self) { weekday in
                    Text(weekday.prefix(2).uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(height: 18)
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
        .padding(14)
        .background(theme.panelSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(theme.hairline)
        )
    }

    private var sidePanel: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(PunaiseL10n.string("Heure"))
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
                Text(PunaiseL10n.string("Rapide"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)

                QuickDeadlineButton(title: "\(PunaiseL10n.string("Aujourd’hui")) 18:00") {
                    setQuickDate(dayOffset: 0, hour: 18, minute: 0)
                }

                QuickDeadlineButton(title: "\(PunaiseL10n.string("Demain")) 09:00") {
                    setQuickDate(dayOffset: 1, hour: 9, minute: 0)
                }

                QuickDeadlineButton(title: "\(PunaiseL10n.string("Demain")) 18:00") {
                    setQuickDate(dayOffset: 1, hour: 18, minute: 0)
                }

                QuickDeadlineButton(title: PunaiseL10n.string("Dans 1 semaine")) {
                    setQuickDate(dayOffset: 7, hour: 9, minute: 0)
                }
            }

            Spacer()

            VStack(alignment: .leading, spacing: 6) {
                Text(PunaiseL10n.string("Sélection"))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                Text(PunaiseDateFormatting.shortDateTime.string(from: deadline))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                Text(PunaiseDateFormatting.relativeDeadline(deadline, now: Date()))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.inputSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(theme.hairline)
            )
        }
    }

    private var footer: some View {
        HStack {
            Button {
                setQuickDate(dayOffset: 0, hour: Calendar.current.component(.hour, from: Date()), minute: roundedMinute(Calendar.current.component(.minute, from: Date())))
            } label: {
                Label(PunaiseL10n.string("Maintenant"), systemImage: "clock")
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .buttonStyle(SecondaryButtonStyle())

            Spacer()

            Button(PunaiseL10n.string("Annuler")) {
                isPresented = false
            }
            .buttonStyle(BouncyPlainButtonStyle())
            .foregroundStyle(.secondary)

            Button {
                isPresented = false
            } label: {
                Label(PunaiseL10n.string("Valider l’échéance"), systemImage: "checkmark")
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
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
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? Color.orange.opacity(0.50) : Color.black.opacity(0.06))
            )
        }
        .buttonStyle(BouncyPlainButtonStyle())
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

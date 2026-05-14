import SwiftUI

struct UrgencyNowWindow: View {
    @ObservedObject var store: ReminderStore
    let onOpen: (Reminder.ID) -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let items = urgentReminders(at: context.date)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    PunaiseLogo(size: 30)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Ce qui presse")
                            .font(.system(size: 20, weight: .semibold))
                        Text(PunaiseDateFormatting.shortDateTime.string(from: context.date))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                if items.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 8) {
                        ForEach(items) { reminder in
                            UrgencyNowRow(
                                reminder: reminder,
                                now: context.date,
                                onOpen: {
                                    onOpen(reminder.id)
                                },
                                onPostpone: {
                                    store.postpone(reminder.id, by: .hour, value: 1)
                                },
                                onComplete: {
                                    store.complete(reminder.id)
                                }
                            )
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(18)
            .frame(width: 390, height: 360)
            .background(.regularMaterial)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.green)

            Text("Rien de critique")
                .font(.system(size: 15, weight: .bold))

            Text("Les Punaises calmes restent dans le tableau.")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func urgentReminders(at now: Date) -> [Reminder] {
        Array(
            store.reminders
                .filter { !$0.isArchived && $0.status(at: now).isUrgentNow }
                .sorted { first, second in
                    if first.pressureScore(at: now) != second.pressureScore(at: now) {
                        return first.pressureScore(at: now) > second.pressureScore(at: now)
                    }

                    return first.deadline < second.deadline
                }
                .prefix(5)
        )
    }
}

private struct UrgencyNowRow: View {
    let reminder: Reminder
    let now: Date
    let onOpen: () -> Void
    let onPostpone: () -> Void
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .shadow(color: color.opacity(0.35), radius: 4)

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(reminder.displayTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(PunaiseDateFormatting.relativeDeadline(reminder.deadline, now: now))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Text("\(reminder.pressureScore(at: now))")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
                .monospacedDigit()
                .frame(width: 28, alignment: .trailing)

            Button(action: onPostpone) {
                Image(systemName: "clock.arrow.circlepath")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Reporter d’une heure")

            Button(action: onComplete) {
                Image(systemName: "checkmark.circle")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Terminer")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
    }

    private var color: Color {
        switch reminder.status(at: now) {
        case .overdue:
            return .black
        case .critical:
            return .red
        case .pressing:
            return .orange
        case .watching:
            return .yellow
        case .calm:
            return .green
        }
    }
}

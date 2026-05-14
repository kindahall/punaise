import SwiftUI

struct CalendarImportSheet: View {
    @ObservedObject var importer: CalendarImportStore
    let onImport: ([CalendarEventCandidate]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedEventIDs: Set<String> = []

    private var selectedEvents: [CalendarEventCandidate] {
        importer.events.filter { selectedEventIDs.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            Group {
                if importer.hasAccess {
                    connectedContent
                } else {
                    permissionContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
            footer
        }
        .frame(width: 820, height: 620)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(red: 0.84, green: 0.93, blue: 1.0).opacity(0.22),
                    Color(nsColor: .windowBackgroundColor)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            if importer.hasAccess {
                importer.refresh()
            }
        }
        .onChange(of: importer.events) { events in
            guard selectedEventIDs.isEmpty else { return }
            selectedEventIDs = Set(events.prefix(8).map(\.id))
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            PunaiseLogo(size: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text("Google Agenda")
                    .font(.system(size: 24, weight: .semibold))
                Text("Créer des Punaises depuis les échéances détectées.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                dismiss()
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

    private var permissionContent: some View {
        VStack(spacing: 18) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(.blue)

            Text(importer.isDenied ? "Accès calendrier bloqué" : "Connecter Google Agenda")
                .font(.system(size: 22, weight: .bold))

            Text(permissionText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(width: 440)

            HStack(spacing: 10) {
                if importer.isDenied {
                    Button {
                        importer.openCalendarPrivacySettings()
                    } label: {
                        Label("Ouvrir les réglages", systemImage: "gearshape")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                } else {
                    Button {
                        importer.connect()
                    } label: {
                        Label("Connecter Google Agenda", systemImage: "calendar")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }

            if let errorMessage = importer.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red)
            }
        }
        .padding(32)
    }

    private var connectedContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("\(importer.events.count) candidat\(importer.events.count > 1 ? "s" : "") détecté\(importer.events.count > 1 ? "s" : "")", systemImage: "calendar")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    selectedEventIDs = Set(importer.events.map(\.id))
                } label: {
                    Text("Tout sélectionner")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(importer.events.isEmpty)

                Button {
                    importer.refresh()
                } label: {
                    Label("Actualiser", systemImage: "arrow.clockwise")
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            if importer.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if importer.events.isEmpty {
                emptyState
            } else {
                eventList
            }
        }
        .padding(24)
    }

    private var eventList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(importer.events) { event in
                    CalendarEventImportRow(
                        event: event,
                        isSelected: Binding(
                            get: { selectedEventIDs.contains(event.id) },
                            set: { isSelected in
                                if isSelected {
                                    selectedEventIDs.insert(event.id)
                                } else {
                                    selectedEventIDs.remove(event.id)
                                }
                            }
                        )
                    )
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("Aucune échéance détectée.")
                .font(.system(size: 15, weight: .bold))
            Text("Punaise garde les événements qui ressemblent à une deadline dans les 14 prochains jours.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Text("\(selectedEvents.count) sélectionné\(selectedEvents.count > 1 ? "s" : "")")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            Button("Annuler") {
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Button {
                onImport(selectedEvents)
                dismiss()
            } label: {
                Label("Créer les Punaises", systemImage: "pin.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selectedEvents.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var permissionText: String {
        if importer.isDenied {
            return "Autorise Punaise dans Confidentialité > Calendriers, puis reviens actualiser l’import."
        }

        return "Punaise utilise Calendrier macOS. Ton agenda Google apparaît ici si ton compte Google est ajouté dans Comptes Internet."
    }
}

private struct CalendarEventImportRow: View {
    let event: CalendarEventCandidate
    @Binding var isSelected: Bool

    var body: some View {
        Toggle(isOn: $isSelected) {
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text(PunaiseDateFormatting.dayNumber.string(from: event.deadline))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(PunaiseDateFormatting.weekdayShort.string(from: event.deadline).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 54, height: 58)
                .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(event.displayTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(PunaiseDateFormatting.relativeDeadline(event.deadline, now: Date()))
                        Text("•")
                        Text(event.calendarTitle)
                        if !event.sourceTitle.isEmpty {
                            Text("•")
                            Text(event.sourceTitle)
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                Spacer()

                Label("\(event.deadlineScore)", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.10), in: Capsule())
                    .help(event.deadlineSignal)

                Label(event.suggestedUrgency.title, systemImage: event.suggestedUrgency.systemImage)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color(for: event.suggestedUrgency))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(color(for: event.suggestedUrgency).opacity(0.11), in: Capsule())
            }
            .padding(.vertical, 10)
            .padding(.trailing, 12)
        }
        .toggleStyle(.checkbox)
        .padding(.leading, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Color.blue.opacity(0.24) : Color.black.opacity(0.07))
        )
    }

    private func color(for urgency: Urgency) -> Color {
        switch urgency {
        case .urgent:
            return .red
        case .neutral:
            return .blue
        case .relaxed:
            return .green
        }
    }
}

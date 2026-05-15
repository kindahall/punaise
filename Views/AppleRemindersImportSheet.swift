import SwiftUI

struct AppleRemindersImportSheet: View {
    @ObservedObject var importer: AppleRemindersImportStore
    let onImport: ([ReminderCandidate]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedCandidateIDs: Set<String> = []

    private var selectedCandidates: [ReminderCandidate] {
        importer.candidates.filter { selectedCandidateIDs.contains($0.id) }
    }

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

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
        .background {
            theme.windowBase
            if theme.isDark {
                LinearGradient(
                    colors: [
                        theme.accent.opacity(0.12),
                        .clear,
                        theme.linkBlue.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .onAppear {
            if importer.hasAccess {
                importer.refresh()
            }
        }
        .onChange(of: importer.candidates) { candidates in
            guard selectedCandidateIDs.isEmpty else { return }
            selectedCandidateIDs = Set(candidates.prefix(8).map(\.id))
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            PunaiseLogo(size: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text("Apple Reminders")
                    .font(.system(size: 24, weight: .semibold))
                Text("Importer les rappels qui ont une vraie échéance.")
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
            Image(systemName: "checklist")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(.orange)

            Text(importer.isDenied ? "Accès rappels bloqué" : "Connecter Apple Reminders")
                .font(.system(size: 22, weight: .bold))

            Text(permissionText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(width: 440)

            if importer.isDenied {
                Button {
                    importer.openReminderPrivacySettings()
                } label: {
                    Label("Ouvrir les réglages", systemImage: "gearshape")
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button {
                    importer.connect()
                } label: {
                    Label("Connecter Apple Reminders", systemImage: "checklist")
                }
                .buttonStyle(PrimaryButtonStyle())
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
                Label(candidateCountText, systemImage: "checklist")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    selectedCandidateIDs = Set(importer.candidates.map(\.id))
                } label: {
                    Text("Tout sélectionner")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(importer.candidates.isEmpty)

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
            } else if importer.candidates.isEmpty {
                emptyState
            } else {
                candidateList
            }
        }
        .padding(24)
    }

    private var candidateList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(importer.candidates) { candidate in
                    AppleReminderImportRow(
                        candidate: candidate,
                        isSelected: Binding(
                            get: { selectedCandidateIDs.contains(candidate.id) },
                            set: { isSelected in
                                if isSelected {
                                    selectedCandidateIDs.insert(candidate.id)
                                } else {
                                    selectedCandidateIDs.remove(candidate.id)
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
            Image(systemName: "checkmark.circle")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("Aucun rappel pressant.")
                .font(.system(size: 15, weight: .bold))
            Text("Punaise garde les rappels non terminés avec date, priorité ou signal d’échéance.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Text(selectedCountText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            Button("Annuler") {
                dismiss()
            }
            .buttonStyle(BouncyPlainButtonStyle())
            .foregroundStyle(.secondary)

            Button {
                onImport(selectedCandidates)
                dismiss()
            } label: {
                Label("Créer les Punaises", systemImage: "pin.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selectedCandidates.isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var permissionText: String {
        if importer.isDenied {
            return PunaiseL10n.string("Autorise Punaise dans Confidentialité > Rappels, puis reviens actualiser l’import.")
        }

        return PunaiseL10n.string("Punaise utilise les rappels macOS et ne retient que ceux qui méritent de prendre forme sur le bureau.")
    }

    private var candidateCountText: String {
        let count = importer.candidates.count
        return PunaiseLanguage.current == .english
            ? "\(count) reminder\(count > 1 ? "s" : "") kept"
            : "\(count) rappel\(count > 1 ? "s" : "") retenu\(count > 1 ? "s" : "")"
    }

    private var selectedCountText: String {
        let count = selectedCandidates.count
        return PunaiseLanguage.current == .english
            ? "\(count) selected"
            : "\(count) sélectionné\(count > 1 ? "s" : "")"
    }
}

private struct AppleReminderImportRow: View {
    let candidate: ReminderCandidate
    @Binding var isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = PunaiseTheme(colorScheme: colorScheme)

        Toggle(isOn: $isSelected) {
            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text(PunaiseDateFormatting.dayNumber.string(from: candidate.deadline))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(PunaiseDateFormatting.weekdayShort.string(from: candidate.deadline).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 54, height: 58)
                .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(candidate.displayTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(PunaiseDateFormatting.relativeDeadline(candidate.deadline, now: Date()))
                        Text("•")
                        Text(candidate.listTitle)
                        if candidate.priority > 0 {
                            Text("•")
                            Text("P\(candidate.priority)")
                        }
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                Spacer()

                Label("\(candidate.deadlineScore)", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.10), in: Capsule())
                    .help(candidate.deadlineSignal)

                Label(candidate.suggestedUrgency.title, systemImage: candidate.suggestedUrgency.systemImage)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(color(for: candidate.suggestedUrgency))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(color(for: candidate.suggestedUrgency).opacity(0.11), in: Capsule())
            }
            .padding(.vertical, 10)
            .padding(.trailing, 12)
        }
        .toggleStyle(.checkbox)
        .padding(.leading, 12)
        .background(theme.panelSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Color.orange.opacity(0.26) : theme.hairline)
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

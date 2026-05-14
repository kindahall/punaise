import AppKit
import SwiftUI

struct PreferencesView: View {
    @ObservedObject var store: ReminderStore
    @ObservedObject var desktopController: DesktopStickyController
    let onShowOnboarding: () -> Void
    let onRequestNotifications: () -> Void

    @AppStorage(PunaisePreferenceKey.focusUrgenciesOnDesktop) private var focusUrgenciesOnDesktop = false
    @AppStorage(PunaisePreferenceKey.adaptiveDesktop) private var adaptiveDesktop = true
    @AppStorage(PunaisePreferenceKey.autoCleanDesktop) private var autoCleanDesktop = false
    @AppStorage(PunaisePreferenceKey.watchLeadHours) private var watchLeadHours = 72.0
    @AppStorage(PunaisePreferenceKey.pressingLeadHours) private var pressingLeadHours = 24.0
    @AppStorage(PunaisePreferenceKey.criticalLeadMinutes) private var criticalLeadMinutes = 120.0
    @AppStorage(PunaisePreferenceKey.encryptedBackups) private var encryptedBackups = true
    @AppStorage(PunaisePreferenceKey.iCloudDriveSync) private var iCloudDriveSync = false
    @State private var showsResetConfirmation = false
    @State private var backupMessage: SecureBackupMessage?

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            Form {
                Section {
                    Toggle("Afficher seulement les urgences sur le bureau", isOn: $focusUrgenciesOnDesktop)
                    Toggle("Bureau adaptatif", isOn: $adaptiveDesktop)
                    Toggle("Bureau propre automatique", isOn: $autoCleanDesktop)

                    Button {
                        desktopController.cleanDesktop(in: store)
                    } label: {
                        Label("Ranger maintenant", systemImage: "square.grid.2x2")
                    }
                } header: {
                    Text("Bureau")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("À surveiller")
                            Spacer()
                            Text("\(Int(watchLeadHours)) h avant")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }

                        Slider(value: $watchLeadHours, in: 1...336, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Pressant")
                            Spacer()
                            Text("\(Int(pressingLeadHours)) h avant")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }

                        Slider(value: $pressingLeadHours, in: 1...168, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Critique")
                            Spacer()
                            Text("\(Int(criticalLeadMinutes)) min avant")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }

                        Slider(value: $criticalLeadMinutes, in: 5...240, step: 5)
                    }

                    Button {
                        onRequestNotifications()
                    } label: {
                        Label("Autoriser les notifications", systemImage: "bell.badge")
                    }
                } header: {
                    Text("Urgence")
                }

                Section {
                    Toggle("Sauvegarde chiffrée", isOn: $encryptedBackups)
                    Toggle("Synchronisation iCloud Drive", isOn: $iCloudDriveSync)
                        .disabled(!encryptedBackups || !store.secureBackupStatus.isICloudDriveAvailable)

                    HStack(spacing: 10) {
                        Button {
                            backupMessage = store.writeSecureBackupNow()
                        } label: {
                            Label("Sauvegarder", systemImage: "lock.doc")
                        }

                        Button {
                            backupMessage = store.syncFromICloudDriveBackup()
                        } label: {
                            Label("Synchroniser", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .disabled(!iCloudDriveSync)
                    }

                    BackupStatusView(status: store.secureBackupStatus, message: backupMessage)
                } header: {
                    Text("Sauvegarde")
                }

                Section {
                    Button {
                        onShowOnboarding()
                    } label: {
                        Label("Revoir l’introduction", systemImage: "sparkles")
                    }

                    Button {
                        NSWorkspace.shared.open(store.dataFolderURL)
                    } label: {
                        Label("Ouvrir les données locales", systemImage: "folder")
                    }

                    Button(role: .destructive) {
                        showsResetConfirmation = true
                    } label: {
                        Label("Réinitialiser les exemples", systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Produit")
                }
            }
            .formStyle(.grouped)
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
        }
        .frame(width: 620, height: 520)
        .onChange(of: focusUrgenciesOnDesktop) { _ in
            desktopController.focusesUrgenciesOnly = focusUrgenciesOnDesktop
        }
        .onChange(of: adaptiveDesktop) { _ in
            desktopController.usesAdaptiveDesk = adaptiveDesktop
        }
        .onChange(of: autoCleanDesktop) { _ in
            if autoCleanDesktop {
                desktopController.cleanDesktop(in: store)
            }
        }
        .onChange(of: watchLeadHours) { _ in
            refreshUrgencyRules()
        }
        .onChange(of: pressingLeadHours) { _ in
            refreshUrgencyRules()
        }
        .onChange(of: criticalLeadMinutes) { _ in
            refreshUrgencyRules()
        }
        .onChange(of: encryptedBackups) { _ in
            if !encryptedBackups {
                iCloudDriveSync = false
            }
            backupMessage = store.writeSecureBackupNow()
        }
        .onChange(of: iCloudDriveSync) { _ in
            if iCloudDriveSync {
                encryptedBackups = true
                backupMessage = store.syncFromICloudDriveBackup()
            } else {
                backupMessage = store.writeSecureBackupNow()
            }
        }
        .confirmationDialog(
            "Réinitialiser les exemples ?",
            isPresented: $showsResetConfirmation
        ) {
            Button("Réinitialiser", role: .destructive) {
                store.resetToExamples()
                desktopController.cleanDesktop(in: store)
            }
            Button("Annuler", role: .cancel) {}
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            PunaiseLogo(size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("Préférences")
                    .font(.system(size: 22, weight: .semibold))
                Text("Punaise rend l’urgence visible.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(22)
    }

    private func refreshUrgencyRules() {
        if pressingLeadHours > watchLeadHours {
            watchLeadHours = pressingLeadHours
        }

        ReminderNotificationScheduler.refresh(reminders: store.reminders)

        if autoCleanDesktop {
            desktopController.cleanDesktop(in: store)
        }
    }
}

private struct BackupStatusView: View {
    let status: SecureBackupStatus
    let message: SecureBackupMessage?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(status.iCloudStatusTitle, systemImage: status.isICloudDriveAvailable ? "icloud" : "icloud.slash")
                .foregroundStyle(status.isICloudDriveAvailable ? Color.secondary : Color.orange)

            if let localModifiedAt = status.localModifiedAt {
                Text("Dernière sauvegarde locale : \(PunaiseDateFormatting.shortDateTime.string(from: localModifiedAt))")
            } else {
                Text("Aucune sauvegarde locale.")
            }

            if let iCloudModifiedAt = status.iCloudModifiedAt {
                Text("Dernière sauvegarde iCloud : \(PunaiseDateFormatting.shortDateTime.string(from: iCloudModifiedAt))")
            }

            if let message {
                Text("\(message.title) · \(message.detail)")
                    .foregroundStyle(.primary)
            }
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(.secondary)
    }
}

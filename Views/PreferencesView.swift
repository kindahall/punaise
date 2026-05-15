import AppKit
import SwiftUI

struct PreferencesView: View {
    @ObservedObject var store: ReminderStore
    @ObservedObject var desktopController: DesktopStickyController
    let onShowOnboarding: () -> Void
    let onRequestNotifications: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(PunaisePreferenceKey.appearance) private var appearance = PunaiseAppearancePreference.system.rawValue
    @AppStorage(PunaisePreferenceKey.focusUrgenciesOnDesktop) private var focusUrgenciesOnDesktop = false
    @AppStorage(PunaisePreferenceKey.adaptiveDesktop) private var adaptiveDesktop = true
    @AppStorage(PunaisePreferenceKey.autoCleanDesktop) private var autoCleanDesktop = false
    @AppStorage(PunaisePreferenceKey.watchLeadHours) private var watchLeadHours = 72.0
    @AppStorage(PunaisePreferenceKey.pressingLeadHours) private var pressingLeadHours = 24.0
    @AppStorage(PunaisePreferenceKey.criticalLeadMinutes) private var criticalLeadMinutes = 120.0
    @AppStorage(PunaisePreferenceKey.encryptedBackups) private var encryptedBackups = true
    @AppStorage(PunaisePreferenceKey.iCloudDriveSync) private var iCloudDriveSync = false
    @AppStorage(PunaisePreferenceKey.language) private var language = PunaiseLanguage.default.rawValue
    @AppStorage(PunaisePreferenceKey.licenseKey) private var licenseKey = ""
    @State private var showsResetConfirmation = false
    @State private var backupMessage: SecureBackupMessage?

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            Form {
                Section {
                    Picker("Langue", selection: $language) {
                        ForEach(PunaiseLanguage.allCases) { language in
                            Text(language.nativeTitle).tag(language.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Apparence", selection: $appearance) {
                        ForEach(PunaiseAppearancePreference.allCases) { mode in
                            Text(mode.title).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Interface")
                }

                Section {
                    LicenseInlineActivationView()
                } header: {
                    Text("Licence")
                }

                Section {
                    Toggle("Afficher seulement les urgences sur le bureau", isOn: $focusUrgenciesOnDesktop)
                        .disabled(!isPro)
                    Toggle("Bureau adaptatif", isOn: $adaptiveDesktop)
                        .disabled(!isPro)
                    Toggle("Bureau propre automatique", isOn: $autoCleanDesktop)
                        .disabled(!isPro)

                    Button {
                        guard isPro else {
                            PunaiseLicense.openPurchasePage()
                            return
                        }
                        desktopController.cleanDesktop(in: store)
                    } label: {
                        Label("Ranger maintenant", systemImage: "square.grid.2x2")
                    }

                    if !isPro {
                        ProLockCard(feature: .smartDesktop, compact: true) { _ in
                            PunaiseLicense.openPurchasePage()
                        }
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
                            .disabled(!isPro)
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
                            .disabled(!isPro)
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
                            .disabled(!isPro)
                    }

                    Button {
                        onRequestNotifications()
                    } label: {
                        Label("Autoriser les notifications", systemImage: "bell.badge")
                    }

                    if !isPro {
                        ProLockCard(feature: .advancedUrgency, compact: true) { _ in
                            PunaiseLicense.openPurchasePage()
                        }
                    }
                } header: {
                    Text("Urgence")
                }

                Section {
                    Toggle("Sauvegarde chiffrée", isOn: $encryptedBackups)
                        .disabled(!isPro)
                    Toggle("Synchronisation iCloud Drive", isOn: $iCloudDriveSync)
                        .disabled(!isPro || !encryptedBackups || !store.secureBackupStatus.isICloudDriveAvailable)

                    HStack(spacing: 10) {
                        Button {
                            guard isPro else {
                                PunaiseLicense.openPurchasePage()
                                return
                            }
                            backupMessage = store.writeSecureBackupNow()
                        } label: {
                            Label("Sauvegarder", systemImage: "lock.doc")
                        }

                        Button {
                            guard isPro else {
                                PunaiseLicense.openPurchasePage()
                                return
                            }
                            backupMessage = store.syncFromICloudDriveBackup()
                        } label: {
                            Label("Synchroniser", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .disabled(!isPro || !iCloudDriveSync)
                    }

                    BackupStatusView(status: store.secureBackupStatus, message: backupMessage)

                    if !isPro {
                        ProLockCard(feature: .backup, compact: true) { _ in
                            PunaiseLicense.openPurchasePage()
                        }
                    }
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
                        Label("Vider les Punaises", systemImage: "trash")
                    }
                } header: {
                    Text("Produit")
                }
            }
            .formStyle(.grouped)
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
        }
        .punaiseLocale(language)
        .punaisePreferredAppearance(appearance)
        .tint(PunaiseTheme(colorScheme: colorScheme).accent)
        .background(PunaiseTheme(colorScheme: colorScheme).windowBase)
        .frame(width: 620, height: 620)
        .onChange(of: focusUrgenciesOnDesktop) { _ in
            desktopController.focusesUrgenciesOnly = isPro && focusUrgenciesOnDesktop
        }
        .onChange(of: adaptiveDesktop) { _ in
            desktopController.usesAdaptiveDesk = isPro && adaptiveDesktop
        }
        .onChange(of: autoCleanDesktop) { _ in
            if isPro && autoCleanDesktop {
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
        .onChange(of: language) { _ in
            store.localizeGeneratedDefaultTitlesForCurrentLanguage()
            NotificationCenter.default.post(name: .punaiseLanguageDidChange, object: nil)
        }
        .onChange(of: encryptedBackups) { _ in
            guard isPro else { return }
            if !encryptedBackups {
                iCloudDriveSync = false
            }
            backupMessage = store.writeSecureBackupNow()
        }
        .onChange(of: iCloudDriveSync) { _ in
            guard isPro else { return }
            if iCloudDriveSync {
                encryptedBackups = true
                backupMessage = store.syncFromICloudDriveBackup()
            } else {
                backupMessage = store.writeSecureBackupNow()
            }
        }
        .confirmationDialog(
            "Vider toutes les Punaises ?",
            isPresented: $showsResetConfirmation
        ) {
            Button("Vider", role: .destructive) {
                store.resetToExamples()
                desktopController.cleanDesktop(in: store)
            }
            Button("Annuler", role: .cancel) {}
        }
    }

    private var isPro: Bool {
        PunaiseLicense.isValid(licenseKey)
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
        .foregroundStyle(PunaiseTheme(colorScheme: colorScheme).brand)
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
                Text("\(PunaiseL10n.string("Dernière sauvegarde locale")) : \(PunaiseDateFormatting.shortDateTime.string(from: localModifiedAt))")
            } else {
                Text(PunaiseL10n.string("Aucune sauvegarde locale."))
            }

            if let iCloudModifiedAt = status.iCloudModifiedAt {
                Text("\(PunaiseL10n.string("Dernière sauvegarde iCloud")) : \(PunaiseDateFormatting.shortDateTime.string(from: iCloudModifiedAt))")
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

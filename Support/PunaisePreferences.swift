import Foundation

enum PunaisePreferenceKey {
    static let hasCompletedOnboarding = "punaise.hasCompletedOnboarding"
    static let focusUrgenciesOnDesktop = "punaise.focusUrgenciesOnDesktop"
    static let adaptiveDesktop = "punaise.adaptiveDesktop"
    static let autoCleanDesktop = "punaise.autoCleanDesktop"
    static let watchLeadHours = "punaise.watchLeadHours"
    static let pressingLeadHours = "punaise.pressingLeadHours"
    static let criticalLeadMinutes = "punaise.criticalLeadMinutes"
    static let encryptedBackups = "punaise.encryptedBackups"
    static let iCloudDriveSync = "punaise.iCloudDriveSync"
    static let appearance = "punaise.appearance"
    static let language = "punaise.language"
    static let lastTemplate = "punaise.lastTemplate"
    static let licenseKey = "punaise.licenseKey"
}

enum PunaisePreferences {
    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            PunaisePreferenceKey.focusUrgenciesOnDesktop: false,
            PunaisePreferenceKey.adaptiveDesktop: true,
            PunaisePreferenceKey.autoCleanDesktop: false,
            PunaisePreferenceKey.watchLeadHours: 72.0,
            PunaisePreferenceKey.pressingLeadHours: 24.0,
            PunaisePreferenceKey.criticalLeadMinutes: 120.0,
            PunaisePreferenceKey.encryptedBackups: true,
            PunaisePreferenceKey.iCloudDriveSync: false,
            PunaisePreferenceKey.appearance: PunaiseAppearancePreference.system.rawValue,
            PunaisePreferenceKey.language: PunaiseLanguage.default.rawValue,
            PunaisePreferenceKey.lastTemplate: PunaiseTemplate.facture.rawValue,
            PunaisePreferenceKey.licenseKey: ""
        ])
    }

    static var watchLeadTime: TimeInterval {
        let hours = UserDefaults.standard.object(forKey: PunaisePreferenceKey.watchLeadHours) as? Double ?? 72
        return max(1, min(336, hours)) * 60 * 60
    }

    static var pressingLeadTime: TimeInterval {
        let hours = UserDefaults.standard.object(forKey: PunaisePreferenceKey.pressingLeadHours) as? Double ?? 24
        return max(1, min(168, hours)) * 60 * 60
    }

    static var criticalLeadTime: TimeInterval {
        let minutes = UserDefaults.standard.object(forKey: PunaisePreferenceKey.criticalLeadMinutes) as? Double ?? 120
        return max(5, min(240, minutes)) * 60
    }

    static var encryptedBackupsEnabled: Bool {
        PunaiseLicense.isPro && (UserDefaults.standard.object(forKey: PunaisePreferenceKey.encryptedBackups) as? Bool ?? true)
    }

    static var iCloudDriveSyncEnabled: Bool {
        PunaiseLicense.isPro && UserDefaults.standard.bool(forKey: PunaisePreferenceKey.iCloudDriveSync)
    }
}

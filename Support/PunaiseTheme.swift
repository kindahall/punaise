import SwiftUI

enum PunaiseAppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return PunaiseL10n.string("Système")
        case .light:
            return PunaiseL10n.string("Clair")
        case .dark:
            return PunaiseL10n.string("Sombre")
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    static func value(from rawValue: String) -> PunaiseAppearancePreference {
        PunaiseAppearancePreference(rawValue: rawValue) ?? .system
    }
}

struct PunaiseTheme {
    let colorScheme: ColorScheme

    var isDark: Bool {
        colorScheme == .dark
    }

    var brand: Color {
        isDark ? Color(red: 0.83, green: 0.91, blue: 1.0) : Color(red: 0.06, green: 0.18, blue: 0.33)
    }

    var accent: Color {
        isDark ? Color(red: 1.0, green: 0.62, blue: 0.26) : Color(red: 0.93, green: 0.35, blue: 0.07)
    }

    var windowBase: Color {
        isDark ? Color(red: 0.045, green: 0.052, blue: 0.062) : .white
    }

    var windowLift: Color {
        isDark ? Color(red: 0.080, green: 0.092, blue: 0.112) : .white
    }

    var sidebarBase: Color {
        isDark ? Color(red: 0.060, green: 0.070, blue: 0.086).opacity(0.96) : .white
    }

    var editorSurface: Color {
        isDark ? Color(red: 0.075, green: 0.083, blue: 0.100).opacity(0.92) : .white
    }

    var panelSurface: Color {
        isDark ? Color.white.opacity(0.055) : .white
    }

    var inputSurface: Color {
        isDark ? Color.white.opacity(0.070) : .white
    }

    var hoverSurface: Color {
        isDark ? Color.white.opacity(0.075) : Color.black.opacity(0.045)
    }

    var selectedSurface: Color {
        isDark ? Color(red: 0.25, green: 0.48, blue: 1.0).opacity(0.24) : Color(red: 0.08, green: 0.36, blue: 1.0).opacity(0.15)
    }

    var hairline: Color {
        isDark ? Color.white.opacity(0.105) : Color.black.opacity(0.095)
    }

    var strongHairline: Color {
        isDark ? Color.white.opacity(0.160) : Color.black.opacity(0.135)
    }

    var shadow: Color {
        isDark ? Color.black.opacity(0.48) : Color.black.opacity(0.085)
    }

    var mutedText: Color {
        isDark ? Color.white.opacity(0.64) : Color.black.opacity(0.54)
    }

    var urgencyRed: Color {
        isDark ? Color(red: 1.0, green: 0.30, blue: 0.27) : Color(red: 0.94, green: 0.10, blue: 0.09)
    }

    var urgencyOrange: Color {
        isDark ? Color(red: 1.0, green: 0.62, blue: 0.24) : Color(red: 0.93, green: 0.42, blue: 0.08)
    }

    var urgencyYellow: Color {
        isDark ? Color(red: 0.98, green: 0.77, blue: 0.25) : Color(red: 0.88, green: 0.62, blue: 0.12)
    }

    var calmGreen: Color {
        isDark ? Color(red: 0.38, green: 0.86, blue: 0.48) : Color(red: 0.37, green: 0.75, blue: 0.27)
    }

    var linkBlue: Color {
        isDark ? Color(red: 0.42, green: 0.69, blue: 1.0) : Color(red: 0.23, green: 0.55, blue: 0.86)
    }
}

extension View {
    func punaisePreferredAppearance(_ rawValue: String) -> some View {
        preferredColorScheme(PunaiseAppearancePreference.value(from: rawValue).preferredColorScheme)
    }
}

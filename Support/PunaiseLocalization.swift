import Foundation
import SwiftUI

enum PunaiseLanguage: String, CaseIterable, Identifiable {
    case french = "fr"
    case english = "en"

    static let `default` = PunaiseLanguage.french

    var id: String { rawValue }

    var locale: Locale {
        switch self {
        case .french:
            return Locale(identifier: "fr_FR")
        case .english:
            return Locale(identifier: "en_US")
        }
    }

    var nativeTitle: String {
        switch self {
        case .french:
            return "Français"
        case .english:
            return "English"
        }
    }

    var shortTitle: String {
        switch self {
        case .french:
            return "FR"
        case .english:
            return "EN"
        }
    }

    var next: PunaiseLanguage {
        switch self {
        case .french:
            return .english
        case .english:
            return .french
        }
    }

    static func value(from rawValue: String) -> PunaiseLanguage {
        PunaiseLanguage(rawValue: rawValue) ?? .default
    }

    static var current: PunaiseLanguage {
        value(from: UserDefaults.standard.string(forKey: PunaisePreferenceKey.language) ?? PunaiseLanguage.default.rawValue)
    }
}

enum PunaiseL10n {
    static func string(_ key: String) -> String {
        let language = PunaiseLanguage.current

        if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: key, table: nil)
        }

        return NSLocalizedString(key, comment: "")
    }
}

extension Notification.Name {
    static let punaiseLanguageDidChange = Notification.Name("punaiseLanguageDidChange")
}

extension View {
    func punaiseLocale(_ languageRawValue: String) -> some View {
        environment(\.locale, PunaiseLanguage.value(from: languageRawValue).locale)
    }
}

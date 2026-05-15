import AppKit
import CryptoKit
import Foundation

enum PunaiseProFeature: String, CaseIterable, Identifiable {
    case unlimitedPunaises
    case naturalCapture
    case smartDesktop
    case advancedUrgency
    case imports
    case templates
    case context
    case backup

    var id: String { rawValue }

    var title: String {
        switch self {
        case .unlimitedPunaises:
            return PunaiseL10n.string("Punaises illimitées")
        case .naturalCapture:
            return PunaiseL10n.string("Capture naturelle")
        case .smartDesktop:
            return PunaiseL10n.string("Bureau intelligent")
        case .advancedUrgency:
            return PunaiseL10n.string("Urgence avancée")
        case .imports:
            return PunaiseL10n.string("Imports calendrier")
        case .templates:
            return PunaiseL10n.string("Templates métier")
        case .context:
            return PunaiseL10n.string("Contexte lié")
        case .backup:
            return PunaiseL10n.string("Sauvegarde chiffrée")
        }
    }

    var detail: String {
        switch self {
        case .unlimitedPunaises:
            return PunaiseL10n.string("Crée autant de Punaises actives que nécessaire.")
        case .naturalCapture:
            return PunaiseL10n.string("Transforme une phrase en Punaise complète.")
        case .smartDesktop:
            return PunaiseL10n.string("Nettoyage, focus et rangement automatique du bureau.")
        case .advancedUrgency:
            return PunaiseL10n.string("Score, Anti-oubli, pression mentale et plan de secours.")
        case .imports:
            return PunaiseL10n.string("Google Agenda et Apple Reminders sont réservés à Pro.")
        case .templates:
            return PunaiseL10n.string("Facture, client, appel, livraison, contrat, projet et administratif.")
        case .context:
            return PunaiseL10n.string("Ajoute fichiers, apps, sites, dossiers et mails à une Punaise.")
        case .backup:
            return PunaiseL10n.string("Sauvegarde locale/iCloud chiffrée et synchronisation.")
        }
    }

    var systemImage: String {
        switch self {
        case .unlimitedPunaises:
            return "infinity"
        case .naturalCapture:
            return "bolt.circle"
        case .smartDesktop:
            return "square.grid.2x2"
        case .advancedUrgency:
            return "flame"
        case .imports:
            return "tray.and.arrow.down"
        case .templates:
            return "wand.and.stars"
        case .context:
            return "paperclip"
        case .backup:
            return "lock.doc"
        }
    }
}

enum PunaiseLicense {
    static let freeActiveLimit = 5
    private static let signedKeyPrefix = "PUNAISE1"
    private static let productIdentifier = "punaise_pro"
    private static let signingPublicKeyX963Base64 = "BA4fXDfJTMpzSZEW7JQFAk/DskqvKYMBxleuWnaIowq6q88uOf4PESFEBUtMTMgPfRj326NE7pq3OSNr3bI+5Hc="

    static func normalizedKey(_ key: String) -> String {
        key
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\t", with: "")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
    }

    static func isValid(_ key: String) -> Bool {
        let normalized = normalizedKey(key)
        return isValidSignedKey(normalized)
    }

    static var storedKey: String {
        UserDefaults.standard.string(forKey: PunaisePreferenceKey.licenseKey) ?? ""
    }

    static var isPro: Bool {
        isValid(storedKey)
    }

    static func purchaseURL(language: PunaiseLanguage = .current) -> URL {
        var components = URLComponents(string: "https://punaise.cloud/licence")!
        components.queryItems = [
            URLQueryItem(name: "plan", value: "annual"),
            URLQueryItem(name: "lang", value: language.rawValue)
        ]
        return components.url ?? URL(string: "https://punaise.cloud/licence?plan=annual")!
    }

    static func openPurchasePage() {
        NSWorkspace.shared.open(purchaseURL())
    }

    private static func isValidSignedKey(_ key: String, now: Date = Date()) -> Bool {
        let parts = key.split(separator: ".", omittingEmptySubsequences: false).map(String.init)

        guard parts.count == 3,
              parts[0] == signedKeyPrefix,
              let payloadData = data(fromBase64URL: parts[1]),
              let signatureData = data(fromBase64URL: parts[2]),
              let publicKeyData = Data(base64Encoded: signingPublicKeyX963Base64),
              let publicKey = try? P256.Signing.PublicKey(x963Representation: publicKeyData),
              let signature = try? P256.Signing.ECDSASignature(derRepresentation: signatureData),
              publicKey.isValidSignature(signature, for: payloadData),
              let payload = try? JSONDecoder().decode(SignedLicensePayload.self, from: payloadData),
              payload.v == 1,
              payload.product == productIdentifier,
              payload.plan == "monthly" || payload.plan == "annual" else {
            return false
        }

        if let expiresAt = payload.expiresAt,
           let expirationDate = parseLicenseDate(expiresAt),
           expirationDate < now {
            return false
        }

        if let expiresAt = payload.expiresAt,
           parseLicenseDate(expiresAt) == nil {
            return false
        }

        return true
    }

    private static func data(fromBase64URL value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let padding = base64.count % 4
        if padding > 0 {
            base64 += String(repeating: "=", count: 4 - padding)
        }

        return Data(base64Encoded: base64)
    }

    private static func parseLicenseDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: value) {
            return date
        }

        return ISO8601DateFormatter().date(from: value)
    }
}

private struct SignedLicensePayload: Decodable {
    let v: Int
    let product: String
    let plan: String
    let issuedAt: String?
    let expiresAt: String?
    let emailHash: String?
    let sessionId: String?
    let requestId: String?
}

extension Notification.Name {
    static let punaiseLicenseDidChange = Notification.Name("punaiseLicenseDidChange")
    static let punaiseShowLicense = Notification.Name("punaiseShowLicense")
}

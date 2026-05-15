import CryptoKit
import Foundation
import Security

enum SecureBackupService {
    private static let backupFileName = "punaises.punaisebackup"
    private static let keychainService = "app.punaise.secure-backup"
    private static let keychainAccount = "backup-key-v1"

    static func writeBackups(reminders: [Reminder], storageURL: URL) throws -> [URL] {
        var writtenURLs: [URL] = []

        guard PunaisePreferences.encryptedBackupsEnabled else {
            return writtenURLs
        }

        let localURL = localBackupURL(for: storageURL)
        try writeEncrypted(reminders: reminders, to: localURL)
        writtenURLs.append(localURL)

        if PunaisePreferences.iCloudDriveSyncEnabled, let cloudURL = iCloudDriveBackupURL() {
            try writeEncrypted(reminders: reminders, to: cloudURL)
            writtenURLs.append(cloudURL)
        }

        return writtenURLs
    }

    static func importCloudBackupIfNewerThanLocal(storageURL: URL) throws -> [Reminder]? {
        guard PunaisePreferences.iCloudDriveSyncEnabled,
              let cloudURL = iCloudDriveBackupURL(),
              FileManager.default.fileExists(atPath: cloudURL.path) else {
            return nil
        }

        let cloudDate = modificationDate(for: cloudURL) ?? .distantPast
        let localDate = modificationDate(for: storageURL) ?? .distantPast
        guard cloudDate > localDate else { return nil }

        return try readEncrypted(from: cloudURL)
    }

    static func backupStatus(storageURL: URL) -> SecureBackupStatus {
        let localURL = localBackupURL(for: storageURL)
        let cloudURL = iCloudDriveBackupURL()

        return SecureBackupStatus(
            localBackupURL: localURL,
            localModifiedAt: modificationDate(for: localURL),
            iCloudBackupURL: cloudURL,
            iCloudModifiedAt: cloudURL.flatMap(modificationDate(for:)),
            isICloudDriveAvailable: cloudURL != nil
        )
    }

    static func localBackupURL(for storageURL: URL) -> URL {
        storageURL
            .deletingLastPathComponent()
            .appendingPathComponent("Backups", isDirectory: true)
            .appendingPathComponent(backupFileName)
    }

    static func iCloudDriveBackupURL() -> URL? {
        let cloudDocuments = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs", isDirectory: true)

        guard FileManager.default.fileExists(atPath: cloudDocuments.path) else {
            return nil
        }

        return cloudDocuments
            .appendingPathComponent("Punaise", isDirectory: true)
            .appendingPathComponent(backupFileName)
    }

    private static func writeEncrypted(reminders: [Reminder], to url: URL) throws {
        let key = try backupKey()
        let envelope = SecureBackupEnvelope(createdAt: Date(), reminders: reminders)
        let data = try JSONEncoder.punaiseBackup.encode(envelope)
        let sealedBox = try AES.GCM.seal(data, using: key)

        guard let combined = sealedBox.combined else {
            throw SecureBackupError.unableToSealBackup
        }

        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try combined.write(to: url, options: [.atomic])
    }

    private static func readEncrypted(from url: URL) throws -> [Reminder] {
        let key = try backupKey()
        let data = try Data(contentsOf: url)
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let openedData = try AES.GCM.open(sealedBox, using: key)
        let envelope = try JSONDecoder.punaiseBackup.decode(SecureBackupEnvelope.self, from: openedData)
        return envelope.reminders
    }

    private static func backupKey() throws -> SymmetricKey {
        SymmetricKey(data: try loadOrCreateKeyData())
    }

    private static func loadOrCreateKeyData() throws -> Data {
        if let existing = try keyDataFromKeychain() {
            return existing
        }

        var bytes = [UInt8](repeating: 0, count: 32)
        let byteCount = bytes.count
        let status = bytes.withUnsafeMutableBytes { buffer in
            SecRandomCopyBytes(kSecRandomDefault, byteCount, buffer.baseAddress!)
        }
        guard status == errSecSuccess else {
            throw SecureBackupError.keyGenerationFailed(status)
        }

        let data = Data(bytes)
        try saveKeyDataToKeychain(data)
        return data
    }

    private static func keyDataFromKeychain() throws -> Data? {
        var query = baseKeychainQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw SecureBackupError.keychainReadFailed(status)
        }

        return result as? Data
    }

    private static func saveKeyDataToKeychain(_ data: Data) throws {
        var item = baseKeychainQuery()
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(item as CFDictionary, nil)
        if status == errSecDuplicateItem {
            return
        }

        guard status == errSecSuccess else {
            throw SecureBackupError.keychainWriteFailed(status)
        }
    }

    private static func baseKeychainQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecAttrSynchronizable as String: kCFBooleanTrue as Any
        ]
    }

    private static func modificationDate(for url: URL) -> Date? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? FileManager.default.attributesOfItem(atPath: url.path)[.modificationDate] as? Date
    }
}

struct SecureBackupStatus {
    var localBackupURL: URL
    var localModifiedAt: Date?
    var iCloudBackupURL: URL?
    var iCloudModifiedAt: Date?
    var isICloudDriveAvailable: Bool

    var iCloudStatusTitle: String {
        PunaiseL10n.string(isICloudDriveAvailable ? "iCloud Drive disponible" : "iCloud Drive indisponible")
    }
}

struct SecureBackupMessage {
    var title: String
    var detail: String
}

private struct SecureBackupEnvelope: Codable {
    var version = 1
    var createdAt: Date
    var reminders: [Reminder]
}

private enum SecureBackupError: LocalizedError {
    case unableToSealBackup
    case keyGenerationFailed(OSStatus)
    case keychainReadFailed(OSStatus)
    case keychainWriteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unableToSealBackup:
            return PunaiseL10n.string("Impossible de chiffrer la sauvegarde.")
        case .keyGenerationFailed:
            return PunaiseL10n.string("Impossible de générer la clé de sauvegarde.")
        case .keychainReadFailed:
            return PunaiseL10n.string("Impossible de lire la clé dans le trousseau.")
        case .keychainWriteFailed:
            return PunaiseL10n.string("Impossible d’enregistrer la clé dans le trousseau.")
        }
    }
}

private extension JSONEncoder {
    static var punaiseBackup: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var punaiseBackup: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

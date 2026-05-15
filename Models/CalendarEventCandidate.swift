import Foundation

struct CalendarEventCandidate: Identifiable, Equatable {
    let id: String
    let title: String
    let notes: String
    let calendarTitle: String
    let sourceTitle: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let location: String
    let url: URL?

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? PunaiseL10n.string("Événement sans titre") : trimmed
    }

    var deadline: Date {
        guard isAllDay else { return startDate }
        return Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: startDate) ?? startDate
    }

    var suggestedUrgency: Urgency {
        let text = "\(title) \(notes) \(location)".lowercased()
        let strongWords = Self.strongDeadlineWords

        if strongWords.contains(where: { text.contains($0) }) {
            return .urgent
        }

        let remaining = deadline.timeIntervalSince(Date())
        switch remaining {
        case ...0:
            return .urgent
        case 0...(24 * 60 * 60):
            return .urgent
        case ...(3 * 24 * 60 * 60):
            return .neutral
        default:
            return .relaxed
        }
    }

    var deadlineScore: Int {
        let text = "\(title) \(notes) \(location) \(calendarTitle)".lowercased()
        var score = 0

        for word in Self.strongDeadlineWords where text.contains(word) {
            score += 34
        }

        for word in Self.mediumDeadlineWords where text.contains(word) {
            score += 18
        }

        for word in Self.softDeadlineWords where text.contains(word) {
            score += 9
        }

        if isAllDay {
            score += 8
        }

        let remaining = deadline.timeIntervalSince(Date())
        if remaining <= 24 * 60 * 60 {
            score += 26
        } else if remaining <= 3 * 24 * 60 * 60 {
            score += 14
        } else if remaining <= 7 * 24 * 60 * 60 {
            score += 7
        }

        if Self.noiseWords.contains(where: { text.contains($0) }) {
            score -= 22
        }

        return max(0, min(100, score))
    }

    var isDeadlineLike: Bool {
        deadlineScore >= 32
    }

    var deadlineSignal: String {
        let text = "\(title) \(notes) \(location)".lowercased()

        if let strong = Self.strongDeadlineWords.first(where: { text.contains($0) }) {
            return strong.capitalized
        }

        if let medium = Self.mediumDeadlineWords.first(where: { text.contains($0) }) {
            return medium.capitalized
        }

        if deadline.timeIntervalSince(Date()) <= 24 * 60 * 60 {
            return PunaiseL10n.string("Bientôt")
        }

        return PunaiseL10n.string("Signal faible")
    }

    var shouldPinByDefault: Bool {
        isDeadlineLike && (deadline.timeIntervalSince(Date()) <= 3 * 24 * 60 * 60 || suggestedUrgency == .urgent)
    }

    var generatedNote: String {
        var lines: [String] = []

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty {
            lines.append(trimmedNotes)
        }

        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedLocation.isEmpty {
            lines.append("\(PunaiseL10n.string("Lieu")) : \(trimmedLocation)")
        }

        lines.append(PunaiseL10n.string("Importé depuis Google Agenda via Calendrier macOS."))
        return lines.joined(separator: "\n\n")
    }

    private static let strongDeadlineWords = [
        "contrat",
        "client",
        "facture",
        "livraison",
        "paiement",
        "signature",
        "urgent",
        "deadline",
        "échéance",
        "echeance",
        "rendu"
    ]

    private static let mediumDeadlineWords = [
        "appel",
        "réunion importante",
        "reunion importante",
        "devis",
        "relance",
        "validation",
        "valider",
        "envoyer",
        "administratif",
        "dossier",
        "projet"
    ]

    private static let softDeadlineWords = [
        "préparer",
        "preparer",
        "point",
        "livrer",
        "final",
        "à faire",
        "a faire"
    ]

    private static let noiseWords = [
        "anniversaire",
        "birthday",
        "vacances",
        "holiday",
        "sport",
        "déjeuner",
        "dejeuner",
        "dîner",
        "diner"
    ]
}

struct ReminderExternalSource: Codable, Equatable {
    var provider: ReminderExternalProvider
    var identifier: String
    var title: String
    var importedAt: Date
}

enum ReminderExternalProvider: String, Codable {
    case googleCalendar
    case appleReminders

    var title: String {
        switch self {
        case .googleCalendar:
            return PunaiseL10n.string("Google Agenda")
        case .appleReminders:
            return PunaiseL10n.string("Apple Reminders")
        }
    }

    var systemImage: String {
        switch self {
        case .googleCalendar:
            return "calendar"
        case .appleReminders:
            return "checklist"
        }
    }
}

import Foundation

struct ReminderCandidate: Identifiable, Equatable {
    let id: String
    let title: String
    let notes: String
    let listTitle: String
    let sourceTitle: String
    let deadline: Date
    let priority: Int
    let url: URL?

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Rappel sans titre" : trimmed
    }

    var suggestedUrgency: Urgency {
        if priority >= 1 && priority <= 4 {
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
            return priority >= 5 && priority <= 6 ? .neutral : .relaxed
        }
    }

    var deadlineScore: Int {
        let text = "\(title) \(notes) \(listTitle)".lowercased()
        var score = 0

        for word in Self.strongWords where text.contains(word) {
            score += 34
        }

        for word in Self.mediumWords where text.contains(word) {
            score += 18
        }

        for word in Self.softWords where text.contains(word) {
            score += 9
        }

        switch priority {
        case 1...4:
            score += 28
        case 5...6:
            score += 14
        case 7...9:
            score += 4
        default:
            break
        }

        let remaining = deadline.timeIntervalSince(Date())
        if remaining <= 0 {
            score += 34
        } else if remaining <= 24 * 60 * 60 {
            score += 24
        } else if remaining <= 3 * 24 * 60 * 60 {
            score += 14
        } else if remaining <= 7 * 24 * 60 * 60 {
            score += 8
        }

        if Self.noiseWords.contains(where: { text.contains($0) }) {
            score -= 18
        }

        return max(0, min(100, score))
    }

    var isDeadlineLike: Bool {
        deadlineScore >= 30
    }

    var shouldPinByDefault: Bool {
        isDeadlineLike && (suggestedUrgency == .urgent || deadline.timeIntervalSince(Date()) <= 3 * 24 * 60 * 60)
    }

    var deadlineSignal: String {
        if priority >= 1 && priority <= 4 {
            return "Priorité"
        }

        let text = "\(title) \(notes)".lowercased()

        if let strong = Self.strongWords.first(where: { text.contains($0) }) {
            return strong.capitalized
        }

        if deadline < Date() {
            return "En retard"
        }

        return "Échéance"
    }

    var generatedNote: String {
        var lines: [String] = []

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty {
            lines.append(trimmedNotes)
        }

        if priority > 0 {
            lines.append("Priorité Apple Reminders : \(priority).")
        }

        lines.append("Importé depuis Apple Reminders.")
        return lines.joined(separator: "\n\n")
    }

    private static let strongWords = [
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
        "rendu",
        "impôt",
        "impot"
    ]

    private static let mediumWords = [
        "appel",
        "devis",
        "relance",
        "validation",
        "valider",
        "envoyer",
        "administratif",
        "dossier",
        "projet",
        "mail",
        "répondre",
        "repondre"
    ]

    private static let softWords = [
        "préparer",
        "preparer",
        "point",
        "final",
        "à faire",
        "a faire"
    ]

    private static let noiseWords = [
        "courses",
        "liste",
        "idée",
        "idee",
        "film",
        "vacances"
    ]
}

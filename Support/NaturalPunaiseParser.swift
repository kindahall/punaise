import Foundation

struct NaturalPunaiseDraft {
    var title: String
    var note: String
    var deadline: Date
    var urgency: Urgency
    var template: PunaiseTemplate?
    var tags: [String]
    var attachments: [PunaiseAttachment]
}

enum NaturalPunaiseParser {
    static func parse(_ input: String, now: Date = Date()) -> NaturalPunaiseDraft? {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }

        let extracted = extractAttachments(from: cleaned)
        let command = extracted.text
        let lowercased = command.lowercased()
        let urgency = inferUrgency(from: lowercased)
        let template = inferTemplate(from: lowercased)
        let deadline = inferDeadline(from: lowercased, now: now)
        let title = cleanedTitle(from: command)

        var tags = template?.defaultTags ?? []
        if lowercased.contains("client") && !tags.contains("client") {
            tags.append("client")
        }
        if lowercased.contains("fournisseur") && !tags.contains("fournisseur") {
            tags.append("fournisseur")
        }

        return NaturalPunaiseDraft(
            title: title.isEmpty ? (template?.defaultTitle ?? "Nouvelle Punaise") : title,
            note: cleaned,
            deadline: deadline,
            urgency: urgency,
            template: template,
            tags: tags,
            attachments: extracted.attachments
        )
    }

    private static func extractAttachments(from input: String) -> (text: String, attachments: [PunaiseAttachment]) {
        var working = input
        var attachments: [PunaiseAttachment] = []

        let patterns: [(kind: AttachmentKind, pattern: String)] = [
            (.file, #"\b(?:fichier|file|pièce jointe|piece jointe)\s+("[^"]+"|'[^']+'|\S+)"#),
            (.folder, #"\b(?:dossier|folder)\s+("[^"]+"|'[^']+'|\S+)"#),
            (.app, #"\b(?:app|application)\s+("[^"]+"|'[^']+'|\S+)"#),
            (.website, #"\b(?:site|url|lien)\s+(\S+)"#),
            (.mail, #"\b(?:mail|email)\s+(\S+)"#)
        ]

        for item in patterns {
            guard let regex = try? NSRegularExpression(pattern: item.pattern, options: [.caseInsensitive]) else {
                continue
            }

            let range = NSRange(working.startIndex..<working.endIndex, in: working)
            let matches = regex.matches(in: working, options: [], range: range).reversed()

            for match in matches {
                guard match.numberOfRanges > 1,
                      let targetRange = Range(match.range(at: 1), in: working),
                      let fullRange = Range(match.range(at: 0), in: working) else {
                    continue
                }

                let target = cleanAttachmentTarget(String(working[targetRange]))
                guard !target.isEmpty else { continue }

                attachments.insert(
                    PunaiseAttachment(
                        title: attachmentTitle(for: target, kind: item.kind),
                        target: target,
                        kind: item.kind
                    ),
                    at: 0
                )

                working.removeSubrange(fullRange)
            }
        }

        working = working
            .replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: " -—,;").union(.whitespacesAndNewlines))

        return (working, attachments)
    }

    private static func inferUrgency(from text: String) -> Urgency {
        if text.contains("pas urgent") || text.contains("tranquille") || text.contains("quand possible") {
            return .relaxed
        }

        let urgentTerms = ["urgent", "critique", "vite", "important", "aujourd’hui", "aujourd'hui", "demain", "contrat", "facture", "livraison", "client"]
        if urgentTerms.contains(where: { text.contains($0) }) {
            return .urgent
        }

        return .neutral
    }

    private static func inferTemplate(from text: String) -> PunaiseTemplate? {
        if text.contains("facture") || text.contains("paiement") {
            return .facture
        }
        if text.contains("contrat") || text.contains("signature") {
            return .contrat
        }
        if text.contains("livraison") || text.contains("colis") {
            return .livraison
        }
        if text.contains("appel") || text.contains("appeler") || text.contains("téléphone") || text.contains("telephone") {
            return .appel
        }
        if text.contains("administratif") || text.contains("dossier") || text.contains("impôt") || text.contains("impot") {
            return .administratif
        }
        if text.contains("projet") || text.contains("rendu") {
            return .projet
        }
        if text.contains("client") {
            return .client
        }
        return nil
    }

    private static func inferDeadline(from text: String, now: Date) -> Date {
        let calendar = Calendar.current
        let baseDay: Date

        if text.contains("après-demain") || text.contains("apres-demain") {
            baseDay = calendar.date(byAdding: .day, value: 2, to: now) ?? now
        } else if text.contains("demain") {
            baseDay = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        } else if text.contains("aujourd’hui") || text.contains("aujourd'hui") {
            baseDay = now
        } else {
            baseDay = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        }

        if let relativeDate = relativeDate(from: text, now: now) {
            return relativeDate
        }

        let hourMinute = hourMinute(from: text) ?? (18, 0)
        return calendar.date(
            bySettingHour: hourMinute.hour,
            minute: hourMinute.minute,
            second: 0,
            of: baseDay
        ) ?? baseDay
    }

    private static func relativeDate(from text: String, now: Date) -> Date? {
        if let minutes = firstNumber(in: text, pattern: #"dans\s+(\d+)\s*(min|mn|minute|minutes)"#) {
            return Calendar.current.date(byAdding: .minute, value: minutes, to: now)
        }

        if let hours = firstNumber(in: text, pattern: #"dans\s+(\d+)\s*(h|heure|heures)"#) {
            return Calendar.current.date(byAdding: .hour, value: hours, to: now)
        }

        if let days = firstNumber(in: text, pattern: #"dans\s+(\d+)\s*(j|jour|jours)"#) {
            return Calendar.current.date(byAdding: .day, value: days, to: now)
        }

        return nil
    }

    private static func hourMinute(from text: String) -> (hour: Int, minute: Int)? {
        let patterns = [
            #"(\d{1,2})\s*h\s*(\d{2})?"#,
            #"(\d{1,2})\s*:\s*(\d{2})"#
        ]

        for pattern in patterns {
            guard let match = firstMatch(in: text, pattern: pattern) else { continue }
            let hour = Int(match[1]) ?? 18
            let minute = match.indices.contains(2) ? (Int(match[2]) ?? 0) : 0
            return (min(max(hour, 0), 23), min(max(minute, 0), 59))
        }

        return nil
    }

    private static func cleanedTitle(from input: String) -> String {
        var title = input
        let removals = [
            "urgent",
            "pas urgent",
            "neutre",
            "demain",
            "aujourd’hui",
            "aujourd'hui",
            "après-demain",
            "apres-demain"
        ]

        for removal in removals {
            title = title.replacingOccurrences(of: removal, with: "", options: [.caseInsensitive, .diacriticInsensitive])
        }

        title = title.replacingOccurrences(of: #"\bdans\s+\d+\s*(min|mn|minute|minutes|h|heure|heures|j|jour|jours)\b"#, with: "", options: .regularExpression)
        title = title.replacingOccurrences(of: #"\b\d{1,2}\s*(h|:)\s*\d{0,2}\b"#, with: "", options: .regularExpression)
        return title
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: CharacterSet(charactersIn: " -—,;").union(.whitespacesAndNewlines))
    }

    private static func cleanAttachmentTarget(_ target: String) -> String {
        target
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }

    private static func attachmentTitle(for target: String, kind: AttachmentKind) -> String {
        switch kind {
        case .file, .folder, .app:
            return URL(fileURLWithPath: target).lastPathComponent
        case .website:
            return target
                .replacingOccurrences(of: "https://", with: "")
                .replacingOccurrences(of: "http://", with: "")
        case .mail:
            return target
        }
    }

    private static func firstNumber(in text: String, pattern: String) -> Int? {
        guard let match = firstMatch(in: text, pattern: pattern), match.count > 1 else { return nil }
        return Int(match[1])
    }

    private static func firstMatch(in text: String, pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: nsRange) else { return nil }

        return (0..<match.numberOfRanges).map { index in
            let range = match.range(at: index)
            guard let swiftRange = Range(range, in: text) else { return "" }
            return String(text[swiftRange])
        }
    }
}

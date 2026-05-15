import Foundation

struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var note: String
    var deadline: Date
    var urgency: Urgency
    var isPinned: Bool
    var desktopPosition: DesktopPosition?
    var isArchived: Bool
    var project: String
    var tags: [String]
    var template: PunaiseTemplate?
    var attachment: PunaiseAttachment?
    var attachments: [PunaiseAttachment]
    var externalSource: ReminderExternalSource?
    var recurrence: RecurrenceRule
    var completedAt: Date?
    var lastOpenedAt: Date?
    var postponeCount: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        note: String,
        deadline: Date,
        urgency: Urgency,
        isPinned: Bool = false,
        desktopPosition: DesktopPosition? = nil,
        isArchived: Bool = false,
        project: String = "",
        tags: [String] = [],
        template: PunaiseTemplate? = nil,
        attachment: PunaiseAttachment? = nil,
        attachments: [PunaiseAttachment] = [],
        externalSource: ReminderExternalSource? = nil,
        recurrence: RecurrenceRule = .none,
        completedAt: Date? = nil,
        lastOpenedAt: Date? = nil,
        postponeCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.deadline = deadline
        self.urgency = urgency
        self.isPinned = isPinned
        self.desktopPosition = desktopPosition
        self.isArchived = isArchived
        self.project = project
        self.tags = tags
        self.template = template
        self.attachment = attachment
        self.attachments = attachments.isEmpty ? attachment.map { [$0] } ?? [] : attachments
        self.externalSource = externalSource
        self.recurrence = recurrence
        self.completedAt = completedAt
        self.lastOpenedAt = lastOpenedAt
        self.postponeCount = postponeCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case note
        case deadline
        case urgency
        case isPinned
        case desktopPosition
        case isArchived
        case project
        case tags
        case template
        case attachment
        case attachments
        case externalSource
        case recurrence
        case completedAt
        case lastOpenedAt
        case postponeCount
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
        deadline = try container.decodeIfPresent(Date.self, forKey: .deadline) ?? Date()
        urgency = try container.decodeIfPresent(Urgency.self, forKey: .urgency) ?? .neutral
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        desktopPosition = try container.decodeIfPresent(DesktopPosition.self, forKey: .desktopPosition)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        project = try container.decodeIfPresent(String.self, forKey: .project) ?? ""
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        template = try container.decodeIfPresent(PunaiseTemplate.self, forKey: .template)
        attachment = try container.decodeIfPresent(PunaiseAttachment.self, forKey: .attachment)
        let decodedAttachments = try container.decodeIfPresent([PunaiseAttachment].self, forKey: .attachments) ?? []
        attachments = decodedAttachments.isEmpty ? attachment.map { [$0] } ?? [] : decodedAttachments
        externalSource = try container.decodeIfPresent(ReminderExternalSource.self, forKey: .externalSource)
        recurrence = try container.decodeIfPresent(RecurrenceRule.self, forKey: .recurrence) ?? .none
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        lastOpenedAt = try container.decodeIfPresent(Date.self, forKey: .lastOpenedAt)
        postponeCount = try container.decodeIfPresent(Int.self, forKey: .postponeCount) ?? 0
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? PunaiseL10n.string("Sans titre") : trimmed
    }

    func status(at date: Date = Date()) -> ReminderStatus {
        if deadline < date {
            return .overdue
        }

        let secondsRemaining = deadline.timeIntervalSince(date)
        let pressingWindow = max(urgency.pressingWindow, PunaisePreferences.pressingLeadTime)
        let watchingWindow = max(pressingWindow, max(urgency.watchWindow, PunaisePreferences.watchLeadTime))

        if secondsRemaining <= PunaisePreferences.criticalLeadTime {
            return .critical
        }

        if secondsRemaining <= pressingWindow {
            return .pressing
        }

        if secondsRemaining <= watchingWindow {
            return .watching
        }

        return .calm
    }

    func pressureScore(at date: Date = Date()) -> Int {
        pressureBreakdown(at: date).total
    }

    func pressureBreakdown(at date: Date = Date()) -> PunaisePressureBreakdown {
        let currentStatus = status(at: date)
        let secondsRemaining = deadline.timeIntervalSince(date)
        let urgencyWindow = max(urgency.watchWindow, PunaisePreferences.watchLeadTime)
        let progress = max(0, min(1, 1 - (max(0, secondsRemaining) / urgencyWindow)))
        let proximity = secondsRemaining <= 0 ? 42 : Int((progress * 42).rounded())
        let lateness: Int

        if secondsRemaining < 0 {
            let hoursLate = abs(secondsRemaining) / 3600
            lateness = min(36, 18 + Int((hoursLate * 2.4).rounded()))
        } else {
            lateness = 0
        }

        let breakdown = PunaisePressureBreakdown(
            importance: urgency.basePressure,
            proximity: proximity,
            lateness: lateness,
            postponements: min(14, postponeCount * 4),
            context: contextualPressureBoost,
            ignored: antiForgetStage(at: date).scoreBoost,
            status: currentStatus
        )

        return breakdown
    }

    func antiForgetStage(at date: Date = Date()) -> AntiForgetStage {
        guard !isArchived else { return .quiet }

        let currentStatus = status(at: date)
        if currentStatus == .overdue {
            return .black
        }

        guard currentStatus.isUrgentNow else {
            return postponeCount >= 2 && currentStatus == .watching ? .halo : .quiet
        }

        guard isPinned else {
            return currentStatus == .critical ? .halo : .quiet
        }

        let lastAttentionDate = lastOpenedAt ?? createdAt
        let ignoredHours = max(0, date.timeIntervalSince(lastAttentionDate) / 3600)

        switch currentStatus {
        case .critical:
            if ignoredHours >= 3 || postponeCount >= 4 {
                return .front
            }

            if ignoredHours >= 0.75 || postponeCount >= 2 {
                return .vibrate
            }

            return .halo
        case .pressing:
            if ignoredHours >= 8 || postponeCount >= 3 {
                return .vibrate
            }

            if ignoredHours >= 2 || postponeCount >= 1 {
                return .halo
            }

            return .quiet
        case .calm, .watching, .overdue:
            return .quiet
        }
    }

    var projectLabel: String {
        let trimmed = project.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? PunaiseL10n.string("Sans projet") : trimmed
    }

    var tagLine: String {
        tags.isEmpty ? "" : tags.map { "#\($0)" }.joined(separator: " ")
    }

    private var contextualPressureBoost: Int {
        let text = "\(title) \(note) \(project) \(tags.joined(separator: " "))".lowercased()
        let strongWords = ["contrat", "client", "facture", "livraison", "fournisseur", "signature", "paiement", "juridique", "devis"]
        let mediumWords = ["appel", "réunion", "presentation", "présentation", "mail", "envoyer", "valider"]

        if strongWords.contains(where: { text.contains($0) }) {
            return 10
        }

        if mediumWords.contains(where: { text.contains($0) }) {
            return 5
        }

        return 0
    }

}

struct PunaisePressureBreakdown: Equatable {
    var importance: Int
    var proximity: Int
    var lateness: Int
    var postponements: Int
    var context: Int
    var ignored: Int
    var status: ReminderStatus

    var rawTotal: Int {
        importance + proximity + lateness + postponements + context + ignored
    }

    var total: Int {
        if status == .overdue {
            return min(100, max(86, rawTotal))
        }

        return min(99, rawTotal)
    }

    var factors: [PunaisePressureFactor] {
        [
            PunaisePressureFactor(id: "importance", title: PunaiseL10n.string("Importance"), value: importance, systemImage: "exclamationmark.circle"),
            PunaisePressureFactor(id: "proximity", title: PunaiseL10n.string("Proximité"), value: proximity, systemImage: "clock"),
            PunaisePressureFactor(id: "lateness", title: PunaiseL10n.string("Retard"), value: lateness, systemImage: "moon.zzz"),
            PunaisePressureFactor(id: "postponements", title: PunaiseL10n.string("Reports"), value: postponements, systemImage: "clock.arrow.circlepath"),
            PunaisePressureFactor(id: "context", title: PunaiseL10n.string("Contexte"), value: context, systemImage: "link"),
            PunaisePressureFactor(id: "ignored", title: PunaiseL10n.string("Anti-oubli"), value: ignored, systemImage: "bell.badge")
        ]
        .filter { $0.value > 0 }
    }
}

struct PunaisePressureFactor: Identifiable, Equatable {
    var id: String
    var title: String
    var value: Int
    var systemImage: String
}

enum AntiForgetStage: Int, Comparable {
    case quiet
    case halo
    case vibrate
    case front
    case black

    static func < (lhs: AntiForgetStage, rhs: AntiForgetStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .quiet:
            return PunaiseL10n.string("Stable")
        case .halo:
            return PunaiseL10n.string("Halo")
        case .vibrate:
            return PunaiseL10n.string("Insistant")
        case .front:
            return PunaiseL10n.string("Premier plan")
        case .black:
            return PunaiseL10n.string("Noire")
        }
    }

    var scoreBoost: Int {
        switch self {
        case .quiet:
            return 0
        case .halo:
            return 5
        case .vibrate:
            return 9
        case .front:
            return 14
        case .black:
            return 18
        }
    }

    var vibrationAmplitude: Double {
        switch self {
        case .quiet, .halo:
            return 0
        case .vibrate:
            return 2.2
        case .front:
            return 3.4
        case .black:
            return 0
        }
    }

    var haloMultiplier: Double {
        switch self {
        case .quiet:
            return 1
        case .halo:
            return 1.35
        case .vibrate:
            return 1.65
        case .front:
            return 2.0
        case .black:
            return 1.25
        }
    }

    var shouldReturnToFront: Bool {
        self == .front || self == .black
    }
}

enum Urgency: String, CaseIterable, Codable, Identifiable {
    case urgent
    case neutral
    case relaxed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .urgent:
            return PunaiseL10n.string("Urgent")
        case .neutral:
            return PunaiseL10n.string("Neutre")
        case .relaxed:
            return PunaiseL10n.string("Pas urgent")
        }
    }

    var systemImage: String {
        switch self {
        case .urgent:
            return "exclamationmark.circle.fill"
        case .neutral:
            return "minus.circle"
        case .relaxed:
            return "arrow.down.circle"
        }
    }

    var nextQuickState: Urgency {
        switch self {
        case .relaxed:
            return .neutral
        case .neutral:
            return .urgent
        case .urgent:
            return .relaxed
        }
    }

    var watchWindow: TimeInterval {
        switch self {
        case .urgent:
            return 72 * 60 * 60
        case .neutral:
            return 24 * 60 * 60
        case .relaxed:
            return 12 * 60 * 60
        }
    }

    var pressingWindow: TimeInterval {
        switch self {
        case .urgent:
            return 24 * 60 * 60
        case .neutral:
            return 8 * 60 * 60
        case .relaxed:
            return 2 * 60 * 60
        }
    }

    var criticalWindow: TimeInterval {
        switch self {
        case .urgent:
            return 2 * 60 * 60
        case .neutral:
            return 60 * 60
        case .relaxed:
            return 30 * 60
        }
    }

    var basePressure: Int {
        switch self {
        case .urgent:
            return 45
        case .neutral:
            return 28
        case .relaxed:
            return 14
        }
    }
}

enum ReminderStatus: Equatable, CaseIterable {
    case calm
    case watching
    case pressing
    case critical
    case overdue

    var title: String {
        switch self {
        case .calm:
            return PunaiseL10n.string("Calme")
        case .watching:
            return PunaiseL10n.string("À surveiller")
        case .pressing:
            return PunaiseL10n.string("Pressant")
        case .critical:
            return PunaiseL10n.string("Critique")
        case .overdue:
            return PunaiseL10n.string("Punaise noire")
        }
    }

    var scoreBoost: Int {
        switch self {
        case .calm:
            return 0
        case .watching:
            return 6
        case .pressing:
            return 16
        case .critical:
            return 30
        case .overdue:
            return 100
        }
    }

    var isUrgentNow: Bool {
        switch self {
        case .pressing, .critical, .overdue:
            return true
        case .calm, .watching:
            return false
        }
    }
}

struct DesktopPosition: Codable, Equatable {
    var x: Double
    var y: Double
}

enum RecurrenceRule: String, CaseIterable, Codable, Identifiable {
    case none
    case daily
    case weekly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            return PunaiseL10n.string("Une fois")
        case .daily:
            return PunaiseL10n.string("Chaque jour")
        case .weekly:
            return PunaiseL10n.string("Chaque semaine")
        case .monthly:
            return PunaiseL10n.string("Chaque mois")
        }
    }

    func nextDate(after date: Date) -> Date? {
        switch self {
        case .none:
            return nil
        case .daily:
            return Calendar.current.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: date)
        case .monthly:
            return Calendar.current.date(byAdding: .month, value: 1, to: date)
        }
    }
}

enum PunaiseTemplate: String, CaseIterable, Codable, Identifiable {
    case facture
    case client
    case appel
    case livraison
    case contrat
    case projet
    case administratif

    var id: String { rawValue }

    var title: String {
        switch self {
        case .facture:
            return PunaiseL10n.string("Facture")
        case .client:
            return PunaiseL10n.string("Client")
        case .appel:
            return PunaiseL10n.string("Appel")
        case .livraison:
            return PunaiseL10n.string("Livraison")
        case .contrat:
            return PunaiseL10n.string("Contrat")
        case .projet:
            return PunaiseL10n.string("Projet")
        case .administratif:
            return PunaiseL10n.string("Administratif")
        }
    }

    var systemImage: String {
        switch self {
        case .facture:
            return "doc.text"
        case .client:
            return "person.crop.circle.badge.exclamationmark"
        case .appel:
            return "phone"
        case .livraison:
            return "shippingbox"
        case .contrat:
            return "signature"
        case .projet:
            return "folder"
        case .administratif:
            return "tray.full"
        }
    }

    var defaultTitle: String {
        switch self {
        case .facture:
            return PunaiseL10n.string("Payer facture")
        case .client:
            return PunaiseL10n.string("Relancer client")
        case .appel:
            return PunaiseL10n.string("Appeler")
        case .livraison:
            return PunaiseL10n.string("Confirmer livraison")
        case .contrat:
            return PunaiseL10n.string("Envoyer contrat")
        case .projet:
            return PunaiseL10n.string("Avancer projet")
        case .administratif:
            return PunaiseL10n.string("Traiter administratif")
        }
    }

    var defaultNote: String {
        switch self {
        case .facture:
            return PunaiseL10n.string("Vérifier le montant, valider le paiement et terminer la Punaise.")
        case .client:
            return PunaiseL10n.string("Faire le point et obtenir une réponse avant l’échéance.")
        case .appel:
            return PunaiseL10n.string("Préparer le sujet, appeler, puis noter la suite.")
        case .livraison:
            return PunaiseL10n.string("Confirmer le créneau, le contact et le statut de livraison.")
        case .contrat:
            return PunaiseL10n.string("Relire, signer ou envoyer la version finale.")
        case .projet:
            return PunaiseL10n.string("Identifier la prochaine action, ouvrir le dossier lié et avancer sans perdre le contexte.")
        case .administratif:
            return PunaiseL10n.string("Rassembler les pièces, vérifier la date limite et terminer le dossier.")
        }
    }

    var defaultUrgency: Urgency {
        switch self {
        case .facture, .contrat, .livraison, .administratif:
            return .urgent
        case .client, .projet:
            return .neutral
        case .appel:
            return .neutral
        }
    }

    var defaultTags: [String] {
        [rawValue]
    }
}

struct PunaiseAttachment: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var target: String
    var kind: AttachmentKind

    init(
        id: UUID = UUID(),
        title: String,
        target: String,
        kind: AttachmentKind
    ) {
        self.id = id
        self.title = title
        self.target = target
        self.kind = kind
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case target
        case kind
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        target = try container.decodeIfPresent(String.self, forKey: .target) ?? ""
        kind = try container.decodeIfPresent(AttachmentKind.self, forKey: .kind) ?? .website
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? target : trimmed
    }
}

enum AttachmentKind: String, CaseIterable, Codable, Identifiable {
    case app
    case file
    case folder
    case website
    case mail

    var id: String { rawValue }

    var title: String {
        switch self {
        case .app:
            return PunaiseL10n.string("App")
        case .file:
            return PunaiseL10n.string("Fichier")
        case .folder:
            return PunaiseL10n.string("Dossier")
        case .website:
            return PunaiseL10n.string("Site")
        case .mail:
            return PunaiseL10n.string("Mail")
        }
    }

    var systemImage: String {
        switch self {
        case .app:
            return "app"
        case .file:
            return "doc"
        case .folder:
            return "folder"
        case .website:
            return "globe"
        case .mail:
            return "envelope"
        }
    }
}

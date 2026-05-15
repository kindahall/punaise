import Foundation

enum ReminderFilter: String, CaseIterable, Identifiable {
    case all
    case pinned
    case urgentNow
    case history

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .all:
            return "Tableau"
        case .pinned:
            return "Punaisées"
        case .urgentNow:
            return "Urgences"
        case .history:
            return "Historique"
        }
    }

    var title: String {
        PunaiseL10n.string(titleKey)
    }

    func matches(_ reminder: Reminder, now: Date) -> Bool {
        switch self {
        case .all:
            return !reminder.isArchived
        case .pinned:
            return reminder.isPinned && !reminder.isArchived
        case .urgentNow:
            return reminder.status(at: now).isUrgentNow && !reminder.isArchived
        case .history:
            return reminder.isArchived
        }
    }
}

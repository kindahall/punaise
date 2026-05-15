import Foundation

enum PunaiseDateFormatting {
    static var shortDateTime: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = PunaiseLanguage.current.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }

    static var compactDateTime: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = PunaiseLanguage.current.locale
        formatter.dateFormat = PunaiseLanguage.current == .english ? "MMM d — h:mm a" : "d MMM — HH:mm"
        return formatter
    }

    static var weekdayShort: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = PunaiseLanguage.current.locale
        formatter.dateFormat = "EEE d"
        return formatter
    }

    static var monthYear: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = PunaiseLanguage.current.locale
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }

    static var dayNumber: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = PunaiseLanguage.current.locale
        formatter.dateFormat = "d"
        return formatter
    }

    static var timeOnly: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = PunaiseLanguage.current.locale
        formatter.dateFormat = PunaiseLanguage.current == .english ? "h:mm a" : "HH:mm"
        return formatter
    }

    static func relativeDeadline(_ date: Date, now: Date) -> String {
        let calendar = Calendar.current
        let time = timeOnly.string(from: date)

        if calendar.isDateInToday(date) {
            return "\(PunaiseL10n.string("Aujourd’hui")) — \(time)"
        }

        if calendar.isDateInTomorrow(date) {
            return "\(PunaiseL10n.string("Demain")) — \(time)"
        }

        if calendar.isDateInYesterday(date) {
            return "\(PunaiseL10n.string("Hier")) — \(time)"
        }

        return compactDateTime.string(from: date)
    }

}

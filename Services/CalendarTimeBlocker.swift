import EventKit
import Foundation

enum CalendarTimeBlocker {
    static func blockThirtyMinutes(for reminder: Reminder, completion: @escaping (Result<Void, Error>) -> Void) {
        let store = EKEventStore()

        let createEvent = {
            let now = Date()
            let event = EKEvent(eventStore: store)
            event.title = "\(PunaiseL10n.string("Punaise")) : \(reminder.displayTitle)"
            event.notes = reminder.note
            event.startDate = now
            event.endDate = Calendar.current.date(byAdding: .minute, value: 30, to: now) ?? now.addingTimeInterval(1800)
            event.calendar = store.defaultCalendarForNewEvents

            do {
                try store.save(event, span: .thisEvent)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }

        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { granted, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard granted else {
                    completion(.failure(CalendarTimeBlockerError.accessDenied))
                    return
                }

                createEvent()
            }
        } else {
            store.requestAccess(to: .event) { granted, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard granted else {
                    completion(.failure(CalendarTimeBlockerError.accessDenied))
                    return
                }

                createEvent()
            }
        }
    }
}

private enum CalendarTimeBlockerError: LocalizedError {
    case accessDenied

    var errorDescription: String? {
        PunaiseL10n.string("Accès calendrier refusé.")
    }
}

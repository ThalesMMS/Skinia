import Foundation

enum ReminderFrequency: String, CaseIterable {
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"

    var title: String {
        switch self {
        case .weekly: return "Semanal"
        case .monthly: return "Mensal"
        case .quarterly: return "Trimestral"
        }
    }

    var description: String {
        switch self {
        case .weekly: return "A cada 7 dias"
        case .monthly: return "A cada 30 dias"
        case .quarterly: return "A cada 3 meses"
        }
    }

    var timeInterval: TimeInterval {
        switch self {
        case .weekly:
            return 7 * 24 * 60 * 60
        case .monthly:
            return 30 * 24 * 60 * 60
        case .quarterly:
            return 90 * 24 * 60 * 60
        }
    }
}

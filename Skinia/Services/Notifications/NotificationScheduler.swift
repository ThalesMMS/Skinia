import Foundation
import UserNotifications

protocol UserNotificationCenterProtocol {
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
    func removeAllPendingNotificationRequests()
    func removeAllDeliveredNotifications()
}

extension UNUserNotificationCenter: UserNotificationCenterProtocol {
    func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.add(request) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

protocol NotificationSchedulerProtocol {
    func updateAnalysisResultNotifications(isEnabled: Bool) async
    func updateUrgentResultNotifications(isEnabled: Bool) async
    func updateReminderNotifications(isEnabled: Bool, frequency: ReminderFrequency) async
    func cancelAllNotifications() async
}

final class NotificationScheduler: NotificationSchedulerProtocol {
    private enum Identifiers {
        static let analysisResult = "com.skinia.notifications.analysis-result"
        static let urgentResult = "com.skinia.notifications.urgent-result"
        static let reminder = "com.skinia.notifications.reminder"
    }

    private let notificationCenter: UserNotificationCenterProtocol

    init(notificationCenter: UserNotificationCenterProtocol = UNUserNotificationCenter.current()) {
        self.notificationCenter = notificationCenter
    }

    func updateAnalysisResultNotifications(isEnabled: Bool) async {
        cancelNotifications(with: [Identifiers.analysisResult])

        guard isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Análise concluída"
        content.body = "Avisaremos sempre que um novo resultado estiver disponível."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5 * 60, repeats: false)
        let request = UNNotificationRequest(
            identifier: Identifiers.analysisResult,
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    func updateUrgentResultNotifications(isEnabled: Bool) async {
        cancelNotifications(with: [Identifiers.urgentResult])

        guard isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Alerta de resultado urgente"
        content.body = "Você receberá avisos imediatos quando detectarmos possíveis sinais de risco."
        if #available(iOS 15.0, *) {
            content.sound = .defaultCritical
        } else {
            content.sound = .default
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10 * 60, repeats: false)
        let request = UNNotificationRequest(
            identifier: Identifiers.urgentResult,
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    func updateReminderNotifications(isEnabled: Bool, frequency: ReminderFrequency) async {
        cancelNotifications(with: [Identifiers.reminder])

        guard isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Hora de monitorar sua pele"
        content.body = "Crie novas análises periódicas para acompanhar possíveis alterações."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(frequency.timeInterval, 60), repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifiers.reminder,
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }

    private func cancelNotifications(with identifiers: [String]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}

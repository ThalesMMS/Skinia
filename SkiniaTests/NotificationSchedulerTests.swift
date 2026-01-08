import XCTest
@testable import Skinia
import UserNotifications

final class NotificationSchedulerTests: XCTestCase {
    func testEnablingAnalysisNotificationsSchedulesRequest() async {
        let center = FakeNotificationCenter()
        let scheduler = NotificationScheduler(notificationCenter: center)

        await scheduler.updateAnalysisResultNotifications(isEnabled: true)

        XCTAssertEqual(center.addedRequests.count, 1)
        XCTAssertEqual(center.addedRequests.first?.identifier, "com.skinia.notifications.analysis-result")
    }

    func testDisablingAnalysisNotificationsClearsRequests() async {
        let center = FakeNotificationCenter()
        let scheduler = NotificationScheduler(notificationCenter: center)

        await scheduler.updateAnalysisResultNotifications(isEnabled: false)

        XCTAssertEqual(center.removedPendingIdentifiers, [["com.skinia.notifications.analysis-result"]])
    }

    func testEnablingReminderSchedulesRepeatingTrigger() async {
        let center = FakeNotificationCenter()
        let scheduler = NotificationScheduler(notificationCenter: center)

        await scheduler.updateReminderNotifications(isEnabled: true, frequency: .weekly)

        let trigger = center.addedRequests.first?.trigger as? UNTimeIntervalNotificationTrigger
        XCTAssertNotNil(trigger)
        XCTAssertTrue(trigger?.repeats ?? false)
        XCTAssertEqual(trigger?.timeInterval, max(ReminderFrequency.weekly.timeInterval, 60))
    }

    func testDisablingReminderRemovesRequests() async {
        let center = FakeNotificationCenter()
        let scheduler = NotificationScheduler(notificationCenter: center)

        await scheduler.updateReminderNotifications(isEnabled: false, frequency: .monthly)

        XCTAssertEqual(center.removedPendingIdentifiers, [["com.skinia.notifications.reminder"]])
    }

    func testCancelAllNotificationsClearsPendingAndDelivered() async {
        let center = FakeNotificationCenter()
        let scheduler = NotificationScheduler(notificationCenter: center)

        await scheduler.cancelAllNotifications()

        XCTAssertTrue(center.didRemoveAllPending)
        XCTAssertTrue(center.didRemoveAllDelivered)
    }
}

private final class FakeNotificationCenter: UserNotificationCenterProtocol {
    private(set) var addedRequests: [UNNotificationRequest] = []
    private(set) var removedPendingIdentifiers: [[String]] = []
    private(set) var removedDeliveredIdentifiers: [[String]] = []
    private(set) var didRemoveAllPending = false
    private(set) var didRemoveAllDelivered = false

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedPendingIdentifiers.append(identifiers)
    }

    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        removedDeliveredIdentifiers.append(identifiers)
    }

    func removeAllPendingNotificationRequests() {
        didRemoveAllPending = true
    }

    func removeAllDeliveredNotifications() {
        didRemoveAllDelivered = true
    }
}

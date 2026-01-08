//
//  SkiniaTests.swift
//  SkiniaTests
//
//  Created by Thales Matheus Mendonça Santos on 04/09/25.
//

import Testing
@testable import Skinia

struct SkiniaTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @MainActor
    @Test func notificationsAutomaticallyDismissAfterDuration() async throws {
        let notificationManager = NotificationManager()
        let notification = StatusNotification(title: "Teste", type: .info, duration: 0.1)

        notificationManager.show(notification)

        #expect(notificationManager.notifications.count == 1)

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(notificationManager.notifications.isEmpty)
    }

}

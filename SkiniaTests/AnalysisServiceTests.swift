import Foundation
import Testing
@testable import Skinia

@MainActor
struct AnalysisServiceTests {

    @Test func startAnalysisCompletesSuccessfully() async throws {
        let repository = InMemoryPhotoRepository()
        let networkService = MockNetworkService()
        let notificationManager = NotificationManager()
        let analysisService = AnalysisService(
            networkService: networkService,
            photoRepository: repository,
            notificationManager: notificationManager
        )

        let photo = SkinLesionPhoto(imageData: Data([0x00, 0x01, 0x02]), analysisStatus: .pending)
        photo.metadata = PhotoMetadata()
        try repository.save(photo)

        let analysisId = UUID().uuidString
        let initialStatus = RemoteAnalysisStatus(
            analysisId: analysisId,
            status: .uploading,
            stage: .uploading,
            overallProgress: 0.1,
            stageProgress: 0.1,
            estimatedTimeRemaining: 10,
            errorMessage: nil,
            suggestedRetryInterval: 0.2
        )

        networkService.submissionResponse = NetworkAnalysisSubmission(
            analysisId: analysisId,
            estimatedTime: 12,
            initialStatus: initialStatus
        )

        networkService.statusResponses[analysisId] = [
            RemoteAnalysisStatus(
                analysisId: analysisId,
                status: .analyzing,
                stage: .analyzing,
                overallProgress: 0.45,
                stageProgress: 0.45,
                estimatedTimeRemaining: 6,
                errorMessage: nil,
                suggestedRetryInterval: 0.1
            ),
            RemoteAnalysisStatus(
                analysisId: analysisId,
                status: .completed,
                stage: .completed,
                overallProgress: 1.0,
                stageProgress: 1.0,
                estimatedTimeRemaining: 0,
                errorMessage: nil,
                suggestedRetryInterval: 0.1
            )
        ]

        networkService.results[analysisId] = AnalysisResult(
            confidence: 0.87,
            lesionType: "Lesão Benigna",
            riskLevel: .low,
            recommendations: ["Acompanhar"]
        )

        try await analysisService.startAnalysis(for: photo)

        #expect(photo.analysisStatus == .completed)
        #expect(photo.analysisResult?.lesionType == "Lesão Benigna")
        #expect(analysisService.getAnalysisProgress(for: photo.id) == nil)
        #expect(notificationManager.notifications.contains { $0.type == .success })
    }

    @Test func startAnalysisHandlesFailure() async throws {
        let repository = InMemoryPhotoRepository()
        let networkService = MockNetworkService()
        let notificationManager = NotificationManager()
        let analysisService = AnalysisService(
            networkService: networkService,
            photoRepository: repository,
            notificationManager: notificationManager
        )

        let photo = SkinLesionPhoto(imageData: Data([0x00, 0x01]), analysisStatus: .pending)
        photo.metadata = PhotoMetadata()
        try repository.save(photo)

        let analysisId = UUID().uuidString
        let initialStatus = RemoteAnalysisStatus(
            analysisId: analysisId,
            status: .uploading,
            stage: .uploading,
            overallProgress: 0.2,
            stageProgress: 0.2,
            estimatedTimeRemaining: 8,
            errorMessage: nil,
            suggestedRetryInterval: 0.1
        )

        networkService.submissionResponse = NetworkAnalysisSubmission(
            analysisId: analysisId,
            estimatedTime: 9,
            initialStatus: initialStatus
        )

        networkService.statusResponses[analysisId] = [
            RemoteAnalysisStatus(
                analysisId: analysisId,
                status: .failed,
                stage: .failed,
                overallProgress: 0.4,
                stageProgress: 0.0,
                estimatedTimeRemaining: nil,
                errorMessage: "Imagem inválida",
                suggestedRetryInterval: 0.1
            )
        ]

        try await analysisService.startAnalysis(for: photo)

        #expect(photo.analysisStatus == .failed)
        #expect(photo.analysisResult == nil)
        #expect(notificationManager.notifications.contains { $0.type == .error })
    }

    @Test func cancelAnalysisStopsProcessing() async throws {
        let repository = InMemoryPhotoRepository()
        let networkService = MockNetworkService()
        let notificationManager = NotificationManager()
        let analysisService = AnalysisService(
            networkService: networkService,
            photoRepository: repository,
            notificationManager: notificationManager
        )

        let photo = SkinLesionPhoto(imageData: Data([0xFF, 0xFF]), analysisStatus: .pending)
        photo.metadata = PhotoMetadata()
        try repository.save(photo)

        let analysisId = UUID().uuidString
        let initialStatus = RemoteAnalysisStatus(
            analysisId: analysisId,
            status: .uploading,
            stage: .uploading,
            overallProgress: 0.05,
            stageProgress: 0.05,
            estimatedTimeRemaining: 15,
            errorMessage: nil,
            suggestedRetryInterval: 1.0
        )

        networkService.submissionResponse = NetworkAnalysisSubmission(
            analysisId: analysisId,
            estimatedTime: 15,
            initialStatus: initialStatus
        )

        networkService.statusResponses[analysisId] = [
            RemoteAnalysisStatus(
                analysisId: analysisId,
                status: .analyzing,
                stage: .analyzing,
                overallProgress: 0.2,
                stageProgress: 0.2,
                estimatedTimeRemaining: 10,
                errorMessage: nil,
                suggestedRetryInterval: 1.0
            )
        ]

        let startTask = Task {
            try await analysisService.startAnalysis(for: photo)
        }

        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s to ensure submission

        await analysisService.cancelAnalysis(for: photo.id)
        try await startTask.value

        #expect(photo.analysisStatus == .pending)
        #expect(networkService.cancelledIds.contains(analysisId))
        #expect(notificationManager.notifications.contains { $0.type == .warning })
    }
}

// MARK: - Test Doubles

@MainActor
final class InMemoryPhotoRepository: PhotoRepositoryProtocol {
    private var storage: [UUID: SkinLesionPhoto] = [:]

    func save(_ photo: SkinLesionPhoto) throws {
        storage[photo.id] = photo
    }

    func fetch(with id: UUID) throws -> SkinLesionPhoto? {
        storage[id]
    }

    func fetchAll() throws -> [SkinLesionPhoto] {
        storage.values.filter { !$0.isDeleted }
    }

    func fetchPending() throws -> [SkinLesionPhoto] {
        try fetchByStatus(.pending)
    }

    func fetchCompleted() throws -> [SkinLesionPhoto] {
        try fetchByStatus(.completed)
    }

    func fetchByStatus(_ status: AnalysisStatus) throws -> [SkinLesionPhoto] {
        storage.values.filter { $0.analysisStatus == status && !$0.isDeleted }
    }

    func update(_ photo: SkinLesionPhoto) throws {
        photo.lastUpdated = Date()
        storage[photo.id] = photo
    }

    func delete(_ photo: SkinLesionPhoto) throws {
        photo.markAsDeleted()
        storage[photo.id] = photo
    }

    func deleteAll() throws {
        for photo in storage.values {
            photo.markAsDeleted()
        }
    }

    func count() throws -> Int {
        storage.values.filter { !$0.isDeleted }.count
    }
}

final class MockNetworkService: NetworkServiceProtocol {
    var submissionResponse: NetworkAnalysisSubmission?
    var statusResponses: [String: [RemoteAnalysisStatus]] = [:]
    var results: [String: AnalysisResult] = [:]
    private(set) var cancelledIds: [String] = []

    func submitAnalysis(imageData: Data, metadata: PhotoMetadata?) async throws -> NetworkAnalysisSubmission {
        guard let response = submissionResponse else {
            fatalError("MockNetworkService requires a predefined submissionResponse")
        }
        return response
    }

    func fetchAnalysisStatus(for analysisId: String) async throws -> RemoteAnalysisStatus {
        guard var responses = statusResponses[analysisId], !responses.isEmpty else {
            if let last = statusResponses[analysisId]?.last {
                return last
            }
            fatalError("No status responses configured for id \(analysisId)")
        }

        let next = responses.removeFirst()
        statusResponses[analysisId] = responses
        return next
    }

    func fetchAnalysisResult(for analysisId: String) async throws -> AnalysisResult {
        guard let result = results[analysisId] else {
            throw RemoteAnalysisNetworkError.missingResult
        }
        return result
    }

    func cancelAnalysis(for analysisId: String) async throws {
        cancelledIds.append(analysisId)
    }
}

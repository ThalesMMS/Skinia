import Foundation
import SwiftData
import Testing
@testable import Skinia

@MainActor
struct CameraServiceTests {

    private func createInMemoryContainer() -> ModelContainer {
        let schema = Schema([
            SkinLesionPhoto.self,
            AnalysisResult.self,
            PhotoMetadata.self,
            Exam.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create in-memory container: \(error)")
        }
    }

    @Test
    func savesPhotosIntoSharedExamForSamePatient() async throws {
        let container = createInMemoryContainer()
        let photoRepository = PhotoRepository(modelContainer: container)
        let examRepository = ExamRepository(modelContainer: container)
        let analysisService = MockAnalysisService()
        let notificationManager = NotificationManager()
        let cameraService = CameraService(
            photoRepository: photoRepository,
            analysisService: analysisService,
            notificationManager: notificationManager,
            examRepository: examRepository
        )

        let metadata1 = PhotoMetadata(bodyLocation: "Braço")
        let firstPhoto = try await cameraService.savePhoto(
            Data([0x01, 0x02, 0x03]),
            bodyLocation: "Braço",
            userNotes: "Primeira foto",
            patientName: "Paciente Teste",
            patientID: "ID123",
            metadata: metadata1
        )
        await Task.yield()

        let metadata2 = PhotoMetadata(bodyLocation: "Braço")
        let secondPhoto = try await cameraService.savePhoto(
            Data([0x04, 0x05, 0x06]),
            bodyLocation: "Braço",
            userNotes: "Segunda foto",
            patientName: "Paciente Teste",
            patientID: "ID123",
            metadata: metadata2
        )
        await Task.yield()

        #expect(firstPhoto.exam?.id == secondPhoto.exam?.id)

        let storedExam = try examRepository.fetch(patientID: "ID123", patientName: "Paciente Teste")
        #expect(storedExam?.photoCount == 2)
        #expect(analysisService.startedPhotoIDs.contains(firstPhoto.id))
        #expect(analysisService.startedPhotoIDs.contains(secondPhoto.id))
    }
}

@MainActor
final class MockAnalysisService: AnalysisServiceProtocol {
    private(set) var startedPhotoIDs: [UUID] = []

    func startAnalysis(for photo: SkinLesionPhoto) async throws {
        startedPhotoIDs.append(photo.id)
    }

    func getAnalysisProgress(for photoId: UUID) -> AnalysisProgress? {
        nil
    }

    func cancelAnalysis(for photoId: UUID) async {}

    func retryAnalysis(for photo: SkinLesionPhoto) async throws {}
}

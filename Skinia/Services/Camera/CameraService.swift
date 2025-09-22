import Foundation

@MainActor
final class CameraService: CameraServiceProtocol {
    private let photoRepository: any PhotoRepositoryProtocol
    private let analysisService: any AnalysisServiceProtocol
    private let notificationManager: NotificationManager

    init(photoRepository: any PhotoRepositoryProtocol, analysisService: any AnalysisServiceProtocol, notificationManager: NotificationManager) {
        self.photoRepository = photoRepository
        self.analysisService = analysisService
        self.notificationManager = notificationManager
    }

    func savePhoto(_ imageData: Data, bodyLocation: String?, userNotes: String?, patientName: String?, patientID: String?, metadata: PhotoMetadata) async throws -> SkinLesionPhoto {
        let exam = try await findOrCreateExam(patientName: patientName, patientID: patientID)

        let photo = SkinLesionPhoto(
            imageData: imageData,
            analysisStatus: .pending,
            userNotes: userNotes
        )

        metadata.bodyLocation = bodyLocation
        photo.metadata = metadata

        photo.exam = exam
        exam.addPhoto(photo)

        try photoRepository.save(photo)

        Task { @MainActor in
            do {
                try await analysisService.startAnalysis(for: photo)
            } catch {
                print("Erro ao iniciar análise automaticamente: \(error)")
                notificationManager.show(
                    title: "Erro ao iniciar análise",
                    message: "A análise não pôde ser iniciada automaticamente. Tente novamente manualmente.",
                    type: .error
                )
            }
        }

        return photo
    }

    func checkCameraPermission() async -> Bool {
        let permissionManager = CameraPermissionManager()
        return await permissionManager.requestPermission()
    }

    private func findOrCreateExam(patientName: String?, patientID: String?) async throws -> Exam {
        return Exam(patientName: patientName, patientID: patientID)
    }
}

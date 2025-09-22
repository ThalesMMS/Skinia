import Foundation

@MainActor
final class CameraService: CameraServiceProtocol {
    private let photoRepository: any PhotoRepositoryProtocol
    private let analysisService: any AnalysisServiceProtocol
    private let notificationManager: NotificationManager
    private let examRepository: any ExamRepositoryProtocol

    init(
        photoRepository: any PhotoRepositoryProtocol,
        analysisService: any AnalysisServiceProtocol,
        notificationManager: NotificationManager,
        examRepository: any ExamRepositoryProtocol
    ) {
        self.photoRepository = photoRepository
        self.analysisService = analysisService
        self.notificationManager = notificationManager
        self.examRepository = examRepository
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
        try examRepository.update(exam)

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
        let trimmedID = patientID?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = patientName?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existingExam = try examRepository.fetch(patientID: trimmedID, patientName: trimmedName) {
            if existingExam.patientID != trimmedID || existingExam.patientName != trimmedName {
                existingExam.updatePatientInfo(name: trimmedName, id: trimmedID)
                try examRepository.update(existingExam)
            }

            return existingExam
        }

        let newExam = Exam(patientName: trimmedName, patientID: trimmedID)
        try examRepository.save(newExam)
        return newExam
    }
}

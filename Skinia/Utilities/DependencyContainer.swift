import Foundation
import SwiftData

@MainActor
protocol DependencyContainerProtocol {
    // Services
    var photoRepository: any PhotoRepositoryProtocol { get }
    var analysisService: any AnalysisServiceProtocol { get }
    var cameraService: any CameraServiceProtocol { get }
    var networkService: any NetworkServiceProtocol { get }
    
    // Storage
    var modelContainer: ModelContainer { get }
}

@MainActor
final class DependencyContainer: DependencyContainerProtocol {
    
    // MARK: - Managers
    let notificationManager = NotificationManager()
    
    // MARK: - Storage
    lazy var modelContainer: ModelContainer = {
        let schema = Schema([
            SkinLesionPhoto.self,
            AnalysisResult.self,
            PhotoMetadata.self,
            Exam.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // MARK: - Services
    lazy var photoRepository: any PhotoRepositoryProtocol = PhotoRepository(
        modelContainer: modelContainer
    )
    
    lazy var analysisService: any AnalysisServiceProtocol = AnalysisService(
        networkService: networkService,
        photoRepository: photoRepository,
        notificationManager: notificationManager
    )
    
    lazy var cameraService: any CameraServiceProtocol = CameraService(
        photoRepository: photoRepository,
        analysisService: analysisService,
        notificationManager: notificationManager
    )

    lazy var networkService: any NetworkServiceProtocol = RemoteAnalysisNetworkService()
    
    // MARK: - Singleton
    static let shared = DependencyContainer()

    private init() {
        migrateSearchableBodyLocationsIfNeeded()
    }

    func migrateSearchableBodyLocationsIfNeeded() {
        do {
            try PhotoMetadata.populateMissingSearchableBodyLocations(in: modelContainer.mainContext)
        } catch {
            print("Failed to migrate searchable body locations: \(error)")
        }
    }
}

// MARK: - Protocol Placeholders
// Estes protocolos serão implementados nas próximas etapas

@MainActor
protocol AnalysisServiceProtocol {
    func startAnalysis(for photo: SkinLesionPhoto) async throws
    func getAnalysisProgress(for photoId: UUID) -> AnalysisProgress?
    func cancelAnalysis(for photoId: UUID) async
    func retryAnalysis(for photo: SkinLesionPhoto) async throws
}

@MainActor
protocol CameraServiceProtocol {
    func savePhoto(_ imageData: Data, bodyLocation: String?, userNotes: String?, patientName: String?, patientID: String?, metadata: PhotoMetadata) async throws -> SkinLesionPhoto
    func checkCameraPermission() async -> Bool
}

@MainActor
protocol NetworkServiceProtocol {
    func submitAnalysis(imageData: Data, metadata: PhotoMetadata?) async throws -> NetworkAnalysisSubmission
    func fetchAnalysisStatus(for analysisId: String) async throws -> RemoteAnalysisStatus
    func fetchAnalysisResult(for analysisId: String) async throws -> AnalysisResult
    func cancelAnalysis(for analysisId: String) async throws
}

// MARK: - Mock Implementations for now

@MainActor
final class AnalysisService: AnalysisServiceProtocol {
    private let networkService: any NetworkServiceProtocol
    private let photoRepository: any PhotoRepositoryProtocol
    private var activeAnalyses: [UUID: AnalysisProgress] = [:]
    private var analysisTasks: [UUID: Task<Void, Never>] = [:]
    private var remoteAnalysisIds: [UUID: String] = [:]
    private let notificationManager: NotificationManager

    init(networkService: any NetworkServiceProtocol, photoRepository: any PhotoRepositoryProtocol, notificationManager: NotificationManager) {
        self.networkService = networkService
        self.photoRepository = photoRepository
        self.notificationManager = notificationManager
    }

    func startAnalysis(for photo: SkinLesionPhoto) async throws {
        // Cancel any existing analysis for this photo
        if let existingTask = analysisTasks[photo.id] {
            existingTask.cancel()
            analysisTasks.removeValue(forKey: photo.id)
        }

        // Create progress tracker
        let progress = AnalysisProgress(photoId: photo.id)
        activeAnalyses[photo.id] = progress

        // Update photo status
        photo.analysisStatus = .uploading
        try photoRepository.update(photo)

        // Show start notification
        notificationManager.show(
            title: "Análise Iniciada",
            message: "Processando sua imagem...",
            type: .info
        )

        // Start analysis task
        let task = Task<Void, Never> {
            await performAnalysis(for: photo, progress: progress)
        }
        analysisTasks[photo.id] = task

        // Await the analysis
        await task.value
    }

    func getAnalysisProgress(for photoId: UUID) -> AnalysisProgress? {
        return activeAnalyses[photoId]
    }

    func cancelAnalysis(for photoId: UUID) async {
        analysisTasks[photoId]?.cancel()
        analysisTasks.removeValue(forKey: photoId)

        if let remoteId = remoteAnalysisIds.removeValue(forKey: photoId) {
            do {
                try await networkService.cancelAnalysis(for: remoteId)
            } catch {
                print("AnalysisService.cancelAnalysis - failed to cancel remote analysis: \(error)")
            }
        }

        activeAnalyses.removeValue(forKey: photoId)

        // Attempt to restore photo status
        do {
            guard let photo = try photoRepository.fetch(with: photoId) else {
                return
            }

            photo.analysisStatus = .pending

            do {
                try photoRepository.update(photo)
            } catch {
                print("AnalysisService.cancelAnalysis - failed to update photo: \(error)")
                notificationManager.show(
                    title: "Erro ao atualizar análise",
                    message: "Não foi possível restaurar o status da foto cancelada.",
                    type: .error
                )
            }
        } catch {
            print("AnalysisService.cancelAnalysis - failed to fetch photo: \(error)")
            notificationManager.show(
                title: "Erro ao carregar foto",
                message: "Não foi possível acessar a foto para cancelar a análise.",
                type: .error
            )
        }
    }

    func retryAnalysis(for photo: SkinLesionPhoto) async throws {
        photo.analysisStatus = .pending
        photo.analysisResult = nil
        try photoRepository.update(photo)
        remoteAnalysisIds.removeValue(forKey: photo.id)
        try await startAnalysis(for: photo)
    }

    private func performAnalysis(for photo: SkinLesionPhoto, progress: AnalysisProgress) async {
        do {
            let submission = try await networkService.submitAnalysis(imageData: photo.imageData, metadata: photo.metadata)
            remoteAnalysisIds[photo.id] = submission.analysisId

            if let initialStatus = submission.initialStatus {
                updateAnalysisProgress(for: photo, progress: progress, with: initialStatus)
            } else {
                progress.updateProgress(
                    stage: .uploading,
                    stageProgress: 0.1,
                    overallProgress: 0.1,
                    estimatedTimeRemaining: submission.estimatedTime
                )
                do {
                    try photoRepository.update(photo)
                } catch {
                    print("AnalysisService.performAnalysis - failed to update photo: \(error)")
                }
            }

            try await pollAnalysis(for: photo, progress: progress, analysisId: submission.analysisId)
        } catch is CancellationError {
            await handleAnalysisCancellation(for: photo, progress: progress)
        } catch {
            await handleAnalysisFailure(for: photo, progress: progress, error: error)
        }
    }

    private func pollAnalysis(for photo: SkinLesionPhoto, progress: AnalysisProgress, analysisId: String) async throws {
        while true {
            try Task.checkCancellation()

            let status = try await networkService.fetchAnalysisStatus(for: analysisId)
            updateAnalysisProgress(for: photo, progress: progress, with: status)

            if status.isFailed {
                await handleAnalysisFailure(for: photo, progress: progress, message: status.errorMessage)
                return
            }

            if status.isCompleted {
                let result = try await networkService.fetchAnalysisResult(for: analysisId)
                await completeAnalysis(for: photo, progress: progress, result: result)
                return
            }

            let safeInterval = min(max(0.5, status.suggestedRetryInterval), 30.0)
            let nanoseconds = UInt64((safeInterval * 1_000_000_000).rounded())
            try await Task.sleep(nanoseconds: nanoseconds)
        }
    }

    private func updateAnalysisProgress(for photo: SkinLesionPhoto, progress: AnalysisProgress, with status: RemoteAnalysisStatus) {
        if status.isFailed {
            progress.setError(status.errorMessage ?? "Falha na análise da imagem.")
        } else {
            progress.clearError()
        }

        progress.updateProgress(
            stage: status.stage,
            stageProgress: status.stageProgress,
            overallProgress: status.overallProgress,
            estimatedTimeRemaining: status.estimatedTimeRemaining
        )

        photo.analysisStatus = status.status

        do {
            try photoRepository.update(photo)
        } catch {
            print("AnalysisService.updateAnalysisProgress - failed to update photo: \(error)")
        }
    }

    private func completeAnalysis(for photo: SkinLesionPhoto, progress: AnalysisProgress, result: AnalysisResult) async {
        // Set final progress
        progress.updateProgress(stage: .completed, stageProgress: 1.0, overallProgress: 1.0)

        // Update photo with results
        photo.analysisStatus = .completed
        photo.analysisResult = result
        try? photoRepository.update(photo)

        // Show completion notification
        notificationManager.show(
            title: "Análise Concluída",
            message: "Resultado: \(result.lesionType) - Confiança: \(result.confidencePercentage)",
            type: .success,
            duration: 4.0
        )

        // Clean up
        activeAnalyses.removeValue(forKey: photo.id)
        analysisTasks.removeValue(forKey: photo.id)
        remoteAnalysisIds.removeValue(forKey: photo.id)
    }

    private func handleAnalysisFailure(for photo: SkinLesionPhoto, progress: AnalysisProgress, error: Error? = nil, message: String? = nil) async {
        let errorMessage = message ?? error?.localizedDescription ?? "Falha na análise. Tente novamente mais tarde."

        progress.updateProgress(stage: .failed, stageProgress: 0.0, overallProgress: progress.overallProgress)
        progress.setError(errorMessage)

        photo.analysisStatus = .failed
        try? photoRepository.update(photo)

        notificationManager.show(
            title: "Erro na Análise",
            message: errorMessage,
            type: .error,
            duration: 5.0
        )

        activeAnalyses.removeValue(forKey: photo.id)
        analysisTasks.removeValue(forKey: photo.id)
        remoteAnalysisIds.removeValue(forKey: photo.id)
    }

    private func handleAnalysisCancellation(for photo: SkinLesionPhoto, progress: AnalysisProgress) async {
        // Show cancellation notification
        notificationManager.show(
            title: "Análise Cancelada",
            message: "O processamento foi interrompido",
            type: .warning
        )

        // Clean up immediately
        activeAnalyses.removeValue(forKey: photo.id)
        analysisTasks.removeValue(forKey: photo.id)
        remoteAnalysisIds.removeValue(forKey: photo.id)
    }
}

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
        // Create or find existing exam for this patient
        let exam = try await findOrCreateExam(patientName: patientName, patientID: patientID)
        
        // Create the photo
        let photo = SkinLesionPhoto(
            imageData: imageData,
            analysisStatus: .pending,
            userNotes: userNotes
        )
        
        // Set the metadata
        metadata.bodyLocation = bodyLocation
        photo.metadata = metadata
        
        // Associate photo with exam
        photo.exam = exam
        exam.addPhoto(photo)
        
        // Save exam (which will save the photo due to relationship)
        try photoRepository.save(photo)
        
        // Automatically start analysis
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
    
    private func findOrCreateExam(patientName: String?, patientID: String?) async throws -> Exam {
        // For now, create a new exam for each photo
        // In a real app, you might want to group photos from the same session
        return Exam(patientName: patientName, patientID: patientID)
    }
    
    func checkCameraPermission() async -> Bool {
        let permissionManager = CameraPermissionManager()
        return await permissionManager.requestPermission()
    }
}

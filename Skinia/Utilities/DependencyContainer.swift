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
    
    lazy var networkService: any NetworkServiceProtocol = NetworkService()
    
    // MARK: - Singleton
    static let shared = DependencyContainer()
    
    private init() {}
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
    // Será implementado quando criarmos os serviços de rede
}

// MARK: - Mock Implementations for now

@MainActor
final class AnalysisService: AnalysisServiceProtocol {
    private let networkService: any NetworkServiceProtocol
    private let photoRepository: any PhotoRepositoryProtocol
    private var activeAnalyses: [UUID: AnalysisProgress] = [:]
    private var analysisTasks: [UUID: Task<Void, Error>] = [:]
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
        let task = Task<Void, Error> {
            await performAnalysis(for: photo, progress: progress)
        }
        analysisTasks[photo.id] = task
        
        // Await the analysis
        try await task.value
    }
    
    func getAnalysisProgress(for photoId: UUID) -> AnalysisProgress? {
        return activeAnalyses[photoId]
    }
    
    func cancelAnalysis(for photoId: UUID) async {
        // Cancel the task
        analysisTasks[photoId]?.cancel()
        analysisTasks.removeValue(forKey: photoId)

        // Remove progress tracker
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
        try await startAnalysis(for: photo)
    }
    
    private func performAnalysis(for photo: SkinLesionPhoto, progress: AnalysisProgress) async {
        do {
            // Determine mock scenario
            let scenario = MockAnalysisEngine.determineScenario(
                from: photo.imageData,
                bodyLocation: photo.metadata?.bodyLocation
            )
            
            // Check for simulated failure
            if MockAnalysisEngine.shouldSimulateFailure(for: scenario) {
                try await Task.sleep(for: .seconds(Double.random(in: 2.0...8.0)))
                await handleAnalysisFailure(for: photo, progress: progress)
                return
            }
            
            // Get analysis duration
            let totalDuration = MockAnalysisEngine.getVariableAnalysisTime(for: scenario)
            let progressCurve = MockAnalysisEngine.generateRealisticProgressCurve(for: totalDuration)
            
            // Execute analysis with realistic progress updates
            for (index, (timePoint, progressValue)) in progressCurve.enumerated() {
                // Check for cancellation
                try Task.checkCancellation()
                
                // Sleep until next progress point
                if index > 0 {
                    let previousTime = progressCurve[index - 1].0
                    let sleepDuration = timePoint - previousTime
                    try await Task.sleep(for: .seconds(sleepDuration))
                }
                
                // Update progress and photo status
                await updateAnalysisProgress(
                    for: photo,
                    progress: progress,
                    progressValue: progressValue,
                    remainingTime: totalDuration - timePoint
                )
            }
            
            // Complete analysis
            await completeAnalysis(for: photo, progress: progress, result: scenario.analysisResult)
            
        } catch is CancellationError {
            // Analysis was cancelled
            await handleAnalysisCancellation(for: photo, progress: progress)
        } catch {
            // Unexpected error
            await handleAnalysisFailure(for: photo, progress: progress, error: error)
        }
    }
    
    private func updateAnalysisProgress(for photo: SkinLesionPhoto, progress: AnalysisProgress, progressValue: Double, remainingTime: TimeInterval) async {
        // Determine current stage based on progress
        let stage: AnalysisStage
        let stageProgress: Double
        
        switch progressValue {
        case 0.0..<0.15:
            stage = .uploading
            stageProgress = progressValue / 0.15
            photo.analysisStatus = .uploading
        case 0.15..<0.25:
            stage = .preprocessing
            stageProgress = (progressValue - 0.15) / 0.10
            photo.analysisStatus = .analyzing
        case 0.25..<0.90:
            stage = .analyzing
            stageProgress = (progressValue - 0.25) / 0.65
            photo.analysisStatus = .analyzing
        case 0.90..<1.0:
            stage = .postprocessing
            stageProgress = (progressValue - 0.90) / 0.10
            photo.analysisStatus = .analyzing
        default:
            stage = .completed
            stageProgress = 1.0
            photo.analysisStatus = .completed
        }
        
        // Update progress
        progress.updateProgress(
            stage: stage,
            stageProgress: stageProgress,
            overallProgress: progressValue,
            estimatedTimeRemaining: remainingTime > 0 ? remainingTime : nil
        )
        
        // Update photo in repository
        try? photoRepository.update(photo)
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
    }
    
    private func handleAnalysisFailure(for photo: SkinLesionPhoto, progress: AnalysisProgress, error: Error? = nil) async {
        let errorMessages = [
            "Falha na comunicação com o servidor",
            "Imagem com qualidade insuficiente para análise",
            "Servidor de análise temporariamente indisponível",
            "Erro interno do sistema de IA",
            "Timeout na análise - tente novamente"
        ]
        
        let errorMessage = error?.localizedDescription ?? errorMessages.randomElement()!
        
        // Update progress with error
        progress.updateProgress(stage: .failed, stageProgress: 0.0, overallProgress: 0.0)
        progress.setError(errorMessage)
        
        // Update photo status
        photo.analysisStatus = .failed
        try? photoRepository.update(photo)
        
        // Show failure notification
        notificationManager.show(
            title: "Erro na Análise",
            message: errorMessage,
            type: .error,
            duration: 5.0
        )
        
        // Clean up after delay
        Task {
            try await Task.sleep(for: .seconds(5.0))
            activeAnalyses.removeValue(forKey: photo.id)
            analysisTasks.removeValue(forKey: photo.id)
        }
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

@MainActor
final class NetworkService: NetworkServiceProtocol {
    init() {}
}
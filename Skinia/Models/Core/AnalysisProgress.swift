import Foundation

@MainActor
@Observable
final class AnalysisProgress {
    var photoId: UUID
    var currentStage: AnalysisStage
    var overallProgress: Double
    var stageProgress: Double
    var estimatedTimeRemaining: TimeInterval?
    var errorMessage: String?
    var startTime: Date
    var lastUpdateTime: Date
    
    init(photoId: UUID) {
        self.photoId = photoId
        self.currentStage = .uploading
        self.overallProgress = 0.0
        self.stageProgress = 0.0
        self.estimatedTimeRemaining = nil
        self.errorMessage = nil
        self.startTime = Date()
        self.lastUpdateTime = Date()
    }
    
    func updateProgress(stage: AnalysisStage, stageProgress: Double, overallProgress: Double, estimatedTimeRemaining: TimeInterval? = nil) {
        self.currentStage = stage
        self.stageProgress = max(0.0, min(1.0, stageProgress))
        self.overallProgress = max(0.0, min(1.0, overallProgress))
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.lastUpdateTime = Date()
    }
    
    func setError(_ error: String) {
        self.errorMessage = error
        self.lastUpdateTime = Date()
    }
    
    func clearError() {
        self.errorMessage = nil
        self.lastUpdateTime = Date()
    }
    
    var elapsedTime: TimeInterval {
        Date().timeIntervalSince(startTime)
    }
    
    var formattedElapsedTime: String {
        let elapsed = elapsedTime
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedEstimatedTimeRemaining: String? {
        guard let remaining = estimatedTimeRemaining else { return nil }
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

enum AnalysisStage: String, CaseIterable {
    case uploading = "uploading"
    case preprocessing = "preprocessing" 
    case analyzing = "analyzing"
    case postprocessing = "postprocessing"
    case completed = "completed"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .uploading:
            return "Enviando imagem"
        case .preprocessing:
            return "Preparando análise"
        case .analyzing:
            return "Analisando com IA"
        case .postprocessing:
            return "Finalizando resultado"
        case .completed:
            return "Análise concluída"
        case .failed:
            return "Falha na análise"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .uploading:
            return "arrow.up.circle"
        case .preprocessing:
            return "gearshape.2"
        case .analyzing:
            return "brain.head.profile"
        case .postprocessing:
            return "checkmark.seal"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var expectedDuration: TimeInterval {
        switch self {
        case .uploading: return 2.0
        case .preprocessing: return 3.0
        case .analyzing: return 8.0
        case .postprocessing: return 2.0
        case .completed: return 0.0
        case .failed: return 0.0
        }
    }
}
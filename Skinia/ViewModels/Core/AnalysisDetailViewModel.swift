import Foundation
import SwiftUI

@MainActor
@Observable
final class AnalysisDetailViewModel {
    
    private(set) var photo: SkinLesionPhoto
    private let photoRepository: any PhotoRepositoryProtocol
    private let analysisService: any AnalysisServiceProtocol
    
    var isRetrying = false
    var errorMessage: String?
    
    init(
        photo: SkinLesionPhoto,
        photoRepository: any PhotoRepositoryProtocol,
        analysisService: any AnalysisServiceProtocol
    ) {
        self.photo = photo
        self.photoRepository = photoRepository
        self.analysisService = analysisService
    }
    
    var canRetryAnalysis: Bool {
        photo.analysisStatus == .failed
    }
    
    var statusDescription: String {
        switch photo.analysisStatus {
        case .pending:
            return "Aguardando upload da imagem"
        case .uploading:
            return "Enviando imagem para análise"
        case .analyzing:
            return "Analisando com IA"
        case .completed:
            return "Análise concluída"
        case .failed:
            return "Falha na análise"
        }
    }
    
    var progressPercentage: Double {
        switch photo.analysisStatus {
        case .pending:
            return 0.0
        case .uploading:
            return 0.3
        case .analyzing:
            return 0.7
        case .completed:
            return 1.0
        case .failed:
            return 0.0
        }
    }
    
    func retryAnalysis() async {
        guard canRetryAnalysis else { return }
        
        isRetrying = true
        errorMessage = nil
        
        do {
            try await analysisService.retryAnalysis(for: photo)
        } catch {
            errorMessage = "Erro ao reiniciar análise: \(error.localizedDescription)"
        }

        isRetrying = false
    }
    
    func deletePhoto() async throws {
        try photoRepository.delete(photo)
    }
    
}
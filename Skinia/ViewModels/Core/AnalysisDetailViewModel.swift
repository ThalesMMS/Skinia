import Foundation
import SwiftUI

@MainActor
@Observable
final class AnalysisDetailViewModel {
    
    private(set) var photo: SkinLesionPhoto
    private let photoRepository: any PhotoRepositoryProtocol
    
    var isRetrying = false
    var errorMessage: String?
    
    init(photo: SkinLesionPhoto, photoRepository: any PhotoRepositoryProtocol) {
        self.photo = photo
        self.photoRepository = photoRepository
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
            photo.analysisStatus = .pending
            try photoRepository.update(photo)
            
            // Simulate the analysis process
            await simulateAnalysisProgress()
        } catch {
            errorMessage = "Erro ao reiniciar análise: \(error.localizedDescription)"
        }
        
        isRetrying = false
    }
    
    func deletePhoto() async throws {
        try photoRepository.delete(photo)
    }
    
    private func simulateAnalysisProgress() async {
        // Simulate upload
        photo.analysisStatus = .uploading
        try? photoRepository.update(photo)
        try? await Task.sleep(for: .seconds(1))
        
        // Simulate analysis
        photo.analysisStatus = .analyzing
        try? photoRepository.update(photo)
        try? await Task.sleep(for: .seconds(2))
        
        // Complete with mock result
        photo.analysisStatus = .completed
        
        if photo.analysisResult == nil {
            let mockResult = AnalysisResult(
                confidence: Double.random(in: 0.7...0.95),
                lesionType: "Nevo Melanocítico",
                riskLevel: .low,
                recommendations: [
                    "Acompanhamento dermatológico anual",
                    "Proteção solar adequada",
                    "Monitoramento de mudanças na lesão"
                ]
            )
            photo.analysisResult = mockResult
        }
        
        try? photoRepository.update(photo)
    }
}
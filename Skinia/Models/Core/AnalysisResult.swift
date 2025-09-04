import Foundation
import SwiftData

@Model
final class AnalysisResult {
    var id: UUID
    var confidence: Double
    var lesionType: String
    var riskLevel: RiskLevel
    var recommendations: [String]
    var analysisDate: Date
    var additionalNotes: String?
    
    // Relacionamento com a foto
    var photo: SkinLesionPhoto?
    
    init(
        confidence: Double,
        lesionType: String,
        riskLevel: RiskLevel,
        recommendations: [String],
        analysisDate: Date = Date(),
        additionalNotes: String? = nil
    ) {
        self.id = UUID()
        self.confidence = confidence
        self.lesionType = lesionType
        self.riskLevel = riskLevel
        self.recommendations = recommendations
        self.analysisDate = analysisDate
        self.additionalNotes = additionalNotes
    }
}

extension AnalysisResult {
    var confidencePercentage: String {
        return String(format: "%.1f%%", confidence * 100)
    }
    
    var formattedAnalysisDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: analysisDate)
    }
    
    var isHighRisk: Bool {
        return riskLevel == .high || riskLevel == .urgent
    }
    
    var requiresUrgentAttention: Bool {
        return riskLevel == .urgent
    }
}
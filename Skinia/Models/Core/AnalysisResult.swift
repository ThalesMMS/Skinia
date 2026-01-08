import Foundation
import SwiftData

@Model
final class AnalysisResult {
    var id: UUID
    var confidence: Double
    var lesionType: String
    var riskLevel: RiskLevel
    var recommendations: String = "[]" // Store as JSON string directly 
    var analysisDate: Date
    var additionalNotes: String?
    
    // Relacionamento inverso removido para evitar ciclos no SwiftData
    
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
        self.recommendations = Self.encodeRecommendations(recommendations)
        self.analysisDate = analysisDate
        self.additionalNotes = additionalNotes
    }
    
    // MARK: - Computed property for recommendations array
    var recommendationsList: [String] {
        get {
            return Self.decodeRecommendations(recommendations)
        }
        set {
            recommendations = Self.encodeRecommendations(newValue)
        }
    }
    
    // MARK: - Private helpers for JSON encoding/decoding
    private static func encodeRecommendations(_ recommendations: [String]) -> String {
        do {
            let data = try JSONEncoder().encode(recommendations)
            return String(data: data, encoding: .utf8) ?? "[]"
        } catch {
            return "[]"
        }
    }
    
    private static func decodeRecommendations(_ data: String) -> [String] {
        guard let jsonData = data.data(using: .utf8) else { return [] }
        do {
            return try JSONDecoder().decode([String].self, from: jsonData)
        } catch {
            return []
        }
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
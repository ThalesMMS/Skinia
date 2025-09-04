import Foundation
import UIKit

@MainActor
final class MockAnalysisEngine {
    
    // Mock analysis scenarios based on image characteristics
    enum MockScenario: CaseIterable {
        case benignMole
        case atypicalMole
        case seborrheicKeratosis
        case basalCellCarcinoma
        case squamousCellCarcinoma
        case melanoma
        case normalSkin
        case dermatitis
        
        var analysisResult: AnalysisResult {
            switch self {
            case .benignMole:
                return AnalysisResult(
                    confidence: Double.random(in: 0.85...0.95),
                    lesionType: "Nevo Melanocítico Benigno",
                    riskLevel: .low,
                    recommendations: [
                        "Acompanhamento dermatológico anual",
                        "Proteção solar adequada",
                        "Monitoramento de mudanças na lesão",
                        "Evitar exposição solar excessiva"
                    ]
                )
                
            case .atypicalMole:
                return AnalysisResult(
                    confidence: Double.random(in: 0.75...0.88),
                    lesionType: "Nevo Atípico",
                    riskLevel: .moderate,
                    recommendations: [
                        "Consulta dermatológica em 3-6 meses",
                        "Dermatoscopia para avaliação detalhada",
                        "Proteção solar rigorosa",
                        "Monitoramento fotográfico regular",
                        "Evitar trauma na lesão"
                    ]
                )
                
            case .seborrheicKeratosis:
                return AnalysisResult(
                    confidence: Double.random(in: 0.88...0.96),
                    lesionType: "Ceratose Seborreica",
                    riskLevel: .low,
                    recommendations: [
                        "Lesão benigna, sem necessidade de tratamento",
                        "Consulta dermatológica para confirmação",
                        "Remoção apenas por motivos estéticos",
                        "Monitoramento de mudanças significativas"
                    ]
                )
                
            case .basalCellCarcinoma:
                return AnalysisResult(
                    confidence: Double.random(in: 0.72...0.87),
                    lesionType: "Possível Carcinoma Basocelular",
                    riskLevel: .high,
                    recommendations: [
                        "Consulta dermatológica URGENTE",
                        "Biópsia necessária para confirmação",
                        "Tratamento cirúrgico recomendado",
                        "Acompanhamento oncológico",
                        "Proteção solar rigorosa"
                    ]
                )
                
            case .squamousCellCarcinoma:
                return AnalysisResult(
                    confidence: Double.random(in: 0.68...0.83),
                    lesionType: "Possível Carcinoma Espinocelular",
                    riskLevel: .high,
                    recommendations: [
                        "Consulta dermatológica URGENTE",
                        "Biópsia imediata necessária",
                        "Estadiamento oncológico",
                        "Tratamento cirúrgico urgente",
                        "Seguimento oncológico rigoroso"
                    ]
                )
                
            case .melanoma:
                return AnalysisResult(
                    confidence: Double.random(in: 0.65...0.82),
                    lesionType: "Possível Melanoma",
                    riskLevel: .urgent,
                    recommendations: [
                        "CONSULTA DERMATOLÓGICA IMEDIATA",
                        "Biópsia excisional urgente",
                        "Estadiamento completo necessário",
                        "Avaliação oncológica imediata",
                        "Não retardar o tratamento"
                    ]
                )
                
            case .normalSkin:
                return AnalysisResult(
                    confidence: Double.random(in: 0.90...0.98),
                    lesionType: "Pele Normal",
                    riskLevel: .low,
                    recommendations: [
                        "Nenhuma lesão suspeita identificada",
                        "Manutenção dos cuidados preventivos",
                        "Proteção solar diária",
                        "Autoexame mensal da pele"
                    ]
                )
                
            case .dermatitis:
                return AnalysisResult(
                    confidence: Double.random(in: 0.82...0.92),
                    lesionType: "Dermatite",
                    riskLevel: .low,
                    recommendations: [
                        "Consulta dermatológica para tratamento",
                        "Evitar irritantes conhecidos",
                        "Hidratação adequada da pele",
                        "Possível uso de anti-inflamatórios tópicos"
                    ]
                )
            }
        }
        
        var failureRate: Double {
            switch self {
            case .normalSkin, .benignMole, .seborrheicKeratosis: return 0.02
            case .dermatitis, .atypicalMole: return 0.05
            case .basalCellCarcinoma, .squamousCellCarcinoma: return 0.08
            case .melanoma: return 0.12 // Higher failure rate for complex cases
            }
        }
        
        var averageAnalysisTime: TimeInterval {
            switch self {
            case .normalSkin: return 8.0
            case .benignMole, .seborrheicKeratosis, .dermatitis: return 12.0
            case .atypicalMole: return 15.0
            case .basalCellCarcinoma, .squamousCellCarcinoma: return 18.0
            case .melanoma: return 22.0 // Longer analysis for complex cases
            }
        }
    }
    
    static func determineScenario(from imageData: Data, bodyLocation: String?) -> MockScenario {
        // Simulate different scenarios based on image characteristics and body location
        let imageHash = imageData.hashValue
        let locationModifier = bodyLocationModifier(for: bodyLocation)
        
        // Use hash to create deterministic but varied results
        let scenarioIndex = abs((imageHash + locationModifier)) % MockScenario.allCases.count
        return MockScenario.allCases[scenarioIndex]
    }
    
    private static func bodyLocationModifier(for location: String?) -> Int {
        guard let location = location?.lowercased() else { return 0 }
        
        // Different body locations have different risk profiles
        switch location {
        case let loc where loc.contains("rosto") || loc.contains("pescoço"):
            return 100 // Higher chance of sun-exposed lesions
        case let loc where loc.contains("costas"):
            return 200 // Common melanoma location
        case let loc where loc.contains("perna") || loc.contains("braço"):
            return 50
        default:
            return 25
        }
    }
    
    static func shouldSimulateFailure(for scenario: MockScenario) -> Bool {
        return Double.random(in: 0.0...1.0) < scenario.failureRate
    }
    
    static func getVariableAnalysisTime(for scenario: MockScenario) -> TimeInterval {
        let baseTime = scenario.averageAnalysisTime
        let variation = baseTime * 0.3 // ±30% variation
        let randomFactor = Double.random(in: -variation...variation)
        return max(5.0, baseTime + randomFactor) // Minimum 5 seconds
    }
    
    static func generateRealisticProgressCurve(for duration: TimeInterval) -> [(TimeInterval, Double)] {
        var progressPoints: [(TimeInterval, Double)] = []
        
        // Start with upload phase (quick)
        progressPoints.append((0.0, 0.0))
        progressPoints.append((2.0, 0.15)) // Upload complete
        
        // Preprocessing (moderate)
        progressPoints.append((duration * 0.3, 0.25))
        
        // Main analysis (slow, then accelerating)
        progressPoints.append((duration * 0.5, 0.35))
        progressPoints.append((duration * 0.7, 0.55))
        progressPoints.append((duration * 0.85, 0.75))
        
        // Postprocessing (quick finish)
        progressPoints.append((duration * 0.95, 0.90))
        progressPoints.append((duration, 1.0))
        
        return progressPoints
    }
}
import Foundation

enum AnalysisStatus: String, CaseIterable, Codable {
    case pending = "pending"           // Aguardando envio
    case uploading = "uploading"       // Enviando para servidor
    case analyzing = "analyzing"       // Aguardando resposta da IA
    case completed = "completed"       // Análise concluída
    case failed = "failed"            // Erro na análise
    
    var displayName: String {
        switch self {
        case .pending:
            return "Aguardando Envio"
        case .uploading:
            return "Enviando"
        case .analyzing:
            return "Analisando"
        case .completed:
            return "Concluída"
        case .failed:
            return "Erro"
        }
    }
    
    var systemImage: String {
        switch self {
        case .pending:
            return "clock"
        case .uploading:
            return "icloud.and.arrow.up"
        case .analyzing:
            return "brain.head.profile"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .pending:
            return "gray"
        case .uploading:
            return "blue"
        case .analyzing:
            return "orange"
        case .completed:
            return "green"
        case .failed:
            return "red"
        }
    }
}

enum RiskLevel: String, CaseIterable, Codable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case urgent = "urgent"
    
    var displayName: String {
        switch self {
        case .low:
            return "Baixo Risco"
        case .moderate:
            return "Risco Moderado"
        case .high:
            return "Alto Risco"
        case .urgent:
            return "Urgente"
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "green"
        case .moderate:
            return "yellow"
        case .high:
            return "orange"
        case .urgent:
            return "red"
        }
    }
    
    var systemImage: String {
        switch self {
        case .low:
            return "checkmark.shield"
        case .moderate:
            return "exclamationmark.shield"
        case .high:
            return "exclamationmark.triangle"
        case .urgent:
            return "exclamationmark.octagon.fill"
        }
    }
}

enum ImageQuality: String, CaseIterable, Codable {
    case poor = "poor"
    case fair = "fair"
    case good = "good"
    case excellent = "excellent"
    
    var displayName: String {
        switch self {
        case .poor:
            return "Baixa"
        case .fair:
            return "Razoável"
        case .good:
            return "Boa"
        case .excellent:
            return "Excelente"
        }
    }
    
    var systemImage: String {
        switch self {
        case .poor:
            return "photo.badge.exclamationmark"
        case .fair:
            return "photo"
        case .good:
            return "photo.badge.checkmark"
        case .excellent:
            return "photo.badge.checkmark.fill"
        }
    }
}
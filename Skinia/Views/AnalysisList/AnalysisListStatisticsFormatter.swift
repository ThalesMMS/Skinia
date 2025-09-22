import Foundation

enum AnalysisListStatisticsFormatter {
    static func statisticsSummary(from photos: [SkinLesionPhoto]) -> String? {
        guard !photos.isEmpty else { return nil }

        let total = photos.count
        let completed = photos.completedCount
        let pending = photos.pendingCount
        let failed = photos.failedCount
        let highRisk = photos.highRiskCount

        return """
        Estatísticas de Análises
        Total de fotos: \(total)
        Concluídas: \(completed)
        Em andamento: \(pending)
        Com erro: \(failed)
        Alto ou urgente risco: \(highRisk)
        """
    }
}

private extension Array where Element == SkinLesionPhoto {
    var completedCount: Int {
        filter { $0.analysisStatus == .completed }.count
    }

    var pendingCount: Int {
        filter { $0.isPendingAnalysis }.count
    }

    var failedCount: Int {
        filter { $0.hasError }.count
    }

    var highRiskCount: Int {
        filter { $0.analysisResult?.riskLevel == .high || $0.analysisResult?.riskLevel == .urgent }.count
    }
}

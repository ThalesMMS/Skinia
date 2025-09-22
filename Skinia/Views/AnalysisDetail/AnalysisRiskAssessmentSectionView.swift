import SwiftUI

struct AnalysisRiskAssessmentSectionView: View {
    let riskLevel: RiskLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Avaliação de Risco")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: riskLevel.systemImage)
                        .font(.system(size: 40))
                        .foregroundColor(riskLevel.color)

                    Text(riskLevel.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(riskLevel.color)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Text(riskDescription)
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Text(riskActionText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(riskLevel.color.opacity(0.05))
        .cornerRadius(16)
    }

    private var riskDescription: String {
        switch riskLevel {
        case .low:
            return "A lesão apresenta características benignas com baixa probabilidade de malignidade."
        case .moderate:
            return "A lesão requer monitoramento regular, mas não apresenta sinais imediatos de preocupação."
        case .high:
            return "A lesão apresenta características que requerem avaliação dermatológica urgente."
        case .urgent:
            return "A lesão apresenta características altamente suspeitas que requerem atenção médica imediata."
        }
    }

    private var riskActionText: String {
        switch riskLevel {
        case .low:
            return "Continue com acompanhamento dermatológico regular."
        case .moderate:
            return "Agende consulta dermatológica em 3-6 meses."
        case .high:
            return "Consulte um dermatologista dentro de 2-4 semanas."
        case .urgent:
            return "Procure atendimento dermatológico imediatamente."
        }
    }
}

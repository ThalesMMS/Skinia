import SwiftUI

struct AnalysisResultSectionView: View {
    let result: AnalysisResult

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resultado da Análise")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Análise completa com IA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                RiskBadge(riskLevel: result.riskLevel)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Diagnóstico Principal")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(result.lesionType)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Nível de Confiança")
                        .font(.headline)
                    Spacer()
                    Text(result.confidencePercentage)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(confidenceColor(result.confidence))
                }

                ProgressView(value: result.confidence)
                    .progressViewStyle(LinearProgressViewStyle(tint: confidenceColor(result.confidence)))
                    .scaleEffect(y: 2.0, anchor: .center)

                Text(confidenceDescription(result.confidence))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(result.riskLevel.color.opacity(0.3), lineWidth: 2)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.9...1.0: return .green
        case 0.7..<0.9: return .blue
        case 0.5..<0.7: return .orange
        default: return .red
        }
    }

    private func confidenceDescription(_ confidence: Double) -> String {
        switch confidence {
        case 0.9...1.0: return "Confiança muito alta - resultado altamente confiável"
        case 0.7..<0.9: return "Confiança alta - resultado confiável"
        case 0.5..<0.7: return "Confiança moderada - considere análise adicional"
        default: return "Confiança baixa - recomendada nova análise"
        }
    }
}

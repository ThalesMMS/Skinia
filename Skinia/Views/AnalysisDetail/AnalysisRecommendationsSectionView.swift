import SwiftUI

struct AnalysisRecommendationsSectionView: View {
    let result: AnalysisResult

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recomendações Médicas")
                .font(.title2)
                .fontWeight(.bold)

            if !result.recommendationsList.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(result.recommendationsList.enumerated()), id: \.offset) { index, recommendation in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 24, height: 24)
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(recommendation)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)

                                if isUrgentRecommendation(recommendation) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                            .font(.caption2)
                                        Text("Ação urgente recomendada")
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)

                        if index < result.recommendationsList.count - 1 {
                            Divider()
                        }
                    }
                }
            } else {
                Text("Nenhuma recomendação específica disponível.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }

    private func isUrgentRecommendation(_ recommendation: String) -> Bool {
        let urgentKeywords = ["URGENTE", "IMEDIATA", "IMEDIATAMENTE", "NÃO RETARDAR"]
        return urgentKeywords.contains { keyword in
            recommendation.uppercased().contains(keyword)
        }
    }
}

import SwiftUI

struct AnalysisListHistoryOptionsSheet: View {
    let viewModel: AnalysisListViewModel
    @Binding var activeAlert: AnalysisListAlertContext?
    let onExport: (AnalysisExportFormat) -> AnalysisListAlertContext?
    let onShareStatistics: () -> AnalysisListAlertContext?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    statisticsSection
                    dateRangeSection
                    riskDistributionSection
                    exportOptionsSection
                }
                .padding()
            }
            .navigationTitle("Estatísticas do Histórico")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Concluído") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resumo Geral")
                .font(.title2)
                .fontWeight(.bold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                AnalysisListStatCard(
                    title: "Total de Análises",
                    value: "\(viewModel.getAllPhotos.count)",
                    icon: "photo.stack",
                    color: .blue
                )

                AnalysisListStatCard(
                    title: "Concluídas",
                    value: "\(viewModel.getAllPhotos.filter { $0.analysisStatus == .completed }.count)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                AnalysisListStatCard(
                    title: "Em Análise",
                    value: "\(viewModel.getAllPhotos.filter { $0.analysisStatus == .analyzing }.count)",
                    icon: "brain.head.profile",
                    color: .orange
                )

                AnalysisListStatCard(
                    title: "Falharam",
                    value: "\(viewModel.getAllPhotos.filter { $0.analysisStatus == .failed }.count)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
        }
    }

    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Análise por Período")
                .font(.headline)

            if let oldestPhoto = viewModel.getAllPhotos.min(by: { $0.captureDate < $1.captureDate }),
               let newestPhoto = viewModel.getAllPhotos.max(by: { $0.captureDate < $1.captureDate }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Primeira Análise")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(oldestPhoto.formattedCaptureDate)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Última Análise")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(newestPhoto.formattedCaptureDate)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(DesignSystem.Colors.backgroundSecondary)
                .cornerRadius(12)
            }
        }
    }

    private var riskDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distribuição de Risco")
                .font(.headline)

            let completedPhotos = viewModel.getAllPhotos.filter { $0.analysisResult != nil }

            if !completedPhotos.isEmpty {
                VStack(spacing: 8) {
                    ForEach([RiskLevel.low, .moderate, .high, .urgent], id: \.self) { riskLevel in
                        let count = completedPhotos.filter { $0.analysisResult?.riskLevel == riskLevel }.count
                        let percentage = count > 0 ? Double(count) / Double(completedPhotos.count) : 0.0

                        HStack {
                            RiskBadge(riskLevel: riskLevel)

                            Spacer()

                            Text("\(count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text("(\(Int(percentage * 100))%)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(DesignSystem.Colors.backgroundSecondary)
                .cornerRadius(12)
            } else {
                Text("Nenhuma análise concluída disponível")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
    }

    private var exportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Opções de Exportação")
                .font(.headline)

            VStack(spacing: 8) {
                Button("Exportar Relatório Completo (PDF)") {
                    activeAlert = onExport(.pdf)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)

                Button("Exportar Dados CSV") {
                    activeAlert = onExport(.csv)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(DesignSystem.Colors.backgroundSecondary)
                .foregroundColor(.primary)
                .cornerRadius(12)

                Button("Compartilhar Estatísticas") {
                    activeAlert = onShareStatistics()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(DesignSystem.Colors.backgroundSecondary)
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }
}

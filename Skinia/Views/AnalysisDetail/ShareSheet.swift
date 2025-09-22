import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let photo: SkinLesionPhoto
    let result: AnalysisResult

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let reportText = generateShareableReport()
        var items: [Any] = [reportText]

        if let image = photo.fullImage {
            items.append(image)
        }

        return UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}

    private func generateShareableReport() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        return """
        📊 RELATÓRIO DE ANÁLISE DERMATOLÓGICA

        🗓 Data da Análise: \(formatter.string(from: photo.captureDate))

        🔬 Resultado: \(result.lesionType)
        📊 Confiança: \(result.confidencePercentage)
        ⚠️ Nível de Risco: \(result.riskLevel.displayName)

        📋 RECOMENDAÇÕES:
        \(result.recommendationsList.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))

        ⚠️ IMPORTANTE: Este relatório é gerado por inteligência artificial e não substitui a consulta médica profissional. Sempre procure um dermatologista para diagnóstico definitivo.

        📱 Gerado pelo aplicativo Skinia
        """
    }
}

import SwiftUI

struct AnalysisListEmptyStateView: View {
    let onLoadSampleData: () -> Void

    private let instructionsText = "Capture uma foto da lesão ou importe uma imagem da galeria para iniciar uma nova análise e acompanhar os resultados aqui."

    var body: some View {
#if DEBUG
        EnhancedEmptyStateView(
            icon: "photo.stack",
            title: "Nenhuma Análise Encontrada",
            subtitle: instructionsText,
            actionTitle: "Carregar Dados de Exemplo",
            action: onLoadSampleData
        )
#else
        EnhancedEmptyStateView(
            icon: "photo.stack",
            title: "Nenhuma Análise Encontrada",
            subtitle: instructionsText
        )
#endif
    }
}

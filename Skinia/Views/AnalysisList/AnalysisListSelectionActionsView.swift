import SwiftUI

struct AnalysisListSelectionActionsView: View {
    @Binding var showingDeleteConfirmation: Bool
    @Binding var activeAlert: AnalysisListAlertContext?
    let onExportSelected: () -> AnalysisListAlertContext?
    let onDeleteConfirmed: () -> Void

    var body: some View {
        Menu {
            Button("Exportar Selecionadas") {
                activeAlert = onExportSelected()
            }

            Button("Excluir Selecionadas", role: .destructive) {
                HapticManager.shared.selection()
                showingDeleteConfirmation = true
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .confirmationDialog(
            "Confirmar exclusão",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Excluir", role: .destructive) {
                HapticManager.shared.impact(.medium)
                showingDeleteConfirmation = false
                onDeleteConfirmed()
            }

            Button("Cancelar", role: .cancel) {
                HapticManager.shared.selection()
            }
        } message: {
            Text("Esta ação é irreversível. As análises selecionadas serão removidas permanentemente.")
        }
    }
}

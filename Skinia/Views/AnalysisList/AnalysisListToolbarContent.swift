import SwiftUI

struct AnalysisListToolbarContent: ToolbarContent {
    @ObservedObject var selectionHelper: AnalysisListSelectionHelper
    @Binding var showingSearchField: Bool
    @Binding var showingFilterSheet: Bool
    @Binding var showingHistoryOptions: Bool
    @Binding var showingDeleteConfirmation: Bool
    @Binding var activeAlert: AnalysisListAlertContext?
    let isFilterActive: Bool
    let onExportSelected: () -> AnalysisListAlertContext?
    let onExportAll: (AnalysisExportFormat) -> AnalysisListAlertContext?
    let onDeleteSelected: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            if selectionHelper.isSelectionMode {
                Button("Cancelar") {
                    selectionHelper.clearSelection()
                }
            }
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if selectionHelper.isSelectionMode {
                AnalysisListSelectionActionsView(
                    showingDeleteConfirmation: $showingDeleteConfirmation,
                    activeAlert: $activeAlert,
                    onExportSelected: onExportSelected,
                    onDeleteConfirmed: onDeleteSelected
                )
            } else {
                Button {
                    showingSearchField.toggle()
                } label: {
                    Image(systemName: "magnifyingglass")
                }

                Button {
                    showingFilterSheet = true
                } label: {
                    Image(systemName: isFilterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }

                Menu {
                    Button("Estatísticas") {
                        showingHistoryOptions = true
                    }

                    Button("Exportar Todas") {
                        activeAlert = onExportAll(.pdf)
                    }

                    Button("Selecionar") {
                        selectionHelper.enableSelectionMode()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

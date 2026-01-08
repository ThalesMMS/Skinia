import SwiftUI

struct AnalysisListAlertContext: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

@MainActor
final class AnalysisListSelectionHelper: ObservableObject {
    @Published private(set) var selectedPhotoIDs: Set<UUID> = []
    @Published var isSelectionMode = false

    func isSelected(_ id: UUID) -> Bool {
        selectedPhotoIDs.contains(id)
    }

    func enableSelectionMode() {
        if !isSelectionMode {
            selectedPhotoIDs.removeAll()
            isSelectionMode = true
        }
    }

    func toggleSelection(for id: UUID) {
        if selectedPhotoIDs.contains(id) {
            selectedPhotoIDs.remove(id)
        } else {
            selectedPhotoIDs.insert(id)
        }
    }

    func clearSelection() {
        selectedPhotoIDs.removeAll()
        isSelectionMode = false
    }

    func deleteSelectedPhotos(using viewModel: AnalysisListViewModel) {
        let photosToDelete = viewModel.getAllPhotos.filter { selectedPhotoIDs.contains($0.id) }
        photosToDelete.forEach { viewModel.deletePhoto($0) }
        clearSelection()
    }

    func exportSelectedPhotos(
        using viewModel: AnalysisListViewModel,
        exportService: any AnalysisExportServiceProtocol,
        shareSheetPresenter: ShareSheetPresenter
    ) -> AnalysisListAlertContext? {
        let photosToExport = viewModel.getAllPhotos.filter { selectedPhotoIDs.contains($0.id) }
        let alertContext = performExport(
            photos: photosToExport,
            format: .pdf,
            exportService: exportService,
            shareSheetPresenter: shareSheetPresenter,
            emptyMessage: "Selecione ao menos uma foto para exportar."
        )

        if alertContext == nil {
            clearSelection()
        }

        return alertContext
    }

    func exportAllPhotos(
        using viewModel: AnalysisListViewModel,
        format: AnalysisExportFormat = .pdf,
        exportService: any AnalysisExportServiceProtocol,
        shareSheetPresenter: ShareSheetPresenter,
        emptyMessage: String = "Nenhuma foto disponível para exportação."
    ) -> AnalysisListAlertContext? {
        performExport(
            photos: viewModel.getAllPhotos,
            format: format,
            exportService: exportService,
            shareSheetPresenter: shareSheetPresenter,
            emptyMessage: emptyMessage
        )
    }

    private func performExport(
        photos: [SkinLesionPhoto],
        format: AnalysisExportFormat,
        exportService: any AnalysisExportServiceProtocol,
        shareSheetPresenter: ShareSheetPresenter,
        emptyMessage: String
    ) -> AnalysisListAlertContext? {
        guard !photos.isEmpty else {
            return AnalysisListAlertContext(
                title: "Nenhuma foto disponível",
                message: emptyMessage
            )
        }

        do {
            let fileURL = try exportService.exportPhotos(photos, format: format)
            shareSheetPresenter.present(items: [fileURL])
            return nil
        } catch {
            return AnalysisListAlertContext(
                title: "Erro ao exportar",
                message: error.localizedDescription
            )
        }
    }
}

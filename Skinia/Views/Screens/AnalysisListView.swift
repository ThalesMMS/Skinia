import SwiftUI

struct AnalysisListView: View {
    private let exportService: any AnalysisExportServiceProtocol
    private let shareSheetPresenter: ShareSheetPresenter

    @State private var viewModel: AnalysisListViewModel
    @StateObject private var coordinator: AnalysisListCoordinator

    @State private var showingFilterSheet = false
    @State private var showingSearchField = false
    @State private var showingHistoryOptions = false
    @StateObject private var sheetState = AnalysisDetailSheetState()
    @StateObject private var selectionHelper = AnalysisListSelectionHelper()
    @State private var activeAlert: AnalysisListAlertContext?
    @State private var showingDeleteConfirmation = false

    init(
        coordinator: AnalysisListCoordinator,
        exportService: any AnalysisExportServiceProtocol,
        shareSheetPresenter: ShareSheetPresenter
    ) {
        self.exportService = exportService
        self.shareSheetPresenter = shareSheetPresenter
        self._coordinator = StateObject(wrappedValue: coordinator)
        self._viewModel = State(wrappedValue: AnalysisListViewModel(
            photoRepository: coordinator.dependencyContainer.photoRepository
        ))
    }

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    AnalysisListLoadingView()
                } else if !viewModel.hasPhotos {
                    AnalysisListEmptyStateView {
                        do {
                            try PreviewPhotoFactory.seed(repository: coordinator.dependencyContainer.photoRepository)
                            viewModel.loadPhotos()
                        } catch {
                            activeAlert = AnalysisListAlertContext(
                                title: "Erro",
                                message: "Falha ao carregar dados de exemplo: \(error.localizedDescription)"
                            )
                        }
                    }
                } else {
                    photosList
                }
            }
            .navigationTitle("Análises")
            .toolbar {
                AnalysisListToolbarContent(
                    selectionHelper: selectionHelper,
                    showingSearchField: $showingSearchField,
                    showingFilterSheet: $showingFilterSheet,
                    showingHistoryOptions: $showingHistoryOptions,
                    showingDeleteConfirmation: $showingDeleteConfirmation,
                    activeAlert: $activeAlert,
                    isFilterActive: viewModel.selectedStatusFilter != nil,
                    onExportSelected: handleExportSelected,
                    onExportAll: handleExportAll(format:),
                    onDeleteSelected: handleDeleteSelected
                )
            }
            .refreshable {
                HapticManager.shared.impact(.light)
                await viewModel.refreshPhotos()
            }
            .searchable(
                text: $viewModel.searchText,
                isPresented: $showingSearchField,
                prompt: "Buscar por localização, tipo..."
            )
            .sheet(isPresented: $showingFilterSheet) {
                AnalysisListFilterSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingHistoryOptions) {
                AnalysisListHistoryOptionsSheet(
                    viewModel: viewModel,
                    activeAlert: $activeAlert,
                    onExport: { format in
                        handleExportAll(format: format)
                    },
                    onShareStatistics: {
                        shareStatisticsSummary()
                    }
                )
            }
            .alert(item: $activeAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK")) {
                        activeAlert = nil
                        viewModel.clearErrorMessage()
                    }
                )
            }
        }
        .onAppear {
            viewModel.loadPhotos()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await viewModel.refreshPhotos()
            }
        }
        .onChange(of: coordinator.shouldRefresh) { _, shouldRefresh in
            if shouldRefresh {
                Task {
                    await viewModel.refreshPhotos()
                    await MainActor.run {
                        coordinator.shouldRefresh = false
                    }
                }
            }
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            if let message {
                activeAlert = AnalysisListAlertContext(title: "Erro", message: message)
            }
        }
        .sheet(isPresented: $sheetState.isShowing) {
            AnalysisDetailSheetView(
                sheetState: sheetState,
                dependencyContainer: coordinator.dependencyContainer,
                exportService: exportService,
                shareSheetPresenter: shareSheetPresenter
            )
        }
    }

    private var photosList: some View {
        List {
            if !viewModel.photosNeedingAttention.isEmpty {
                Section {
                    ForEach(viewModel.photosNeedingAttention, id: \.id) { photo in
                        photoRow(for: photo)
                            .swipeActions(edge: .trailing) {
                                Button("Excluir", role: .destructive) {
                                    viewModel.deletePhoto(photo)
                                }
                            }
                    }
                } header: {
                    Label("Requerem Atenção", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            }

            Section {
                ForEach(viewModel.photos, id: \.id) { photo in
                    photoRow(for: photo)
                        .swipeActions(edge: .trailing) {
                            Button("Excluir", role: .destructive) {
                                viewModel.deletePhoto(photo)
                            }
                        }
                }
            } header: {
                HStack {
                    Text("Todas as Análises")

                    Spacer()

                    if viewModel.selectedStatusFilter != nil || !viewModel.searchText.isEmpty {
                        Button("Limpar Filtros") {
                            viewModel.clearFilters()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .animation(DesignSystem.Animations.gentle, value: viewModel.photos)
        .animation(DesignSystem.Animations.gentle, value: viewModel.photosNeedingAttention)
    }

    @ViewBuilder
    private func photoRow(for photo: SkinLesionPhoto) -> some View {
        HStack {
            if selectionHelper.isSelectionMode {
                Button(action: {
                    selectionHelper.toggleSelection(for: photo.id)
                }) {
                    Image(systemName: selectionHelper.isSelected(photo.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectionHelper.isSelected(photo.id) ? .blue : .gray)
                }
                .buttonStyle(PlainButtonStyle())
            }

            AnalysisListCell(photo: photo) {
                if selectionHelper.isSelectionMode {
                    selectionHelper.toggleSelection(for: photo.id)
                } else {
                    sheetState.showSheet(with: photo)
                }
            }
        }
    }

    private func handleExportSelected() -> AnalysisListAlertContext? {
        selectionHelper.exportSelectedPhotos(
            using: viewModel,
            exportService: exportService,
            shareSheetPresenter: shareSheetPresenter
        )
    }

    private func handleExportAll(
        format: AnalysisExportFormat = .pdf,
        emptyMessage: String = "Nenhuma foto disponível para exportação."
    ) -> AnalysisListAlertContext? {
        selectionHelper.exportAllPhotos(
            using: viewModel,
            format: format,
            exportService: exportService,
            shareSheetPresenter: shareSheetPresenter,
            emptyMessage: emptyMessage
        )
    }

    private func handleDeleteSelected() {
        selectionHelper.deleteSelectedPhotos(using: viewModel)
    }

    private func shareStatisticsSummary() -> AnalysisListAlertContext? {
        guard let summary = AnalysisListStatisticsFormatter.statisticsSummary(from: viewModel.getAllPhotos) else {
            return AnalysisListAlertContext(
                title: "Sem dados",
                message: "Cadastre análises para compartilhar estatísticas."
            )
        }

        shareSheetPresenter.present(items: [summary])
        return nil
    }
}

#Preview {
    let container = DependencyContainer.shared
    let _ = try? PreviewPhotoFactory.seed(repository: container.photoRepository)
    let coordinator = AnalysisListCoordinator(dependencyContainer: container)

    return AnalysisListView(
        coordinator: coordinator,
        exportService: container.analysisExportService,
        shareSheetPresenter: container.shareSheetPresenter
    )
}
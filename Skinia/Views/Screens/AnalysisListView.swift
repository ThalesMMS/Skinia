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
                            print("Falha ao carregar dados de exemplo: \(error)")
                        }
                    }
                } else {
                    photosList
                }
            }
            .navigationTitle("Análises")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if selectionHelper.isSelectionMode {
                        Button("Cancelar") {
                            selectionHelper.clearSelection()
                        }
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if selectionHelper.isSelectionMode {
                        Menu {
                            Button("Exportar Selecionadas") {
                                exportSelectedPhotos()
                            }

                            Button("Excluir Selecionadas", role: .destructive) {
                                HapticManager.shared.selection()
                                showingDeleteConfirmation = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    } else {
                        Button {
                            showingSearchField.toggle()
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }

                        Button {
                            showingFilterSheet = true
                        } label: {
                            Image(systemName: viewModel.selectedStatusFilter != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        }

                        Menu {
                            Button("Estatísticas") {
                                showingHistoryOptions = true
                            }

                            Button("Exportar Todas") {
                                activeAlert = exportAllPhotos()
                            }

                            Button("Selecionar") {
                                if selectionHelper.isSelectionMode {
                                    selectionHelper.clearSelection()
                                } else {
                                    selectionHelper.enableSelectionMode()
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
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
                        exportAllPhotos(format: format)
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
            .confirmationDialog(
                "Confirmar exclusão",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Excluir", role: .destructive) {
                    HapticManager.shared.impact(.medium)
                    deleteSelectedPhotos()
                }

                Button("Cancelar", role: .cancel) {
                    HapticManager.shared.selection()
                }
            } message: {
                Text("Esta ação é irreversível. As análises selecionadas serão removidas permanentemente.")
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
            let _ = print("🔍 Sheet building - isShowing: \(sheetState.isShowing), selectedPhoto: \(sheetState.selectedPhoto?.id.uuidString ?? "nil")")

            if let photoToShow = sheetState.selectedPhoto {
                let _ = print("🔍 Sheet presenting AnalysisDetailView for photo: \(photoToShow.id)")
                NavigationView {
                    AnalysisDetailView(
                        photo: photoToShow,
                        photoRepository: coordinator.dependencyContainer.photoRepository,
                        analysisService: coordinator.dependencyContainer.analysisService
                    )
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Fechar") {
                                    print("🔍 Closing sheet")
                                    sheetState.hideSheet()
                                }
                            }
                        }
                        .onAppear {
                            print("🔍 Sheet AnalysisDetailView appeared for photo: \(photoToShow.id)")
                        }
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .environment(\.analysisService, coordinator.dependencyContainer.analysisService)
                .environment(\.notificationManager, coordinator.dependencyContainer.notificationManager)
            } else {
                let _ = print("🔍 Sheet presenting but selectedPhoto is nil - creating placeholder")
                VStack {
                    Text("Error: Photo not found")
                        .foregroundColor(.red)
                    Button("Close") {
                        sheetState.hideSheet()
                    }
                }
                .padding()
            }
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
                    print("🔍 Card tapped - showing detail for photo: \(photo.id)")
                    sheetState.showSheet(with: photo)
                }
            }
        }
    }

    private func exportSelectedPhotos() {
        activeAlert = selectionHelper.exportSelectedPhotos(
            using: viewModel,
            exportService: exportService,
            shareSheetPresenter: shareSheetPresenter
        )
    }

    private func exportAllPhotos(
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

    private func deleteSelectedPhotos() {
        selectionHelper.deleteSelectedPhotos(using: viewModel)
    }

    private func shareStatisticsSummary() -> AnalysisListAlertContext? {
        let photos = viewModel.getAllPhotos

        guard !photos.isEmpty else {
            return AnalysisListAlertContext(
                title: "Sem dados",
                message: "Cadastre análises para compartilhar estatísticas."
            )
        }

        let total = photos.count
        let completed = photos.filter { $0.analysisStatus == .completed }.count
        let pending = photos.filter { $0.isPendingAnalysis }.count
        let failed = photos.filter { $0.hasError }.count
        let highRisk = photos.filter { $0.analysisResult?.riskLevel == .high || $0.analysisResult?.riskLevel == .urgent }.count

        let summary = """
        Estatísticas de Análises
        Total de fotos: \(total)
        Concluídas: \(completed)
        Em andamento: \(pending)
        Com erro: \(failed)
        Alto ou urgente risco: \(highRisk)
        """

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

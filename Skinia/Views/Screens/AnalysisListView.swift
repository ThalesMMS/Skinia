import SwiftUI

class SheetState: ObservableObject {
    @Published var selectedPhoto: SkinLesionPhoto?
    @Published var isShowing: Bool = false
    
    func showSheet(with photo: SkinLesionPhoto) {
        print("🔍 SheetState: Setting photo \(photo.id) and showing sheet")
        selectedPhoto = photo
        isShowing = true
    }
    
    func hideSheet() {
        print("🔍 SheetState: Hiding sheet and clearing photo")
        isShowing = false
        selectedPhoto = nil
    }
}

struct AnalysisListView: View {
    @State private var viewModel: AnalysisListViewModel
    @StateObject private var coordinator: AnalysisListCoordinator
    
    @State private var showingFilterSheet = false
    @State private var showingSearchField = false
    @State private var showingHistoryOptions = false
    @State private var showingBatchActions = false
    @State private var selectedPhotos = Set<UUID>()
    @StateObject private var sheetState = SheetState()
    
    init(coordinator: AnalysisListCoordinator) {
        self._coordinator = StateObject(wrappedValue: coordinator)
        self._viewModel = State(wrappedValue: AnalysisListViewModel(
            photoRepository: coordinator.dependencyContainer.photoRepository
        ))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    LoadingView()
                } else if !viewModel.hasPhotos {
                    EmptyStateView {
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
                    if !selectedPhotos.isEmpty {
                        Button("Cancelar") {
                            selectedPhotos.removeAll()
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !selectedPhotos.isEmpty {
                        Menu {
                            Button("Exportar Selecionadas") {
                                exportSelectedPhotos()
                            }
                            
                            Button("Excluir Selecionadas", role: .destructive) {
                                deleteSelectedPhotos()
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
                                exportAllPhotos()
                            }
                            
                            Button("Selecionar") {
                                // Enable selection mode
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
                FilterSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingHistoryOptions) {
                HistoryOptionsSheet(viewModel: viewModel)
            }
            .alert("Erro", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    // Clear error
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
        .onAppear {
            // Load real data from repository
            viewModel.loadPhotos()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh data when app comes back to foreground
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
            // Attention section
            if !viewModel.photosNeedingAttention.isEmpty {
                Section {
                    ForEach(viewModel.photosNeedingAttention, id: \.id) { photo in
                        HStack {
                            if !selectedPhotos.isEmpty {
                                Button(action: {
                                    toggleSelection(for: photo.id)
                                }) {
                                    Image(systemName: selectedPhotos.contains(photo.id) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedPhotos.contains(photo.id) ? .blue : .gray)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            AnalysisListCell(photo: photo) {
                                if selectedPhotos.isEmpty {
                                    print("🔍 Card tapped - showing detail for photo: \(photo.id)")
                                    sheetState.showSheet(with: photo)
                                } else {
                                    toggleSelection(for: photo.id)
                                }
                            }
                        }
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
            
            // All photos section
            Section {
                ForEach(viewModel.photos, id: \.id) { photo in
                    HStack {
                        if !selectedPhotos.isEmpty {
                            Button(action: {
                                toggleSelection(for: photo.id)
                            }) {
                                Image(systemName: selectedPhotos.contains(photo.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedPhotos.contains(photo.id) ? .blue : .gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        AnalysisListCell(photo: photo) {
                            if selectedPhotos.isEmpty {
                                print("🔍 Card tapped - showing detail for photo: \(photo.id)")
                                sheetState.showSheet(with: photo)
                            } else {
                                toggleSelection(for: photo.id)
                            }
                        }
                    }
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
    
    // MARK: - Helper Functions
    
    private func toggleSelection(for photoId: UUID) {
        if selectedPhotos.contains(photoId) {
            selectedPhotos.remove(photoId)
        } else {
            selectedPhotos.insert(photoId)
        }
    }
    
    private func exportSelectedPhotos() {
        let photosToExport = viewModel.getAllPhotos.filter { selectedPhotos.contains($0.id) }
        // TODO: Implement export functionality
        print("Exporting \(photosToExport.count) selected photos")
        selectedPhotos.removeAll()
    }
    
    private func exportAllPhotos() {
        // TODO: Implement export all functionality
        print("Exporting all \(viewModel.getAllPhotos.count) photos")
    }
    
    private func deleteSelectedPhotos() {
        let photosToDelete = viewModel.getAllPhotos.filter { selectedPhotos.contains($0.id) }
        for photo in photosToDelete {
            viewModel.deletePhoto(photo)
        }
        selectedPhotos.removeAll()
    }
}

// MARK: - Supporting Views

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            PulsatingCircle(
                color: DesignSystem.Colors.primary,
                size: 60
            )
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Carregando análises...")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
                
                LoadingDots()
            }
            
            // Skeleton loaders
            VStack(spacing: DesignSystem.Spacing.md) {
                ForEach(0..<3) { _ in
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            SkeletonLoader(height: 60, cornerRadius: DesignSystem.CornerRadius.sm)
                                .frame(width: 60)
                            
                            VStack(spacing: DesignSystem.Spacing.xs) {
                                SkeletonLoader(height: 16)
                                SkeletonLoader(height: 12)
                                SkeletonLoader(height: 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .cardStyle()
                }
            }
            .padding(.top, DesignSystem.Spacing.lg)
        }
        .padding(DesignSystem.Spacing.lg)
    }
}

private struct EmptyStateView: View {
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

private struct FilterSheet: View {
    let viewModel: AnalysisListViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Filtrar por Status") {
                    ForEach([AnalysisStatus?.none] + viewModel.statusFilterOptions.map { Optional($0) }, id: \.self) { status in
                        HStack {
                            if let status = status {
                                StatusBadge(status: status)
                            } else {
                                Text("Todos")
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            if viewModel.selectedStatusFilter == status {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.setStatusFilter(status)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Concluído") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct HistoryOptionsSheet: View {
    let viewModel: AnalysisListViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Statistics Overview
                    statisticsSection
                    
                    // Date Range Analysis
                    dateRangeSection
                    
                    // Risk Distribution
                    riskDistributionSection
                    
                    // Export Options
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
                StatCard(
                    title: "Total de Análises",
                    value: "\(viewModel.getAllPhotos.count)",
                    icon: "photo.stack",
                    color: .blue
                )
                
                StatCard(
                    title: "Concluídas",
                    value: "\(viewModel.getAllPhotos.filter { $0.analysisStatus == .completed }.count)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Em Análise",
                    value: "\(viewModel.getAllPhotos.filter { $0.analysisStatus == .analyzing }.count)",
                    icon: "brain.head.profile",
                    color: .orange
                )
                
                StatCard(
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
                    // TODO: Implement PDF export
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                
                Button("Exportar Dados CSV") {
                    // TODO: Implement CSV export
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(DesignSystem.Colors.backgroundSecondary)
                .foregroundColor(.primary)
                .cornerRadius(12)
                
                Button("Compartilhar Estatísticas") {
                    // TODO: Implement sharing
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

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(DesignSystem.Colors.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    let container = DependencyContainer.shared
    let _ = try? PreviewPhotoFactory.seed(repository: container.photoRepository)
    let coordinator = AnalysisListCoordinator(dependencyContainer: container)

    return AnalysisListView(coordinator: coordinator)
}

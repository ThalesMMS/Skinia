import Foundation
import SwiftUI

@MainActor
final class AnalysisListCoordinator: NavigationCoordinator, ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var shouldRefresh = false
    
    var parent: (any Coordinator)?
    var children: [any Coordinator] = []
    
    let dependencyContainer: DependencyContainer
    
    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
    }
    
    func start() {
        // Inicialização se necessária
    }
    
    func refreshList() async {
        await MainActor.run {
            shouldRefresh = true
        }
    }
    
    @ViewBuilder
    func build() -> some View {
        AnalysisListView(
            coordinator: self,
            exportService: dependencyContainer.analysisExportService,
            shareSheetPresenter: dependencyContainer.shareSheetPresenter
        )
    }
    
    // MARK: - Navigation Methods
    func showAnalysisDetail(for photo: SkinLesionPhoto) {
        // Navigation handled directly in AnalysisListView
    }
}

// MARK: - Navigation Routes
struct AnalysisDetailRoute: Hashable {
    let photo: SkinLesionPhoto
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(photo.id)
    }
    
    static func == (lhs: AnalysisDetailRoute, rhs: AnalysisDetailRoute) -> Bool {
        lhs.photo.id == rhs.photo.id
    }
}
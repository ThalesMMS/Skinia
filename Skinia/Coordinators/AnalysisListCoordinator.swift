import Foundation
import SwiftUI

@MainActor
final class AnalysisListCoordinator: NavigationCoordinator, ObservableObject {
    @Published var navigationPath = NavigationPath()
    
    var parent: (any Coordinator)?
    var children: [any Coordinator] = []
    
    let dependencyContainer: DependencyContainer
    
    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
    }
    
    func start() {
        // Inicialização se necessária
    }
    
    @ViewBuilder
    func build() -> some View {
        NavigationStack(path: Binding(
            get: { self.navigationPath },
            set: { self.navigationPath = $0 }
        )) {
            AnalysisListView(coordinator: self)
                .navigationDestination(for: AnalysisDetailRoute.self) { route in
                    AnalysisDetailView(photo: route.photo)
                }
        }
    }
    
    // MARK: - Navigation Methods
    func showAnalysisDetail(for photo: SkinLesionPhoto) {
        push(AnalysisDetailRoute(photo: photo))
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
import Foundation
import SwiftUI

@MainActor
final class CameraCoordinator: NavigationCoordinator, ObservableObject {
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
    
    func navigateToAnalysisList() {
        // Navigate to analysis list tab through parent coordinator
        if let tabCoordinator = parent as? (any TabCoordinator) {
            tabCoordinator.selectTab(0)
        }
    }
    
    @ViewBuilder
    func build() -> some View {
        NavigationStack(path: Binding(
            get: { self.navigationPath },
            set: { self.navigationPath = $0 }
        )) {
            CameraScreen(coordinator: self)
        }
    }
}
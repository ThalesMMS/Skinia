import Foundation
import SwiftUI

@MainActor
final class SettingsCoordinator: NavigationCoordinator, ObservableObject {
    @Published var navigationPath = NavigationPath()
    
    var parent: (any Coordinator)?
    var children: [any Coordinator] = []
    
    private let dependencyContainer: DependencyContainer
    
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
            SettingsView()
        }
    }
}
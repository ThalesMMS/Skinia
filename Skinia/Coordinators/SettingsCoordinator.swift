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
            SettingsPlaceholderView()
        }
    }
}

private struct SettingsPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gear")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("Configurações")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Interface de configurações será implementada na Fase 5")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .navigationTitle("Configurações")
    }
}
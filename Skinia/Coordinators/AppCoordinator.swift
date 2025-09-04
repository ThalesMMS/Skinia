import Foundation
import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var selectedTab: Int = 0
    
    private let dependencyContainer: DependencyContainer
    
    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
    }
    
    func start() {
        // Inicialização será implementada quando necessário
    }
    
    @ViewBuilder
    func build() -> some View {
        TabView {
            // Tab 1: Análises (Lista principal)
            PlaceholderView(title: "Análises")
                .tabItem {
                    Image(systemName: "photo.stack")
                    Text("Análises")
                }
            
            // Tab 2: Nova Foto (Captura)
            PlaceholderView(title: "Nova Foto")
                .tabItem {
                    Image(systemName: "plus")
                    Text("Nova Foto")
                }
            
            // Tab 3: Configurações
            PlaceholderView(title: "Configurações")
                .tabItem {
                    Image(systemName: "gear")
                    Text("Configurações")
                }
        }
    }
}

private struct PlaceholderView: View {
    let title: String
    
    var body: some View {
        VStack {
            Image(systemName: "app.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.title)
                .foregroundColor(.primary)
            
            Text("Em breve...")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}
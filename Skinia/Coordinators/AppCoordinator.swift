import Foundation
import SwiftUI

@MainActor
final class AppCoordinator: TabCoordinator, ObservableObject {
    @Published var selectedTab: Int = 0
    
    var parent: (any Coordinator)?
    var children: [any Coordinator] = []
    var tabCoordinators: [any Coordinator] = []
    
    private let dependencyContainer: DependencyContainer
    
    // Tab coordinators
    private lazy var analysisListCoordinator = AnalysisListCoordinator(dependencyContainer: dependencyContainer)
    private lazy var cameraCoordinator = CameraCoordinator(dependencyContainer: dependencyContainer)
    private lazy var settingsCoordinator = SettingsCoordinator(dependencyContainer: dependencyContainer)
    
    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
        setupTabCoordinators()
    }
    
    func start() {
        tabCoordinators.forEach { coordinator in
            addChild(coordinator)
            coordinator.start()
        }
    }
    
    private func setupTabCoordinators() {
        tabCoordinators = [
            analysisListCoordinator,
            cameraCoordinator,
            settingsCoordinator
        ]
    }
    
    @ViewBuilder
    func build() -> some View {
        TabView(selection: Binding(
            get: { self.selectedTab },
            set: { self.selectedTab = $0 }
        )) {
            // Tab 1: Análises (Lista principal)
            analysisListCoordinator.build()
                .tabItem {
                    Image(systemName: "photo.stack")
                    Text("Análises")
                }
                .tag(0)
            
            // Tab 2: Nova Foto (Captura)
            cameraCoordinator.build()
                .tabItem {
                    Image(systemName: "plus")
                    Text("Nova Foto")
                }
                .tag(1)
            
            // Tab 3: Configurações
            settingsCoordinator.build()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Configurações")
                }
                .tag(2)
        }
        .environment(\.analysisService, dependencyContainer.analysisService)
        .environment(\.notificationManager, dependencyContainer.notificationManager)
        .overlay(
            NotificationOverlay()
        )
    }
}
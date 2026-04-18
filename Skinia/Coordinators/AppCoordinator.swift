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
    
    func selectTab(_ index: Int) {
        selectedTab = index
        // If switching to analysis list, refresh it
        if index == 0 {
            Task {
                await refreshAnalysList()
            }
        }
    }
    
    private func refreshAnalysList() async {
        // Notify analysis list to refresh
        if let analysisCoordinator = tabCoordinators.first as? AnalysisListCoordinator {
            await analysisCoordinator.refreshList()
        }
    }
    
    private func setupTabCoordinators() {
        tabCoordinators = [
            analysisListCoordinator,
            cameraCoordinator,
            settingsCoordinator
        ]
    }
    
    /// Builds the app's main tab-based interface with Analysis, Camera, and Settings tabs.
    @ViewBuilder
    func build() -> some View {
        TabView(selection: Binding(
            get: { self.selectedTab },
            set: { self.selectedTab = $0 }
        )) {
            // Tab 1: Analysis (Main list)
            analysisListCoordinator.build()
                .tabItem {
                    Image(systemName: "photo.stack")
                    Text("Analyses")
                }
                .tag(0)

            // Tab 2: New Photo (Capture)
            cameraCoordinator.build()
                .tabItem {
                    Image(systemName: "plus")
                    Text("New Photo")
                }
                .tag(1)
            
            // Tab 3: Settings
            settingsCoordinator.build()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
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
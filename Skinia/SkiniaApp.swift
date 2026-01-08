//
//  SkiniaApp.swift
//  Skinia
//
//  Created by Thales Matheus Mendonça Santos on 04/09/25.
//

import SwiftUI
import SwiftData

@main
struct SkiniaApp: App {
    @StateObject private var appCoordinator = AppCoordinator(dependencyContainer: DependencyContainer.shared)
    
    var body: some Scene {
        WindowGroup {
            appCoordinator.build()
                .modelContainer(DependencyContainer.shared.modelContainer)
                .onAppear {
                    appCoordinator.start()
                }
        }
    }
}

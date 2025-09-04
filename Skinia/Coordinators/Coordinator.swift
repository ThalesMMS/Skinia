import Foundation
import SwiftUI

@MainActor
protocol Coordinator: ObservableObject {
    associatedtype Body: View
    
    var parent: (any Coordinator)? { get set }
    var children: [any Coordinator] { get set }
    
    func start()
    func stop()
    func addChild(_ coordinator: any Coordinator)
    func removeChild(_ coordinator: any Coordinator)
    
    @ViewBuilder func build() -> Body
}

extension Coordinator {
    func addChild(_ coordinator: any Coordinator) {
        children.append(coordinator)
        coordinator.parent = self
    }
    
    func removeChild(_ coordinator: any Coordinator) {
        children.removeAll { $0 === coordinator }
        coordinator.parent = nil
    }
    
    func stop() {
        children.forEach { $0.stop() }
        children.removeAll()
        parent?.removeChild(self)
    }
}

protocol NavigationCoordinator: Coordinator {
    var navigationPath: NavigationPath { get set }
    
    func push<T: Hashable>(_ item: T)
    func pop()
    func popToRoot()
}

extension NavigationCoordinator {
    func push<T: Hashable>(_ item: T) {
        navigationPath.append(item)
    }
    
    func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func popToRoot() {
        navigationPath.removeLast(navigationPath.count)
    }
}

protocol TabCoordinator: Coordinator {
    var selectedTab: Int { get set }
    var tabCoordinators: [any Coordinator] { get }
    
    func selectTab(_ index: Int)
}

extension TabCoordinator {
    func selectTab(_ index: Int) {
        guard index >= 0 && index < tabCoordinators.count else { return }
        selectedTab = index
    }
}
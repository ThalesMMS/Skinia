import Foundation
import SwiftUI
import Photos

@MainActor
final class CameraCoordinator: NavigationCoordinator, ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var photoLibraryStatus: PHAuthorizationStatus = .notDetermined
    
    var parent: (any Coordinator)?
    var children: [any Coordinator] = []
    
    let dependencyContainer: DependencyContainer
    
    init(dependencyContainer: DependencyContainer) {
        self.dependencyContainer = dependencyContainer
    }
    
    func start() {
        // Check initial photo library authorization status
        photoLibraryStatus = PHPhotoLibrary.authorizationStatus()
    }
    
    func navigateToAnalysisList() {
        // Navigate to analysis list tab through parent coordinator
        if let tabCoordinator = parent as? (any TabCoordinator) {
            tabCoordinator.selectTab(0)
        }
    }
    
    func requestPhotoLibraryAccess() async -> Bool {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.photoLibraryStatus = status
                    continuation.resume(returning: status == .authorized || status == .limited)
                }
            }
        }
    }
    
    func savePhotoToAnalysisList(_ imageData: Data, bodyLocation: String?, userNotes: String?, patientName: String?, patientID: String?, metadata: PhotoMetadata) async throws -> SkinLesionPhoto {
        return try await dependencyContainer.cameraService.savePhoto(
            imageData,
            bodyLocation: bodyLocation,
            userNotes: userNotes,
            patientName: patientName,
            patientID: patientID,
            metadata: metadata
        )
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
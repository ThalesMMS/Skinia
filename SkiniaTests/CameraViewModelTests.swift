import Testing
import UIKit
@testable import Skinia

@MainActor
final class MockCameraCoordinator: CameraCoordinating {
    enum MockError: Error {
        case failed
    }

    private(set) var startCalled = false
    private(set) var navigateToAnalysisListCalled = false
    private(set) var savedPhotoPayloads: [(data: Data, bodyLocation: String?, notes: String?, patientName: String?, patientID: String?, metadata: PhotoMetadata)] = []
    var shouldThrowOnSave = false

    func start() {
        startCalled = true
    }

    func navigateToAnalysisList() {
        navigateToAnalysisListCalled = true
    }

    func savePhotoToAnalysisList(
        _ imageData: Data,
        bodyLocation: String?,
        userNotes: String?,
        patientName: String?,
        patientID: String?,
        metadata: PhotoMetadata
    ) async throws -> SkinLesionPhoto {
        if shouldThrowOnSave {
            throw MockError.failed
        }

        savedPhotoPayloads.append((
            data: imageData,
            bodyLocation: bodyLocation,
            notes: userNotes,
            patientName: patientName,
            patientID: patientID,
            metadata: metadata
        ))

        return SkinLesionPhoto(imageData: imageData)
    }
}

@MainActor
struct CameraViewModelTests {
    @Test
    func updatesCameraAvailabilityWhenPermissionChanges() async {
        let permissionManager = CameraPermissionManager()
        permissionManager.authorizationStatus = .denied
        let coordinator = MockCameraCoordinator()
        let viewModel = CameraViewModel(coordinator: coordinator, permissionManager: permissionManager)

        #expect(viewModel.canUseCamera == false)

        permissionManager.authorizationStatus = .authorized
        await Task.yield()

        #expect(viewModel.canUseCamera == true)
    }

    @Test
    func savePhotoSuccessResetsStateAndNavigates() async {
        let coordinator = MockCameraCoordinator()
        let viewModel = CameraViewModel(coordinator: coordinator)
        viewModel.capturedImage = makeTestImage()
        viewModel.imageMetadata = ["{Exif}": ["Flash": 1]]

        await viewModel.savePhoto(
            bodyLocation: "Braço",
            userNotes: "Observação",
            patientName: "Paciente",
            patientID: "123"
        )

        #expect(coordinator.savedPhotoPayloads.count == 1)
        #expect(coordinator.navigateToAnalysisListCalled)
        #expect(viewModel.capturedImage == nil)
        #expect(viewModel.showingPreview == false)
        #expect(viewModel.isSaving == false)
        #expect(viewModel.selectedBodyLocation.isEmpty)
        #expect(viewModel.userNotes.isEmpty)
        #expect(viewModel.patientName.isEmpty)
        #expect(viewModel.patientID.isEmpty)
        #expect(viewModel.saveError == nil)
    }

    @Test
    func savePhotoFailureSetsError() async {
        let coordinator = MockCameraCoordinator()
        coordinator.shouldThrowOnSave = true
        let viewModel = CameraViewModel(coordinator: coordinator)
        viewModel.capturedImage = makeTestImage()

        await viewModel.savePhoto(
            bodyLocation: "",
            userNotes: "",
            patientName: "",
            patientID: ""
        )

        #expect(viewModel.saveError != nil)
        #expect(viewModel.isSaving == false)
    }

    private func makeTestImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
    }
}

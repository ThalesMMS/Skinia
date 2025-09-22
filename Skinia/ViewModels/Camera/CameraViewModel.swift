import SwiftUI
import PhotosUI
import Combine
import AVFoundation
import UIKit

@MainActor
final class CameraViewModel: ObservableObject {
    // MARK: - Published State
    @Published var capturedImage: UIImage?
    @Published var imageMetadata: [String: Any]?
    @Published var showingCamera = false
    @Published var showingPreview = false
    @Published var isSaving = false
    @Published var selectedBodyLocation = ""
    @Published var userNotes = ""
    @Published var patientName = ""
    @Published var patientID = ""
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var isProcessingPhotoSelection = false
    @Published var isLoadingPhoto = false
    @Published var saveError: Error?
    @Published private(set) var canUseCamera: Bool

    // MARK: - Dependencies
    let permissionManager: CameraPermissionManager
    private let coordinator: any CameraCoordinating
    private var cancellables = Set<AnyCancellable>()
    private var hasInitialized = false

    // MARK: - Initialization
    init(
        coordinator: any CameraCoordinating,
        permissionManager: CameraPermissionManager = CameraPermissionManager()
    ) {
        self.coordinator = coordinator
        self.permissionManager = permissionManager
        self.canUseCamera = permissionManager.canUseCamera

        permissionManager.$authorizationStatus
            .map { $0 == .authorized }
            .removeDuplicates()
            .sink { [weak self] isAuthorized in
                self?.canUseCamera = isAuthorized
            }
            .store(in: &cancellables)
    }

    // MARK: - Lifecycle
    func initialize() async {
        guard !hasInitialized else { return }
        hasInitialized = true

        coordinator.start()

        if permissionManager.authorizationStatus == .notDetermined {
            _ = await permissionManager.requestPermission()
        }
    }

    // MARK: - Permission Handling
    func handlePermissionGranted() {
        showingCamera = true
    }

    func handlePermissionDenied() {
        // No-op for now, but keeps interface flexible for future handling
    }

    // MARK: - Camera Actions
    func openCamera() {
        showingCamera = true
    }

    func handleImageCaptured(image: UIImage, metadata: [String: Any]?) {
        capturedImage = image
        imageMetadata = metadata
        showingCamera = false
        showingPreview = true
    }

    func retakePhoto() {
        showingPreview = false
        capturedImage = nil
        imageMetadata = nil
        selectedPhotoItem = nil
    }

    // MARK: - Photo Library
    func handlePhotoSelectionChange(_ newItem: PhotosPickerItem?) {
        guard let newItem else { return }

        Task { @MainActor in
            self.isProcessingPhotoSelection = true
            self.isLoadingPhoto = true

            await self.loadPhotoFromLibrary(newItem)

            self.isProcessingPhotoSelection = false
            try? await Task.sleep(nanoseconds: 100_000_000)
            self.isLoadingPhoto = false
        }
    }

    private func loadPhotoFromLibrary(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                print("Failed to load data from photo library")
                return
            }

            guard let image = UIImage(data: data) else {
                print("Failed to create image from data")
                return
            }

            let resizedImage = resizeImageIfNeeded(image)

            capturedImage = resizedImage
            imageMetadata = nil
            showingPreview = true
            selectedPhotoItem = nil
        } catch {
            print("Error loading photo from library: \(error)")
        }
    }

    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxSize: CGFloat = 2048

        guard image.size.width > maxSize || image.size.height > maxSize else {
            return image
        }

        let scale = min(maxSize / image.size.width, maxSize / image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }

    // MARK: - Saving
    func savePhoto(
        bodyLocation: String,
        userNotes: String,
        patientName: String,
        patientID: String
    ) async {
        selectedBodyLocation = bodyLocation
        self.userNotes = userNotes
        self.patientName = patientName
        self.patientID = patientID

        await performSave()
    }

    func retrySavePhoto() async {
        await performSave()
    }

    private func performSave() async {
        guard let image = capturedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }

        saveError = nil
        isSaving = true

        do {
            let metadata = createPhotoMetadata(from: imageMetadata, imageSize: image.size, dataSize: imageData.count)

            _ = try await coordinator.savePhotoToAnalysisList(
                imageData,
                bodyLocation: selectedBodyLocation.isEmpty ? nil : selectedBodyLocation,
                userNotes: userNotes.isEmpty ? nil : userNotes,
                patientName: patientName.isEmpty ? nil : patientName,
                patientID: patientID.isEmpty ? nil : patientID,
                metadata: metadata
            )

            showingPreview = false
            capturedImage = nil
            imageMetadata = nil
            selectedBodyLocation = ""
            self.userNotes = ""
            self.patientName = ""
            self.patientID = ""
            isSaving = false

            coordinator.navigateToAnalysisList()
        } catch {
            isSaving = false
            saveError = error
        }
    }

    private func createPhotoMetadata(from metadata: [String: Any]?, imageSize: CGSize, dataSize: Int) -> PhotoMetadata {
        PhotoMetadata(
            imageQuality: determineImageQuality(size: imageSize, dataSize: dataSize),
            bodyLocation: selectedBodyLocation.isEmpty ? nil : selectedBodyLocation,
            imageSize: imageSize,
            fileSize: Int64(dataSize),
            hasFlash: extractFlashUsed(from: metadata),
            orientation: extractOrientation(from: metadata)
        )
    }

    private func determineImageQuality(size: CGSize, dataSize: Int) -> ImageQuality {
        let pixelCount = size.width * size.height
        let bytesPerPixel = Double(dataSize) / pixelCount

        if pixelCount >= 2_000_000 && bytesPerPixel > 2.0 {
            return .excellent
        } else if pixelCount >= 1_000_000 && bytesPerPixel > 1.5 {
            return .good
        } else if pixelCount >= 500_000 {
            return .fair
        } else {
            return .poor
        }
    }

    private func extractFlashUsed(from metadata: [String: Any]?) -> Bool {
        guard let metadata,
              let exifDict = metadata["{Exif}"] as? [String: Any],
              let flash = exifDict["Flash"] as? Int else {
            return false
        }
        return flash != 0
    }

    private func extractOrientation(from metadata: [String: Any]?) -> String {
        guard let metadata,
              let orientation = metadata["Orientation"] as? Int else {
            return "portrait"
        }

        switch orientation {
        case 1: return "portrait"
        case 3: return "portrait-upside-down"
        case 6: return "landscape-right"
        case 8: return "landscape-left"
        default: return "portrait"
        }
    }
}

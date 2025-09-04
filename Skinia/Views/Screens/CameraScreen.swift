import SwiftUI
import AVFoundation
import ImageIO
import CoreGraphics

struct CameraScreen: View {
    @StateObject private var coordinator: CameraCoordinator
    @StateObject private var permissionManager = CameraPermissionManager()
    
    @State private var capturedImage: UIImage?
    @State private var imageMetadata: [String: Any]?
    @State private var showingCamera = false
    @State private var showingPreview = false
    @State private var isSaving = false
    @State private var selectedBodyLocation = ""
    @State private var userNotes = ""
    
    init(coordinator: CameraCoordinator) {
        self._coordinator = StateObject(wrappedValue: coordinator)
    }
    
    var body: some View {
        Group {
            if permissionManager.canUseCamera {
                cameraInterface
            } else {
                CameraPermissionView(
                    onPermissionGranted: {
                        permissionManager.authorizationStatus = .authorized
                        showingCamera = true
                    },
                    onPermissionDenied: {
                        // Handle permission denial
                    }
                )
            }
        }
        .navigationTitle("Nova Foto")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                _ = await permissionManager.requestPermission()
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(
                capturedImage: $capturedImage,
                showingImagePicker: $showingCamera,
                onImageCaptured: { image, metadata in
                    capturedImage = image
                    imageMetadata = metadata
                    showingCamera = false
                    showingPreview = true
                }
            )
        }
        .sheet(isPresented: $showingPreview) {
            if let image = capturedImage {
                PhotoPreviewView(
                    image: image,
                    metadata: imageMetadata,
                    onSave: { bodyLocation, notes in
                        selectedBodyLocation = bodyLocation
                        userNotes = notes
                        Task {
                            await savePhoto()
                        }
                    },
                    onRetake: {
                        showingPreview = false
                        showingCamera = true
                    }
                )
            }
        }
    }
    
    private var cameraInterface: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Camera icon and instructions
            VStack(spacing: 20) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)
                
                VStack(spacing: 12) {
                    Text("Capture uma Foto")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("Posicione a lesão de pele no centro da tela para uma melhor análise.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
            
            // Capture button
            Button {
                showingCamera = true
            } label: {
                HStack {
                    Image(systemName: "camera")
                    Text("Abrir Câmera")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .font(.headline)
            }
            .padding(.horizontal)
            
            // Tips section
            VStack(alignment: .leading, spacing: 12) {
                Text("Dicas para uma boa foto:")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 8) {
                    tipRow("Boa iluminação natural", icon: "sun.max")
                    tipRow("Foco na lesão", icon: "viewfinder.circle")
                    tipRow("Evitar sombras", icon: "flashlight.off.fill")
                    tipRow("Câmera estável", icon: "hand.raised")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .overlay(
            Group {
                if isSaving {
                    Color.black.opacity(0.3)
                        .overlay(
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                
                                Text("Salvando foto...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        )
                        .ignoresSafeArea()
                }
            }
        )
    }
    
    private func tipRow(_ text: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private func savePhoto() async {
        guard let image = capturedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        isSaving = true
        
        do {
            // Create metadata
            let metadata = createPhotoMetadata(from: imageMetadata, imageSize: image.size, dataSize: imageData.count)
            
            // Save photo using camera service
            _ = try await coordinator.dependencyContainer.cameraService.savePhoto(
                imageData,
                bodyLocation: selectedBodyLocation.isEmpty ? nil : selectedBodyLocation,
                userNotes: userNotes.isEmpty ? nil : userNotes,
                metadata: metadata
            )
            
            // Reset state
            await MainActor.run {
                showingPreview = false
                capturedImage = nil
                imageMetadata = nil
                selectedBodyLocation = ""
                userNotes = ""
                isSaving = false
            }
            
            // Navigate back to analysis list
            coordinator.navigateToAnalysisList()
            
        } catch {
            await MainActor.run {
                isSaving = false
                // TODO: Show error alert
                print("Error saving photo: \(error)")
            }
        }
    }
    
    private func createPhotoMetadata(from metadata: [String: Any]?, imageSize: CGSize, dataSize: Int) -> PhotoMetadata {
        let photoMetadata = PhotoMetadata(
            imageQuality: determineImageQuality(size: imageSize, dataSize: dataSize),
            bodyLocation: selectedBodyLocation.isEmpty ? nil : selectedBodyLocation,
            imageSize: imageSize,
            fileSize: Int64(dataSize),
            hasFlash: extractFlashUsed(from: metadata),
            orientation: extractOrientation(from: metadata)
        )
        
        return photoMetadata
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
        guard let metadata = metadata,
              let exifDict = metadata["{Exif}"] as? [String: Any],
              let flash = exifDict["Flash"] as? Int else {
            return false
        }
        return flash != 0
    }
    
    private func extractOrientation(from metadata: [String: Any]?) -> String {
        guard let metadata = metadata,
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

#Preview {
    let container = DependencyContainer.shared
    let coordinator = CameraCoordinator(dependencyContainer: container)
    
    NavigationView {
        CameraScreen(coordinator: coordinator)
    }
}
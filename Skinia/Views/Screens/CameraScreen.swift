import SwiftUI
import AVFoundation
import ImageIO
import CoreGraphics
import PhotosUI
import Photos

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
    @State private var patientName = ""
    @State private var patientID = ""
    @State private var showingPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isProcessingPhotoSelection = false
    @State private var isLoadingPhoto = false
    @State private var saveError: Error?

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
                coordinator.start() // Initialize photo library status
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
                    onSave: { bodyLocation, notes, patientNameInput, patientIDInput in
                        selectedBodyLocation = bodyLocation
                        userNotes = notes
                        patientName = patientNameInput
                        patientID = patientIDInput
                        Task {
                            await savePhoto()
                        }
                    },
                    onRetake: {
                        showingPreview = false
                        capturedImage = nil
                        imageMetadata = nil
                        selectedPhotoItem = nil
                        // Don't automatically show camera when closing preview
                    }
                )
            }
        }
        .alert(
            "Não foi possível salvar a foto",
            isPresented: Binding(
                get: { saveError != nil },
                set: { isPresented in
                    if !isPresented {
                        saveError = nil
                    }
                }
            )
        ) {
            Button("Tentar novamente") {
                let errorExists = saveError != nil
                saveError = nil
                if errorExists {
                    Task {
                        await savePhoto()
                    }
                }
            }
            Button("Cancelar", role: .cancel) {
                saveError = nil
            }
        } message: {
            Text("Ocorreu um problema ao salvar sua foto. Verifique sua conexão e tente novamente.")
        }
    }
    
    private var cameraInterface: some View {
        ScrollView {
            VStack(spacing: 30) {
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
                .padding(.top, 20)
                
                // Action buttons
                VStack(spacing: 12) {
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
                        .background(DesignSystem.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .font(.headline)
                    }
                    
                    // Photo library button
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Escolher da Galeria")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.Colors.backgroundSecondary)
                        .foregroundColor(DesignSystem.Colors.primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .stroke(DesignSystem.Colors.primary, lineWidth: 1)
                        )
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .font(.headline)
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let newItem = newItem {
                                isProcessingPhotoSelection = true
                                isLoadingPhoto = true
                                await loadPhotoFromLibrary(newItem)
                                isProcessingPhotoSelection = false
                                // Small delay to ensure smooth transition
                                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                                isLoadingPhoto = false
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Tips section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dicas para uma boa análise:")
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        tipRow("Boa iluminação natural", icon: "sun.max")
                        tipRow("Foco claro na lesão", icon: "viewfinder.circle")
                        tipRow("Evitar sombras", icon: "flashlight.off.fill")
                        tipRow("Imagem nítida e estável", icon: "hand.raised")
                        tipRow("Pode usar fotos existentes", icon: "photo.on.rectangle")
                    }
                }
                .padding(DesignSystem.Spacing.lg)
                .cardStyle()
                .padding(.horizontal)
                
                Spacer(minLength: 50)
            }
        }
        .overlay(
            Group {
                if isSaving || isLoadingPhoto {
                    Color.black.opacity(0.3)
                        .overlay(
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)
                                
                                Text(isLoadingPhoto ? "Processando foto..." : "Salvando foto...")
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
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 20)
            
            Text(text)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.text)
            
            Spacer()
        }
    }
    
    private func loadPhotoFromLibrary(_ item: PhotosPickerItem) async {
        do {
            // Load image data
            guard let data = try await item.loadTransferable(type: Data.self) else {
                print("Failed to load data from photo library")
                await MainActor.run {
                    isLoadingPhoto = false
                }
                return
            }
            
            // Create image from data
            guard let image = UIImage(data: data) else {
                print("Failed to create image from data")
                await MainActor.run {
                    isLoadingPhoto = false
                }
                return
            }
            
            // Resize image if it's too large to improve performance
            let resizedImage = resizeImageIfNeeded(image)
            
            await MainActor.run {
                capturedImage = resizedImage
                imageMetadata = nil // Photo library images don't have camera metadata
                showingPreview = true
                selectedPhotoItem = nil
            }
        } catch {
            print("Error loading photo from library: \(error)")
            await MainActor.run {
                isLoadingPhoto = false
            }
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
    
    private func savePhoto() async {
        guard let image = capturedImage,
              let imageData = image.jpegData(compressionQuality: 0.8) else {
            return
        }
        
        isSaving = true
        
        do {
            // Create metadata
            let metadata = createPhotoMetadata(from: imageMetadata, imageSize: image.size, dataSize: imageData.count)
            
            // Save photo using coordinator with patient info
            _ = try await coordinator.savePhotoToAnalysisList(
                imageData,
                bodyLocation: selectedBodyLocation.isEmpty ? nil : selectedBodyLocation,
                userNotes: userNotes.isEmpty ? nil : userNotes,
                patientName: patientName.isEmpty ? nil : patientName,
                patientID: patientID.isEmpty ? nil : patientID,
                metadata: metadata
            )
            
            // Reset state
            await MainActor.run {
                showingPreview = false
                capturedImage = nil
                imageMetadata = nil
                selectedBodyLocation = ""
                userNotes = ""
                patientName = ""
                patientID = ""
                isSaving = false
            }
            
            // Navigate back to analysis list
            coordinator.navigateToAnalysisList()
            
        } catch {
            await MainActor.run {
                isSaving = false
                saveError = error
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
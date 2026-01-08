import SwiftUI

struct CameraScreen: View {
    @StateObject private var viewModel: CameraViewModel

    init(viewModel: CameraViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.canUseCamera {
                cameraInterface
            } else {
                CameraPermissionView(
                    permissionManager: viewModel.permissionManager,
                    onPermissionGranted: {
                        viewModel.handlePermissionGranted()
                    },
                    onPermissionDenied: {
                        viewModel.handlePermissionDenied()
                    }
                )
            }
        }
        .navigationTitle("Nova Foto")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.initialize()
        }
        .sheet(isPresented: $viewModel.showingCamera) {
            CameraView(
                capturedImage: $viewModel.capturedImage,
                showingImagePicker: $viewModel.showingCamera
            ) { image, metadata in
                viewModel.handleImageCaptured(image: image, metadata: metadata)
            }
        }
        .sheet(isPresented: $viewModel.showingPreview) {
            if let image = viewModel.capturedImage {
                PhotoPreviewView(
                    image: image,
                    metadata: viewModel.imageMetadata,
                    onSave: { bodyLocation, notes, patientName, patientID in
                        Task {
                            await viewModel.savePhoto(
                                bodyLocation: bodyLocation,
                                userNotes: notes,
                                patientName: patientName,
                                patientID: patientID
                            )
                        }
                    },
                    onRetake: {
                        viewModel.retakePhoto()
                    }
                )
            }
        }
        .saveErrorAlert(error: $viewModel.saveError) {
            Task {
                await viewModel.retrySavePhoto()
            }
        }
    }

    private var cameraInterface: some View {
        ScrollView {
            VStack(spacing: 30) {
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

                VStack(spacing: 12) {
                    CameraCaptureControls(onOpenCamera: viewModel.openCamera)

                    PhotoLibraryImporter(
                        selection: $viewModel.selectedPhotoItem,
                        isProcessing: viewModel.isProcessingPhotoSelection,
                        onSelection: viewModel.handlePhotoSelectionChange
                    )
                }
                .padding(.horizontal)

                CaptureTipsSection()
                    .padding(.horizontal)

                Spacer(minLength: 50)
            }
        }
        .overlay(
            Group {
                if viewModel.isSaving || viewModel.isLoadingPhoto {
                    Color.black.opacity(0.3)
                        .overlay(
                            VStack(spacing: 16) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.5)

                                Text(viewModel.isLoadingPhoto ? "Processando foto..." : "Salvando foto...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        )
                        .ignoresSafeArea()
                }
            }
        )
    }
}

#Preview {
    let container = DependencyContainer.shared
    let coordinator = CameraCoordinator(dependencyContainer: container)

    NavigationView {
        CameraScreen(viewModel: CameraViewModel(coordinator: coordinator))
    }
}

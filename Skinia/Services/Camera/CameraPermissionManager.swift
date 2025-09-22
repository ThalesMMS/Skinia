import AVFoundation
import UIKit
import SwiftUI

@MainActor
final class CameraPermissionManager: ObservableObject {
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var showingPermissionAlert = false
    
    init() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestPermission() async -> Bool {
        switch authorizationStatus {
        case .authorized:
            return true
            
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            }
            return granted
            
        case .denied, .restricted:
            await MainActor.run {
                showingPermissionAlert = true
            }
            return false
            
        @unknown default:
            return false
        }
    }
    
    var permissionDescription: String {
        switch authorizationStatus {
        case .authorized:
            return "Câmera autorizada"
        case .notDetermined:
            return "Permissão da câmera não solicitada"
        case .denied:
            return "Permissão da câmera negada"
        case .restricted:
            return "Câmera restrita por política do dispositivo"
        @unknown default:
            return "Status de permissão desconhecido"
        }
    }
    
    var canUseCamera: Bool {
        authorizationStatus == .authorized
    }
}

struct CameraPermissionView: View {
    @ObservedObject private var permissionManager: CameraPermissionManager
    let onPermissionGranted: () -> Void
    let onPermissionDenied: () -> Void

    init(
        permissionManager: CameraPermissionManager = CameraPermissionManager(),
        onPermissionGranted: @escaping () -> Void,
        onPermissionDenied: @escaping () -> Void
    ) {
        self._permissionManager = ObservedObject(wrappedValue: permissionManager)
        self.onPermissionGranted = onPermissionGranted
        self.onPermissionDenied = onPermissionDenied
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Camera icon
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Permissão da Câmera")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text("O Skinia precisa de acesso à câmera para capturar fotos das lesões de pele.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                Button {
                    Task {
                        let granted = await permissionManager.requestPermission()
                        if granted {
                            onPermissionGranted()
                        } else {
                            onPermissionDenied()
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "camera")
                        Text("Permitir Acesso à Câmera")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                if permissionManager.authorizationStatus == .denied {
                    Button {
                        openSettings()
                    } label: {
                        HStack {
                            Image(systemName: "gear")
                            Text("Abrir Configurações")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .alert("Permissão Necessária", isPresented: $permissionManager.showingPermissionAlert) {
            Button("Cancelar", role: .cancel) {
                onPermissionDenied()
            }
            Button("Configurações") {
                openSettings()
            }
        } message: {
            Text("Para capturar fotos, é necessário permitir o acesso à câmera nas configurações do app.")
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}
import SwiftUI

struct CameraCaptureControls: View {
    let onOpenCamera: () -> Void

    var body: some View {
        Button(action: onOpenCamera) {
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
    }
}

#Preview {
    CameraCaptureControls(onOpenCamera: {})
        .padding()
        .background(Color.gray.opacity(0.1))
}

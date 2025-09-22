import SwiftUI
import PhotosUI

struct PhotoLibraryImporter: View {
    @Binding var selection: PhotosPickerItem?
    let isProcessing: Bool
    let onSelection: (PhotosPickerItem?) -> Void

    var body: some View {
        PhotosPicker(
            selection: $selection,
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
        .disabled(isProcessing)
        .onChange(of: selection) { _, newValue in
            onSelection(newValue)
        }
    }
}

import SwiftUI

struct AnalysisMetadataSectionView: View {
    let metadata: PhotoMetadata

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Informações Técnicas")
                .font(.headline)

            VStack(spacing: 8) {
                metadataRow(label: "Qualidade", value: metadata.imageQuality.rawValue.capitalized)
                metadataRow(label: "Dispositivo", value: metadata.deviceInfo)
                metadataRow(label: "Orientação", value: metadata.orientation.capitalized)
                metadataRow(label: "Dimensões", value: metadata.imageDimensions)
                metadataRow(label: "Tamanho", value: metadata.fileSizeFormatted)

                if let bodyLocation = metadata.bodyLocation {
                    metadataRow(label: "Local do Corpo", value: bodyLocation)
                }
            }
        }
        .padding()
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(12)
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

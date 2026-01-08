import SwiftUI

struct CaptureTipsSection: View {
    var body: some View {
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
}

#Preview {
    CaptureTipsSection()
        .padding()
}

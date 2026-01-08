import SwiftUI

struct AnalysisPatientInfoSectionView: View {
    let photo: SkinLesionPhoto

    var body: some View {
        Group {
            if let bodyLocation = photo.metadata?.bodyLocation {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Local da Lesão")
                            .font(DesignSystem.Typography.medicalCaption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(bodyLocation)
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.text)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Data da Captura")
                            .font(DesignSystem.Typography.medicalCaption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        Text(photo.formattedCaptureDate)
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.text)
                    }
                }
                .padding(DesignSystem.Spacing.md)
                .cardStyle()
            }
        }
    }
}

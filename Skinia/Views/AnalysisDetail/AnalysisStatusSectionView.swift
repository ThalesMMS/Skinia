import SwiftUI

struct AnalysisStatusSectionView: View {
    let status: AnalysisStatus
    let captureDate: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                StatusBadge(status: status)
                Spacer()
                Text(captureDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(description)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding()
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(12)
    }
}

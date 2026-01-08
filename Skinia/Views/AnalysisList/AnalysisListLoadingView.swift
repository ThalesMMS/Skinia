import SwiftUI

struct AnalysisListLoadingView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            PulsatingCircle(
                color: DesignSystem.Colors.primary,
                size: 60
            )

            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("Carregando análises...")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)

                LoadingDots()
            }

            VStack(spacing: DesignSystem.Spacing.md) {
                ForEach(0..<3) { _ in
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            SkeletonLoader(height: 60, cornerRadius: DesignSystem.CornerRadius.sm)
                                .frame(width: 60)

                            VStack(spacing: DesignSystem.Spacing.xs) {
                                SkeletonLoader(height: 16)
                                SkeletonLoader(height: 12)
                                SkeletonLoader(height: 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .cardStyle()
                }
            }
            .padding(.top, DesignSystem.Spacing.lg)
        }
        .padding(DesignSystem.Spacing.lg)
    }
}

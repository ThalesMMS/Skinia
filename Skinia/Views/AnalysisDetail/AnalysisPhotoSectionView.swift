import SwiftUI

struct AnalysisPhotoSectionView: View {
    let photo: SkinLesionPhoto
    @Binding var showingFullScreenImage: Bool

    var body: some View {
        Group {
            if let image = photo.fullImage {
                let aspectRatio = safeAspectRatio(from: image.size)
                let optimalHeight = calculateOptimalHeight(for: aspectRatio)

                Button {
                    showingFullScreenImage = true
                    HapticManager.shared.impact(.light)
                } label: {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(aspectRatio, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: optimalHeight)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                        .designShadow(DesignSystem.Shadows.medium)
                        .overlay(alignment: .topTrailing) {
                            HStack(spacing: 4) {
                                Image(systemName: "viewfinder")
                                    .font(.caption2)
                                Text("Tocar para ampliar")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .padding(8)
                        }
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.backgroundSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(DesignSystem.Colors.textTertiary)

                            Text("Imagem não disponível")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                        }
                    }
                    .designShadow(DesignSystem.Shadows.small)
            }
        }
    }

    private func safeAspectRatio(from size: CGSize) -> CGFloat {
        guard size.width > 0, size.height > 0,
              size.width.isFinite, size.height.isFinite,
              !size.width.isNaN, !size.height.isNaN else {
            return 1.0
        }

        let ratio = size.width / size.height

        guard ratio.isFinite, !ratio.isNaN, ratio > 0 else {
            return 1.0
        }

        return min(max(ratio, 0.2), 5.0)
    }

    private func calculateOptimalHeight(for aspectRatio: CGFloat) -> CGFloat {
        let minHeight: CGFloat = 180
        let maxHeight: CGFloat = 400
        let targetHeight: CGFloat = 280

        guard aspectRatio.isFinite, !aspectRatio.isNaN, aspectRatio > 0 else {
            return targetHeight
        }

        if aspectRatio > 2.0 {
            return max(minHeight, targetHeight * 0.6)
        } else if aspectRatio < 0.75 {
            return min(maxHeight, targetHeight * 1.3)
        } else {
            return targetHeight
        }
    }
}

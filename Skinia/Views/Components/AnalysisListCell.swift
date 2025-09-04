import SwiftUI

struct AnalysisListCell: View {
    let photo: SkinLesionPhoto
    let onTap: () -> Void
    
    @Environment(\.analysisService) private var analysisService
    
    var body: some View {
        Button(action: {
            print("🔘 Card tapped for photo: \(photo.id)")
            HapticManager.shared.impact(.light)
            onTap()
        }) {
            VStack(spacing: DesignSystem.Spacing.md) {
                // Header with title and date
                HStack(alignment: .top) {
                    // Title on the left
                    if let bodyLocation = photo.metadata?.bodyLocation {
                        Text(bodyLocation)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if let userNotes = photo.userNotes {
                        Text(userNotes)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(2)
                    } else {
                        Text("Análise de Lesão")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Date and attention icon
                    HStack(spacing: 6) {
                        if photo.needsAttention {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Text(photo.shortCaptureDate)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .fixedSize()
                    }
                }
                
                // Main content row with thumbnail and info
                HStack(spacing: DesignSystem.Spacing.md) {
                    // Thumbnail image
                    AsyncImage(data: photo.imageData) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(DesignSystem.Colors.backgroundSecondary)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                                    .font(DesignSystem.Typography.title3)
                            }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    .designShadow(DesignSystem.Shadows.small)
                    
                    // Content info
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        // Status badge
                        HStack {
                            StatusBadge(status: photo.analysisStatus)
                            Spacer()
                        }
                        
                        // Analysis result or progress
                        if let result = photo.analysisResult {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    RiskBadge(riskLevel: result.riskLevel)
                                    Spacer()
                                    Text(result.confidencePercentage)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(result.lesionType)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        } else if photo.analysisStatus == .uploading || photo.analysisStatus == .analyzing {
                            CompactAnalysisProgressIndicator(photo: photo, analysisService: analysisService)
                        } else {
                            Text("Aguardando análise...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Chevron indicator
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption2)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.lg)
            .designShadow(DesignSystem.Shadows.card)
            .contentShape(Rectangle())
        }
        .buttonStyle(CardButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Toque para ver detalhes da análise")
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(photo.needsAttention ? .isSelected : [])
    }
    
    private var accessibilityDescription: String {
        var description = "Análise de lesão"
        
        // Add location or notes
        if let bodyLocation = photo.metadata?.bodyLocation {
            description += " em \(bodyLocation)"
        } else if let userNotes = photo.userNotes, !userNotes.isEmpty {
            description += ": \(userNotes)"
        }
        
        // Add status
        description += ". Status: \(photo.analysisStatus.displayName)"
        
        // Add results if available
        if let result = photo.analysisResult {
            description += ". Tipo: \(result.lesionType). Risco: \(result.riskLevel.displayName). Confiança: \(result.confidencePercentage)"
        }
        
        // Add date
        description += ". Capturada em \(photo.formattedCaptureDate)"
        
        // Add attention warning
        if photo.needsAttention {
            description += ". Atenção requerida"
        }
        
        return description
    }
}

// MARK: - Supporting Views

struct StatusBadge: View {
    let status: AnalysisStatus
    @State private var isPressed = false
    @State private var pulseAnimation = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: status.systemImage)
                .font(DesignSystem.Typography.caption2)
                .imageScale(.small)
                .scaleEffect(shouldPulse ? (pulseAnimation ? 1.2 : 1.0) : 1.0)
                .animation(
                    shouldPulse ? 
                    Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : 
                    .none, 
                    value: pulseAnimation
                )
            
            Text(status.displayName)
                .font(DesignSystem.Typography.medicalCaption)
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, DesignSystem.Spacing.sm + 2)
        .padding(.vertical, DesignSystem.Spacing.xs + 1)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.badge))
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(DesignSystem.Animations.quick, value: isPressed)
        .designShadow(shouldPulse ? DesignSystem.Shadows.medium : DesignSystem.Shadows.small)
        .onAppear {
            if shouldPulse {
                pulseAnimation = true
            }
        }
        .onTapGesture {
            withAnimation(DesignSystem.Animations.quick) {
                isPressed = true
            }
            HapticManager.shared.impact(.light)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignSystem.Animations.quick) {
                    isPressed = false
                }
            }
        }
    }
    
    private var shouldPulse: Bool {
        status == .uploading || status == .analyzing
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending:
            return DesignSystem.Colors.textTertiary.opacity(0.15)
        case .uploading:
            return DesignSystem.Colors.info.opacity(0.15)
        case .analyzing:
            return DesignSystem.Colors.warning.opacity(0.15)
        case .completed:
            return DesignSystem.Colors.success.opacity(0.15)
        case .failed:
            return DesignSystem.Colors.error.opacity(0.15)
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .pending:
            return DesignSystem.Colors.textSecondary
        case .uploading:
            return DesignSystem.Colors.info
        case .analyzing:
            return DesignSystem.Colors.warning
        case .completed:
            return DesignSystem.Colors.success
        case .failed:
            return DesignSystem.Colors.error
        }
    }
}

struct RiskBadge: View {
    let riskLevel: RiskLevel
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: riskLevel.systemImage)
                .font(DesignSystem.Typography.caption2)
                .imageScale(.small)
            
            Text(riskLevel.displayName)
                .font(DesignSystem.Typography.medicalCaption)
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, DesignSystem.Spacing.sm + 2)
        .padding(.vertical, DesignSystem.Spacing.xs + 1)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.badge))
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(DesignSystem.Animations.quick, value: isPressed)
        .designShadow(DesignSystem.Shadows.small)
        .onTapGesture {
            withAnimation(DesignSystem.Animations.quick) {
                isPressed = true
            }
            HapticManager.shared.impact(.light)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignSystem.Animations.quick) {
                    isPressed = false
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        switch riskLevel {
        case .low:
            return DesignSystem.Colors.riskLowBackground
        case .moderate:
            return DesignSystem.Colors.riskModerateBackground
        case .high:
            return DesignSystem.Colors.riskHighBackground
        case .urgent:
            return DesignSystem.Colors.riskUrgentBackground
        }
    }
    
    private var foregroundColor: Color {
        switch riskLevel {
        case .low:
            return DesignSystem.Colors.riskLow
        case .moderate:
            return DesignSystem.Colors.riskModerate
        case .high:
            return DesignSystem.Colors.riskHigh
        case .urgent:
            return DesignSystem.Colors.riskUrgent
        }
    }
}

// MARK: - AsyncImage Helper

private struct AsyncImage<Content: View, Placeholder: View>: View {
    let data: Data
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    var body: some View {
        if let uiImage = UIImage(data: data) {
            content(Image(uiImage: uiImage))
        } else {
            placeholder()
        }
    }
}

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    List {
        AnalysisListCell(
            photo: SkinLesionPhoto(
                imageData: Data(),
                analysisStatus: .completed
            )
        ) {
            // Action
        }
        
        AnalysisListCell(
            photo: SkinLesionPhoto(
                imageData: Data(),
                analysisStatus: .pending
            )
        ) {
            // Action
        }
    }
}
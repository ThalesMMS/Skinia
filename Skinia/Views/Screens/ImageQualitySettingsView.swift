import SwiftUI

struct ImageQualitySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("imageQuality") private var imageQualityRaw = CaptureImageQuality.high.rawValue
    @AppStorage("compressionEnabled") private var compressionEnabled = true
    @AppStorage("compressionQuality") private var compressionQuality = 0.8
    @AppStorage("maxImageSize") private var maxImageSize = MaxImageSize.large.rawValue
    @AppStorage("autoOptimization") private var autoOptimization = true
    
    private var imageQuality: CaptureImageQuality {
        get { CaptureImageQuality(rawValue: imageQualityRaw) ?? .high }
        set { imageQualityRaw = newValue.rawValue }
    }
    
    private var maxImageSizeEnum: MaxImageSize {
        get { MaxImageSize(rawValue: maxImageSize) ?? .large }
        set { maxImageSize = newValue.rawValue }
    }
    
    var body: some View {
        NavigationView {
            List {
                // Quality Overview Section
                Section {
                    QualityOverviewCard(
                        imageQuality: imageQuality,
                        compressionEnabled: compressionEnabled,
                        maxImageSize: maxImageSizeEnum
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                }
                
                // Image Quality Settings
                Section("Qualidade da Imagem") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Resolução da Captura")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.text)
                        
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            ForEach(CaptureImageQuality.allCases, id: \.self) { quality in
                                QualityOption(
                                    quality: quality,
                                    isSelected: imageQuality == quality
                                ) {
                                    imageQualityRaw = quality.rawValue
                                    HapticManager.shared.selection()
                                }
                            }
                        }
                    }
                }
                
                // Compression Settings
                Section("Compressão e Otimização") {
                    Toggle(isOn: $compressionEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Compressão Inteligente")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.Colors.text)
                            
                            Text("Reduz o tamanho sem perder qualidade essencial")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primary))
                    
                    if compressionEnabled {
                        CompressionQualitySlider(compressionQuality: $compressionQuality)
                    }
                    
                    Toggle(isOn: $autoOptimization) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Otimização Automática")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.Colors.text)
                            
                            Text("Ajusta automaticamente baseado na conexão")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primary))
                }
                
                // Size Limits
                Section("Limite de Tamanho") {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Tamanho Máximo")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.text)
                        
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            ForEach(MaxImageSize.allCases, id: \.self) { size in
                                SizeOption(
                                    size: size,
                                    isSelected: maxImageSizeEnum == size
                                ) {
                                    maxImageSize = size.rawValue
                                    HapticManager.shared.selection()
                                }
                            }
                        }
                    }
                }
                
                // Recommendations
                Section("Recomendações") {
                    RecommendationRow(
                        icon: "lightbulb",
                        iconColor: DesignSystem.Colors.warning,
                        title: "Para Melhor Análise",
                        subtitle: "Use qualidade 'Alta' com compressão moderada para equilibrar qualidade e velocidade de upload."
                    )
                    
                    RecommendationRow(
                        icon: "wifi",
                        iconColor: DesignSystem.Colors.info,
                        title: "Conexão Lenta",
                        subtitle: "Ative a otimização automática para ajustar a qualidade baseada na sua conexão de internet."
                    )
                    
                    RecommendationRow(
                        icon: "internaldrive",
                        iconColor: DesignSystem.Colors.success,
                        title: "Armazenamento",
                        subtitle: "Imagens de alta qualidade ocupam mais espaço no dispositivo. Considere a compressão se o espaço for limitado."
                    )
                }
            }
            .navigationTitle("Qualidade da Imagem")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Models

enum CaptureImageQuality: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case maximum = "maximum"
    
    var title: String {
        switch self {
        case .low: return "Baixa"
        case .medium: return "Média"
        case .high: return "Alta"
        case .maximum: return "Máxima"
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Mais rápida, menor qualidade"
        case .medium: return "Equilíbrio entre qualidade e velocidade"
        case .high: return "Boa qualidade, recomendado"
        case .maximum: return "Máxima qualidade, mais lenta"
        }
    }
    
    var resolution: String {
        switch self {
        case .low: return "1280x720"
        case .medium: return "1920x1080"
        case .high: return "2560x1440"
        case .maximum: return "4096x2304"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return DesignSystem.Colors.error
        case .medium: return DesignSystem.Colors.warning
        case .high: return DesignSystem.Colors.success
        case .maximum: return DesignSystem.Colors.primary
        }
    }
    
    var recommendedFor: String {
        switch self {
        case .low: return "Conexões muito lentas"
        case .medium: return "Uso geral"
        case .high: return "Análises precisas (recomendado)"
        case .maximum: return "Máxima precisão"
        }
    }
}

enum MaxImageSize: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    case unlimited = "unlimited"
    
    var title: String {
        switch self {
        case .small: return "Pequeno"
        case .medium: return "Médio"
        case .large: return "Grande"
        case .unlimited: return "Sem Limite"
        }
    }
    
    var size: String {
        switch self {
        case .small: return "2 MB"
        case .medium: return "5 MB"
        case .large: return "10 MB"
        case .unlimited: return "Ilimitado"
        }
    }
    
    var description: String {
        switch self {
        case .small: return "Upload mais rápido"
        case .medium: return "Boa qualidade, tamanho moderado"
        case .large: return "Alta qualidade (recomendado)"
        case .unlimited: return "Sem restrição de tamanho"
        }
    }
}

// MARK: - Quality Overview Card

struct QualityOverviewCard: View {
    let imageQuality: CaptureImageQuality
    let compressionEnabled: Bool
    let maxImageSize: MaxImageSize
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "photo.badge.checkmark")
                    .font(.system(size: 28))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Text("Configuração Atual")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                OverviewItem(
                    title: "Qualidade",
                    value: imageQuality.title,
                    detail: imageQuality.resolution,
                    color: imageQuality.color
                )
                
                OverviewItem(
                    title: "Compressão",
                    value: compressionEnabled ? "Ativada" : "Desativada",
                    detail: compressionEnabled ? "Otimizada para análise" : "Sem compressão",
                    color: compressionEnabled ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary
                )
                
                OverviewItem(
                    title: "Tamanho Máximo",
                    value: maxImageSize.title,
                    detail: maxImageSize.size,
                    color: DesignSystem.Colors.primary
                )
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.card)
        .designShadow(DesignSystem.Shadows.card)
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }
}

struct OverviewItem: View {
    let title: String
    let value: String
    let detail: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(value)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Text(detail)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

// MARK: - Quality Option

struct QualityOption: View {
    let quality: CaptureImageQuality
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(quality.title)
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.text)
                        
                        Spacer()
                        
                        Text(quality.resolution)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(quality.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(quality.color.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Text(quality.description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text("Recomendado para: \(quality.recommendedFor)")
                        .font(DesignSystem.Typography.caption2)
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                        .italic()
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Size Option

struct SizeOption: View {
    let size: MaxImageSize
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(size.title)
                            .font(DesignSystem.Typography.callout)
                            .fontWeight(.medium)
                            .foregroundColor(DesignSystem.Colors.text)
                        
                        Spacer()
                        
                        Text(size.size)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.primary)
                            .fontWeight(.medium)
                    }
                    
                    Text(size.description)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Compression Quality Slider

struct CompressionQualitySlider: View {
    @Binding var compressionQuality: Double
    
    private var qualityText: String {
        switch compressionQuality {
        case 0.0..<0.4: return "Baixa"
        case 0.4..<0.7: return "Média"
        case 0.7..<0.9: return "Alta"
        default: return "Máxima"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .frame(width: 24)
                
                Text("Nível de Compressão")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.Colors.text)
                
                Spacer()
                
                Text(qualityText)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Mais compressão")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                
                Slider(value: $compressionQuality, in: 0.1...1.0)
                    .tint(DesignSystem.Colors.primary)
                
                Text("Menos compressão")
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(.leading, 38) // Align with text above
        }
    }
}

// MARK: - Recommendation Row

struct RecommendationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24)
                .padding(.top, 1)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.text)
                
                Text(subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    ImageQualitySettingsView()
}
import SwiftUI

// MARK: - Accessibility Helpers

extension View {
    // Enhanced accessibility label
    func accessibilityLabel(title: String, description: String? = nil) -> some View {
        let fullLabel = description != nil ? "\(title). \(description!)" : title
        return self.accessibilityLabel(fullLabel)
    }
    
    // Smart accessibility traits for interactive elements
    func smartAccessibilityTraits(isButton: Bool = false, isSelected: Bool = false, isDisabled: Bool = false) -> some View {
        var traits: AccessibilityTraits = []
        
        if isButton { traits.insert(.isButton) }
        if isSelected { traits.insert(.isSelected) }
        // Note: .notEnabled doesn't exist in SwiftUI, disabled state is handled differently
        
        return self.accessibilityAddTraits(traits)
    }
    
    // Medical data accessibility - important for health information
    func medicalAccessibility(
        title: String,
        value: String? = nil,
        importance: MedicalImportance = .normal,
        additionalInfo: String? = nil
    ) -> some View {
        var label = title
        if let value = value {
            label += ". \(value)"
        }
        if let additionalInfo = additionalInfo {
            label += ". \(additionalInfo)"
        }
        
        return self
            .accessibilityLabel(label)
            .accessibilityAddTraits(importance == .critical ? .isStaticText : [])
    }
    
    // Progress accessibility
    func progressAccessibility(current: Double, total: Double = 1.0, description: String) -> some View {
        let percentage = Int((current / total) * 100)
        return self
            .accessibilityLabel("\(description)")
            .accessibilityValue("\(percentage) por cento concluído")
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    // Risk level accessibility
    func riskAccessibility(_ riskLevel: RiskLevel) -> some View {
        let urgencyDescription = riskLevel.accessibilityDescription
        return self
            .accessibilityLabel("Nível de risco: \(riskLevel.displayName)")
            .accessibilityHint(urgencyDescription)
    }
    
    // Status accessibility with dynamic updates
    func statusAccessibility(_ status: AnalysisStatus) -> some View {
        let statusDescription = status.accessibilityDescription
        return self
            .accessibilityLabel("Status da análise: \(status.displayName)")
            .accessibilityValue(statusDescription)
            .accessibilityAddTraits(status.isInProgress ? .updatesFrequently : [])
    }
    
    // Reduce motion sensitivity
    func motionSensitiveAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V
    ) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            return self.animation(.none, value: value)
        } else {
            return self.animation(animation, value: value)
        }
    }
    
    // High contrast support
    func adaptiveColors(
        normal: Color,
        highContrast: Color? = nil
    ) -> some View {
        let color = UIAccessibility.isDarkerSystemColorsEnabled ? 
                   (highContrast ?? normal) : normal
        return self.foregroundColor(color)
    }
    
    // Large text support
    func scalableFont(_ font: Font, minimumScale: CGFloat = 0.8) -> some View {
        self.font(font)
            .lineLimit(nil)
            .minimumScaleFactor(minimumScale)
    }
}

// MARK: - Medical Importance Enum

enum MedicalImportance {
    case normal
    case important
    case critical
}

// MARK: - Accessibility Extensions

extension RiskLevel {
    var accessibilityDescription: String {
        switch self {
        case .low:
            return "Baixo risco. Continue monitoramento regular."
        case .moderate:
            return "Risco moderado. Considere consulta dermatológica."
        case .high:
            return "Alto risco. Consulta dermatológica recomendada em breve."
        case .urgent:
            return "Risco urgente. Procure atendimento médico imediatamente."
        }
    }
}

extension AnalysisStatus {
    var accessibilityDescription: String {
        switch self {
        case .pending:
            return "Aguardando início da análise"
        case .uploading:
            return "Enviando imagem para análise"
        case .analyzing:
            return "Analisando imagem com inteligência artificial"
        case .completed:
            return "Análise concluída com sucesso"
        case .failed:
            return "Análise falhou. Tente novamente."
        }
    }
    
    var isInProgress: Bool {
        switch self {
        case .uploading, .analyzing:
            return true
        case .pending, .completed, .failed:
            return false
        }
    }
}

// MARK: - VoiceOver Helpers

class VoiceOverHelper {
    static let shared = VoiceOverHelper()
    
    private init() {}
    
    func announce(_ message: String, priority: UIAccessibility.Notification = .announcement) {
        DispatchQueue.main.async {
            UIAccessibility.post(notification: priority, argument: message)
        }
    }
    
    func announceAnalysisComplete(lesionType: String, riskLevel: RiskLevel, confidence: Double) {
        let confidencePercentage = Int(confidence * 100)
        let message = """
        Análise concluída. 
        Tipo de lesão: \(lesionType). 
        Nível de risco: \(riskLevel.displayName). 
        Confiança: \(confidencePercentage) por cento. 
        \(riskLevel.accessibilityDescription)
        """
        announce(message, priority: .announcement)
    }
    
    func announceAnalysisStarted() {
        announce("Iniciando análise da imagem. Aguarde.", priority: .announcement)
    }
    
    func announceAnalysisFailed() {
        announce("Análise falhou. Verifique sua conexão e tente novamente.", priority: .announcement)
    }
    
    func announcePhotoDeleted() {
        announce("Foto excluída.", priority: .announcement)
    }
    
    func announceSelectionMode(enabled: Bool) {
        let message = enabled ? "Modo de seleção ativado. Toque nas fotos para selecioná-las." : 
                               "Modo de seleção desativado."
        announce(message, priority: .announcement)
    }
}

// MARK: - Dynamic Type Support

struct DynamicTypeHelper {
    static func preferredFont(for textStyle: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> Font {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
        let font = UIFont.systemFont(ofSize: descriptor.pointSize, weight: weight)
        return Font(font)
    }
    
    static func scaledValue(baseValue: CGFloat, textStyle: UIFont.TextStyle = .body) -> CGFloat {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: textStyle)
        let scaleFactor = descriptor.pointSize / UIFont.systemFont(ofSize: 17).pointSize
        return baseValue * scaleFactor
    }
}

// MARK: - Accessible Button Style

struct AccessibleButtonStyle: ButtonStyle {
    let isDestructive: Bool
    let isDisabled: Bool
    
    init(isDestructive: Bool = false, isDisabled: Bool = false) {
        self.isDestructive = isDestructive
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isDisabled ? 0.6 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.Animations.quick, value: configuration.isPressed)
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(isDisabled ? [] : [])
            .accessibilityHint(
                isDestructive ? "Esta ação é destrutiva e não pode ser desfeita." : ""
            )
    }
}

// MARK: - Color Contrast Helpers

extension Color {
    // Calculate luminance for contrast checking
    private var luminance: Double {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let r = components[0]
        let g = components[1]
        let b = components[2]
        
        let linearR = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4)
        let linearG = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4)
        let linearB = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4)
        
        return 0.2126 * linearR + 0.7152 * linearG + 0.0722 * linearB
    }
    
    // Check if color combination meets WCAG AA contrast ratio (4.5:1)
    func hasAccessibleContrast(with backgroundColor: Color) -> Bool {
        let foregroundLuminance = self.luminance
        let backgroundLuminance = backgroundColor.luminance
        
        let lightest = max(foregroundLuminance, backgroundLuminance)
        let darkest = min(foregroundLuminance, backgroundLuminance)
        
        let contrastRatio = (lightest + 0.05) / (darkest + 0.05)
        return contrastRatio >= 4.5
    }
    
    // Get high contrast version of color if needed
    func accessibleVersion(on backgroundColor: Color) -> Color {
        if hasAccessibleContrast(with: backgroundColor) {
            return self
        }
        
        // If contrast is insufficient, return a high contrast alternative
        return backgroundColor.luminance > 0.5 ? .black : .white
    }
}

#if DEBUG
// MARK: - Accessibility Testing Helpers

struct AccessibilityPreviewHelper {
    static func withAccessibilitySettings<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
    }
    
    static func announceForTesting(_ message: String) {
        print("🔊 VoiceOver would announce: \(message)")
    }
}
#endif
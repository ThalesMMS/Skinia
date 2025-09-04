import SwiftUI

// MARK: - Design System

struct DesignSystem {
    
    // MARK: - Color System
    struct Colors {
        // Primary Brand Colors
        static let primary = Color(red: 0.0, green: 0.48, blue: 0.8) // Medical Blue
        static let primaryLight = Color(red: 0.85, green: 0.93, blue: 1.0)
        static let primaryDark = Color(red: 0.0, green: 0.36, blue: 0.6)
        
        // Secondary Colors
        static let secondary = Color(red: 0.98, green: 0.45, blue: 0.26) // Medical Orange
        static let secondaryLight = Color(red: 1.0, green: 0.95, blue: 0.92)
        static let secondaryDark = Color(red: 0.8, green: 0.36, blue: 0.21)
        
        // Status Colors
        static let success = Color(red: 0.0, green: 0.7, blue: 0.42)
        static let successLight = Color(red: 0.9, green: 0.98, blue: 0.94)
        static let warning = Color(red: 1.0, green: 0.75, blue: 0.0)
        static let warningLight = Color(red: 1.0, green: 0.98, blue: 0.9)
        static let error = Color(red: 0.9, green: 0.26, blue: 0.21)
        static let errorLight = Color(red: 1.0, green: 0.95, blue: 0.95)
        static let info = Color(red: 0.13, green: 0.58, blue: 0.95)
        static let infoLight = Color(red: 0.93, green: 0.97, blue: 1.0)
        
        // Neutral Colors
        static let text = Color(red: 0.11, green: 0.11, blue: 0.13)
        static let textSecondary = Color(red: 0.44, green: 0.44, blue: 0.46)
        static let textTertiary = Color(red: 0.68, green: 0.68, blue: 0.7)
        
        static let background = Color(red: 0.98, green: 0.98, blue: 0.99)
        static let backgroundSecondary = Color(red: 0.95, green: 0.95, blue: 0.97)
        static let surface = Color.white
        static let surfaceSecondary = Color(red: 0.98, green: 0.98, blue: 0.99)
        
        static let border = Color(red: 0.89, green: 0.89, blue: 0.92)
        static let borderLight = Color(red: 0.95, green: 0.95, blue: 0.97)
        
        // Risk Level Colors (Enhanced)
        static let riskLow = success
        static let riskLowBackground = successLight
        static let riskModerate = warning
        static let riskModerateBackground = warningLight
        static let riskHigh = secondary
        static let riskHighBackground = secondaryLight
        static let riskUrgent = error
        static let riskUrgentBackground = errorLight
    }
    
    // MARK: - Typography System
    struct Typography {
        // Headings
        static let largeTitle = Font.custom("SF Pro Display", size: 34, relativeTo: .largeTitle).weight(.bold)
        static let title1 = Font.custom("SF Pro Display", size: 28, relativeTo: .title).weight(.bold)
        static let title2 = Font.custom("SF Pro Display", size: 22, relativeTo: .title2).weight(.semibold)
        static let title3 = Font.custom("SF Pro Display", size: 20, relativeTo: .title3).weight(.semibold)
        
        // Body Text
        static let headline = Font.custom("SF Pro Text", size: 17, relativeTo: .headline).weight(.semibold)
        static let body = Font.custom("SF Pro Text", size: 17, relativeTo: .body)
        static let bodyEmphasized = Font.custom("SF Pro Text", size: 17, relativeTo: .body).weight(.medium)
        static let callout = Font.custom("SF Pro Text", size: 16, relativeTo: .callout)
        static let subheadline = Font.custom("SF Pro Text", size: 15, relativeTo: .subheadline)
        
        // Supporting Text
        static let footnote = Font.custom("SF Pro Text", size: 13, relativeTo: .footnote)
        static let caption = Font.custom("SF Pro Text", size: 12, relativeTo: .caption)
        static let caption2 = Font.custom("SF Pro Text", size: 11, relativeTo: .caption2)
        
        // Medical Specific
        static let medicalTitle = Font.custom("SF Pro Display", size: 24, relativeTo: .title2).weight(.bold)
        static let medicalBody = Font.custom("SF Pro Text", size: 16, relativeTo: .body)
        static let medicalCaption = Font.custom("SF Pro Text", size: 13, relativeTo: .caption).weight(.medium)
    }
    
    // MARK: - Spacing System
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
        
        // Component Specific
        static let cardPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
        static let itemSpacing: CGFloat = 12
        static let buttonHeight: CGFloat = 48
        static let inputHeight: CGFloat = 44
    }
    
    // MARK: - Corner Radius System
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let round: CGFloat = 1000 // For perfect circles
        
        // Component Specific
        static let card: CGFloat = 16
        static let button: CGFloat = 12
        static let input: CGFloat = 10
        static let badge: CGFloat = 8
    }
    
    // MARK: - Shadow System
    struct Shadows {
        static let small = Shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        static let medium = Shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        static let large = Shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)
        static let card = Shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        static let floating = Shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
        
        struct Shadow {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }
    
    // MARK: - Animation System
    struct Animations {
        // Standard Animations
        static let quick = Animation.easeInOut(duration: 0.2)
        static let standard = Animation.easeInOut(duration: 0.3)
        static let slow = Animation.easeInOut(duration: 0.5)
        
        // Spring Animations
        static let bouncy = Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let gentle = Animation.spring(response: 0.4, dampingFraction: 0.9)
        static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
        
        // Specialized
        static let progressUpdate = Animation.easeInOut(duration: 0.4)
        static let stateChange = Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let listUpdate = Animation.easeInOut(duration: 0.25)
    }
    
    // MARK: - Layout System
    struct Layout {
        // Screen margins
        static let screenPadding: CGFloat = 20
        static let safeAreaPadding: CGFloat = 16
        
        // Grid system
        static let gridSpacing: CGFloat = 16
        static let columnSpacing: CGFloat = 12
        
        // Component dimensions
        static let maxContentWidth: CGFloat = 428 // iPhone 14 Pro Max width
        static let cardMinHeight: CGFloat = 120
        static let buttonMinWidth: CGFloat = 88
        static let iconSize: CGFloat = 24
        static let avatarSize: CGFloat = 40
        
        // Breakpoints for responsive design
        static let compactWidth: CGFloat = 375 // iPhone SE width
        static let regularWidth: CGFloat = 428 // iPhone 14 Pro Max width
        static let tabletWidth: CGFloat = 768 // iPad Mini width
    }
}

// MARK: - View Extensions

extension View {
    // Apply design system shadows
    func designShadow(_ shadow: DesignSystem.Shadows.Shadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    // Apply card styling
    func cardStyle(
        padding: CGFloat = DesignSystem.Spacing.cardPadding,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.card,
        shadow: DesignSystem.Shadows.Shadow = DesignSystem.Shadows.card
    ) -> some View {
        self
            .padding(padding)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(cornerRadius)
            .designShadow(shadow)
    }
    
    // Apply button styling
    func primaryButtonStyle() -> some View {
        self
            .frame(minHeight: DesignSystem.Spacing.buttonHeight)
            .background(DesignSystem.Colors.primary)
            .foregroundColor(.white)
            .font(DesignSystem.Typography.headline)
            .cornerRadius(DesignSystem.CornerRadius.button)
            .designShadow(DesignSystem.Shadows.small)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .frame(minHeight: DesignSystem.Spacing.buttonHeight)
            .background(DesignSystem.Colors.surface)
            .foregroundColor(DesignSystem.Colors.primary)
            .font(DesignSystem.Typography.headline)
            .cornerRadius(DesignSystem.CornerRadius.button)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(DesignSystem.Colors.primary, lineWidth: 1.5)
            )
    }
    
    // Responsive layout helpers
    func adaptiveFrame(maxWidth: CGFloat = DesignSystem.Layout.maxContentWidth) -> some View {
        self.frame(maxWidth: min(maxWidth, UIScreen.main.bounds.width - (DesignSystem.Layout.screenPadding * 2)))
    }
    
    // Animation helpers
    func quickAnimation() -> some View {
        self.animation(DesignSystem.Animations.quick, value: UUID())
    }
    
    func standardAnimation() -> some View {
        self.animation(DesignSystem.Animations.standard, value: UUID())
    }
}

// MARK: - Color Extensions

extension Color {
    // Initialize from hex
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Haptic Feedback Helper

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
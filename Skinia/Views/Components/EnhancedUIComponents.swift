import SwiftUI

// MARK: - Enhanced Loading States

struct LoadingDots: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationAmount == 0 ? 1.0 : 0.3)
                    .opacity(animationAmount == 0 ? 1.0 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: animationAmount
                    )
            }
        }
        .onAppear {
            animationAmount = 1.0
        }
    }
}

struct PulsatingCircle: View {
    @State private var isPulsing = false
    let color: Color
    let size: CGFloat
    
    init(color: Color = DesignSystem.Colors.primary, size: CGFloat = 40) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size, height: size)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0.1 : 0.3)
            
            Circle()
                .fill(color)
                .frame(width: size * 0.6, height: size * 0.6)
        }
        .animation(
            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
            value: isPulsing
        )
        .onAppear {
            isPulsing = true
        }
    }
}

struct SkeletonLoader: View {
    @State private var animationAmount = 0.0
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(height: CGFloat = 20, cornerRadius: CGFloat = DesignSystem.CornerRadius.sm) {
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        DesignSystem.Colors.backgroundSecondary,
                        DesignSystem.Colors.backgroundSecondary.opacity(0.7),
                        DesignSystem.Colors.backgroundSecondary
                    ],
                    startPoint: UnitPoint(x: -1.0 - animationAmount, y: 0),
                    endPoint: UnitPoint(x: 1.0 - animationAmount, y: 0)
                )
            )
            .frame(height: height)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
                ) {
                    animationAmount = 2.0
                }
            }
    }
}

struct WaveLoadingIndicator: View {
    @State private var waveOffset = Angle(degrees: 0)
    let color: Color
    
    init(color: Color = DesignSystem.Colors.primary) {
        self.color = color
    }
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midHeight = height * 0.5
                let wavelength = width / 2
                
                path.move(to: CGPoint(x: 0, y: midHeight))
                
                for x in stride(from: 0, through: width, by: 1) {
                    let relativeX = x / wavelength
                    let sine = sin(relativeX * Double.pi * 2 + waveOffset.radians)
                    let y = midHeight + sine * (height * 0.25)
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(color, lineWidth: 3)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
        .frame(height: 4)
        .onAppear {
            withAnimation(
                Animation.linear(duration: 2.0).repeatForever(autoreverses: false)
            ) {
                waveOffset = Angle(degrees: 360)
            }
        }
    }
}

// MARK: - Enhanced Buttons

struct AnimatedButton<Content: View>: View {
    let action: () -> Void
    let content: () -> Content
    
    @State private var isPressed = false
    @State private var animationScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.medium)
            
            withAnimation(DesignSystem.Animations.bouncy) {
                animationScale = 0.95
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignSystem.Animations.bouncy) {
                    animationScale = 1.0
                }
                action()
            }
        }) {
            content()
                .scaleEffect(animationScale)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    
    init(_ title: String, isLoading: Bool = false, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.action = action
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        AnimatedButton(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if isLoading {
                    LoadingDots()
                } else {
                    Text(title)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Spacing.buttonHeight)
            .background(
                isDisabled ? DesignSystem.Colors.textTertiary : DesignSystem.Colors.primary
            )
            .cornerRadius(DesignSystem.CornerRadius.button)
            .designShadow(isDisabled ? DesignSystem.Shadows.small : DesignSystem.Shadows.medium)
        }
        .disabled(isDisabled || isLoading)
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    
    init(_ title: String, isLoading: Bool = false, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.action = action
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        AnimatedButton(action: action) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                if isLoading {
                    LoadingDots()
                } else {
                    Text(title)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(isDisabled ? DesignSystem.Colors.textTertiary : DesignSystem.Colors.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignSystem.Spacing.buttonHeight)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.button)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.button)
                    .stroke(isDisabled ? DesignSystem.Colors.textTertiary : DesignSystem.Colors.primary, lineWidth: 1.5)
            )
            .designShadow(DesignSystem.Shadows.small)
        }
        .disabled(isDisabled || isLoading)
    }
}

// MARK: - Enhanced Cards

struct InteractiveCard<Content: View>: View {
    let content: () -> Content
    let onTap: (() -> Void)?
    
    @State private var isPressed = false
    
    init(onTap: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.onTap = onTap
    }
    
    var body: some View {
        content()
            .cardStyle()
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animations.quick, value: isPressed)
            .onTapGesture {
                guard let onTap = onTap else { return }
                
                HapticManager.shared.impact(.light)
                
                withAnimation(DesignSystem.Animations.quick) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(DesignSystem.Animations.quick) {
                        isPressed = false
                    }
                    onTap()
                }
            }
    }
}

// MARK: - Enhanced Progress Indicators

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        lineWidth: CGFloat = 4,
        size: CGFloat = 40,
        backgroundColor: Color = DesignSystem.Colors.border,
        foregroundColor: Color = DesignSystem.Colors.primary
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(foregroundColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(DesignSystem.Animations.progressUpdate, value: animatedProgress)
        }
        .frame(width: size, height: size)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { _, newProgress in
            withAnimation(DesignSystem.Animations.progressUpdate) {
                animatedProgress = newProgress
            }
        }
    }
}

struct LinearProgressView: View {
    let progress: Double
    let height: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        height: CGFloat = 8,
        backgroundColor: Color = DesignSystem.Colors.border,
        foregroundColor: Color = DesignSystem.Colors.primary
    ) {
        self.progress = progress
        self.height = height
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(backgroundColor)
                
                Rectangle()
                    .fill(foregroundColor)
                    .frame(width: geometry.size.width * animatedProgress)
                    .animation(DesignSystem.Animations.progressUpdate, value: animatedProgress)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: height / 2))
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { _, newProgress in
            withAnimation(DesignSystem.Animations.progressUpdate) {
                animatedProgress = newProgress
            }
        }
    }
}

// MARK: - Floating Action Button

struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var shadowOffset: CGFloat = 8
    
    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.heavy)
            
            withAnimation(DesignSystem.Animations.bouncy) {
                isPressed = true
                shadowOffset = 4
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignSystem.Animations.bouncy) {
                    isPressed = false
                    shadowOffset = 8
                }
                action()
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(DesignSystem.Colors.primary)
                .clipShape(Circle())
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .shadow(
                    color: DesignSystem.Colors.primary.opacity(0.3),
                    radius: 12,
                    x: 0,
                    y: shadowOffset
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Empty State

struct EnhancedEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    Text(title)
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.text)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(actionTitle, action: action)
                    .adaptiveFrame(maxWidth: 280)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .adaptiveFrame()
    }
}

// MARK: - Toast Notification Enhancement

struct ToastView: View {
    let notification: StatusNotification
    let onDismiss: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isVisible = true
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: notification.icon)
                .foregroundColor(notification.color)
                .font(DesignSystem.Typography.headline)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(notification.title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.text)
                
                if let message = notification.message {
                    Text(message)
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(3)
                }
            }
            
            Spacer()
            
            Button {
                dismissNotification()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .font(DesignSystem.Typography.caption)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .designShadow(DesignSystem.Shadows.floating)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(notification.color.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(y: dragOffset.height)
        .animation(DesignSystem.Animations.standard, value: isVisible)
        .animation(DesignSystem.Animations.quick, value: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 {
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    if value.translation.height < -50 {
                        dismissNotification()
                    } else {
                        dragOffset = .zero
                    }
                }
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + notification.duration) {
                dismissNotification()
            }
        }
    }
    
    private func dismissNotification() {
        HapticManager.shared.impact(.light)
        
        withAnimation(DesignSystem.Animations.standard) {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LoadingDots()
        PulsatingCircle()
        SkeletonLoader()
        CircularProgressView(progress: 0.7)
        LinearProgressView(progress: 0.5)
        PrimaryButton("Primary Button") {}
        SecondaryButton("Secondary Button") {}
    }
    .padding()
}
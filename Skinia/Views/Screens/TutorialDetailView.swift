import SwiftUI

struct TutorialDetailView: View {
    let tutorial: Tutorial
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressIndicator(current: currentStep, total: tutorial.steps.count)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                
                // Tutorial content
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Header with icon and title
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: tutorial.icon)
                                .font(.system(size: 50))
                                .foregroundColor(tutorial.iconColor)
                            
                            Text(tutorial.title)
                                .font(DesignSystem.Typography.title2)
                                .foregroundColor(DesignSystem.Colors.text)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, DesignSystem.Spacing.md)
                        
                        // Current step content
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("Passo \(currentStep + 1) de \(tutorial.steps.count)")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(tutorial.iconColor)
                                .fontWeight(.medium)
                            
                            Text(tutorial.steps[currentStep].title)
                                .font(DesignSystem.Typography.title3)
                                .foregroundColor(DesignSystem.Colors.text)
                            
                            Text(tutorial.steps[currentStep].description)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .lineSpacing(4)
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DesignSystem.Colors.surface)
                        .cornerRadius(DesignSystem.CornerRadius.card)
                        .designShadow(DesignSystem.Shadows.card)
                        
                        Spacer(minLength: DesignSystem.Spacing.xl)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                }
                
                // Navigation buttons
                HStack(spacing: DesignSystem.Spacing.md) {
                    // Previous button
                    Button(action: previousStep) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Anterior")
                                .font(DesignSystem.Typography.callout)
                        }
                        .foregroundColor(currentStep > 0 ? DesignSystem.Colors.primary : DesignSystem.Colors.textTertiary)
                    }
                    .disabled(currentStep == 0)
                    .frame(maxWidth: .infinity)
                    .secondaryButtonStyle()
                    .opacity(currentStep > 0 ? 1.0 : 0.6)
                    
                    // Next/Finish button
                    Button(action: nextStep) {
                        HStack {
                            Text(isLastStep ? "Concluir" : "Próximo")
                                .font(DesignSystem.Typography.callout)
                            
                            if !isLastStep {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .primaryButtonStyle()
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.lg)
                .background(
                    Rectangle()
                        .fill(DesignSystem.Colors.background)
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: -1)
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isLastStep: Bool {
        currentStep == tutorial.steps.count - 1
    }
    
    private func previousStep() {
        guard currentStep > 0 else { return }
        
        withAnimation(DesignSystem.Animations.standard) {
            currentStep -= 1
        }
        HapticManager.shared.selection()
    }
    
    private func nextStep() {
        if isLastStep {
            HapticManager.shared.notification(.success)
            dismiss()
        } else {
            withAnimation(DesignSystem.Animations.standard) {
                currentStep += 1
            }
            HapticManager.shared.selection()
        }
    }
}

// MARK: - Progress Indicator

struct ProgressIndicator: View {
    let current: Int
    let total: Int
    
    private var progress: Double {
        Double(current + 1) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignSystem.Colors.borderLight)
                        .frame(height: 4)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(DesignSystem.Animations.standard, value: progress)
                }
            }
            .frame(height: 4)
            
            // Step indicator
            HStack {
                Text("Passo \(current + 1)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(total) passos")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
    }
}

#Preview {
    TutorialDetailView(tutorial: Tutorial.allTutorials.first!)
}
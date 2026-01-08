import SwiftUI

struct AnalysisProgressView: View {
    let photo: SkinLesionPhoto
    @State private var progress: AnalysisProgress?
    @State private var timer: Timer?
    
    private let analysisService: any AnalysisServiceProtocol
    
    init(photo: SkinLesionPhoto, analysisService: any AnalysisServiceProtocol) {
        self.photo = photo
        self.analysisService = analysisService
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Photo thumbnail
            photoSection
            
            // Progress section
            if let progress = progress {
                progressSection(progress)
            } else {
                loadingSection
            }
            
            Spacer()
            
            // Action buttons
            actionButtons
        }
        .padding()
        .navigationTitle("Análise em Progresso")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startProgressTracking()
        }
        .onDisappear {
            stopProgressTracking()
        }
    }
    
    private var photoSection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if let image = photo.fullImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                    .designShadow(DesignSystem.Shadows.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .stroke(DesignSystem.Colors.backgroundSecondary, lineWidth: 2)
                    )
            }
            
            if let bodyLocation = photo.metadata?.bodyLocation {
                Text(bodyLocation)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.primary)
                    .fontWeight(.medium)
            }
            
            Text("ID: \(photo.id.uuidString.prefix(8))")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
    
    private func progressSection(_ progress: AnalysisProgress) -> some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Current stage
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    Image(systemName: progress.currentStage.systemIcon)
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(stageColor(progress.currentStage))
                        .imageScale(.large)
                    
                    Text(progress.currentStage.displayName)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.text)
                    
                    Spacer()
                    
                    if progress.currentStage != .completed && progress.currentStage != .failed {
                        LoadingDots()
                            .scaleEffect(0.8)
                    }
                }
                
                // Overall progress bar
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text("Progresso Geral")
                            .font(DesignSystem.Typography.medicalCaption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Spacer()
                        
                        Text("\(Int(progress.overallProgress * 100))%")
                            .font(DesignSystem.Typography.medicalCaption)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                    
                    ProgressView(value: progress.overallProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.primary))
                        .scaleEffect(y: 2.0)
                }
            }
            .padding(DesignSystem.Spacing.lg)
            .cardStyle()
            .designShadow(DesignSystem.Shadows.card)
            
            // Stage progress
            if progress.currentStage != .completed && progress.currentStage != .failed {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Etapa Atual")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(Int(progress.stageProgress * 100))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    ProgressView(value: progress.stageProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                }
                .padding()
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .cornerRadius(8)
            }
            
            // Time information
            timeInfoSection(progress)
            
            // Error section
            if let errorMessage = progress.errorMessage {
                errorSection(errorMessage)
            }
        }
    }
    
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Carregando informações da análise...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private func timeInfoSection(_ progress: AnalysisProgress) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Label("Tempo Decorrido", systemImage: "clock")
                    .font(DesignSystem.Typography.medicalCaption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                Text(progress.formattedElapsedTime)
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.text)
            }
            
            Spacer()
            
            if let remainingTime = progress.formattedEstimatedTimeRemaining,
               progress.currentStage != .completed && progress.currentStage != .failed {
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Label("Tempo Restante", systemImage: "timer")
                        .font(DesignSystem.Typography.medicalCaption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(remainingTime)
                        .font(DesignSystem.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .cardStyle()
    }
    
    private func errorSection(_ errorMessage: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(DesignSystem.Colors.error)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Erro na Análise")
                    .font(DesignSystem.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DesignSystem.Colors.error)
                
                Text(errorMessage)
                    .font(DesignSystem.Typography.medicalCaption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.error.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.error.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
    
    private var actionButtons: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if let progress = progress {
                switch progress.currentStage {
                case .completed:
                    Button {
                        // Navigate to results
                    } label: {
                        HStack {
                            Image(systemName: "eye.fill")
                            Text("Ver Resultado")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.Colors.success)
                        .foregroundColor(.white)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.semibold)
                    }
                    
                case .failed:
                    Button {
                        Task {
                            HapticManager.shared.impact(.medium)
                            try await analysisService.retryAnalysis(for: photo)
                            startProgressTracking()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Tentar Novamente")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.Colors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.semibold)
                    }
                    
                default:
                    Button {
                        Task {
                            HapticManager.shared.impact(.light)
                            await analysisService.cancelAnalysis(for: photo.id)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Cancelar Análise")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignSystem.Colors.backgroundSecondary)
                        .foregroundColor(DesignSystem.Colors.error)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .stroke(DesignSystem.Colors.error.opacity(0.5), lineWidth: 1)
                        )
                        .cornerRadius(DesignSystem.CornerRadius.lg)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                    }
                }
            }
        }
    }
    
    private func startProgressTracking() {
        // Get initial progress
        Task { @MainActor in
            progress = analysisService.getAnalysisProgress(for: photo.id)
        }
        
        // Start timer for updates
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            Task { @MainActor in
                progress = analysisService.getAnalysisProgress(for: photo.id)
            }
        }
    }
    
    private func stopProgressTracking() {
        timer?.invalidate()
        timer = nil
    }
    
    private func stageColor(_ stage: AnalysisStage) -> Color {
        switch stage {
        case .uploading:
            return DesignSystem.Colors.info
        case .preprocessing, .analyzing:
            return DesignSystem.Colors.warning
        case .postprocessing:
            return DesignSystem.Colors.primary
        case .completed:
            return DesignSystem.Colors.success
        case .failed:
            return DesignSystem.Colors.error
        }
    }
}

#Preview {
    let container = DependencyContainer.shared
    
    let mockPhoto = SkinLesionPhoto(
        imageData: Data(),
        analysisStatus: .analyzing
    )
    
    NavigationView {
        AnalysisProgressView(photo: mockPhoto, analysisService: container.analysisService)
    }
}
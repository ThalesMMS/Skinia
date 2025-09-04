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
        VStack(spacing: 12) {
            if let image = photo.fullImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
            
            Text("ID: \(photo.id.uuidString.prefix(8))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func progressSection(_ progress: AnalysisProgress) -> some View {
        VStack(spacing: 20) {
            // Current stage
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: progress.currentStage.systemIcon)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text(progress.currentStage.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                // Overall progress bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progresso Geral")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(progress.overallProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    ProgressView(value: progress.overallProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(y: 1.5)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
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
            VStack(alignment: .leading, spacing: 4) {
                Text("Tempo Decorrido")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(progress.formattedElapsedTime)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            if let remainingTime = progress.formattedEstimatedTimeRemaining,
               progress.currentStage != .completed && progress.currentStage != .failed {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Tempo Restante")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(remainingTime)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func errorSection(_ errorMessage: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Erro na Análise")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if let progress = progress {
                switch progress.currentStage {
                case .completed:
                    Button("Ver Resultado") {
                        // Navigate to results
                    }
                    .buttonStyle(.borderedProminent)
                    
                case .failed:
                    Button("Tentar Novamente") {
                        Task {
                            try await analysisService.retryAnalysis(for: photo)
                            startProgressTracking()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                default:
                    Button("Cancelar Análise") {
                        Task {
                            await analysisService.cancelAnalysis(for: photo.id)
                        }
                    }
                    .buttonStyle(.bordered)
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
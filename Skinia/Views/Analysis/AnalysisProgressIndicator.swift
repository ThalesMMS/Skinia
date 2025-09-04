import SwiftUI

struct AnalysisProgressIndicator: View {
    let photo: SkinLesionPhoto
    @State private var progress: AnalysisProgress?
    @State private var timer: Timer?
    
    private let analysisService: any AnalysisServiceProtocol
    
    init(photo: SkinLesionPhoto, analysisService: any AnalysisServiceProtocol) {
        self.photo = photo
        self.analysisService = analysisService
    }
    
    var body: some View {
        Group {
            if let progress = progress {
                progressContent(progress)
            } else {
                defaultContent
            }
        }
        .onAppear {
            startProgressTracking()
        }
        .onDisappear {
            stopProgressTracking()
        }
    }
    
    @ViewBuilder
    private func progressContent(_ progress: AnalysisProgress) -> some View {
        switch progress.currentStage {
        case .uploading, .preprocessing, .analyzing, .postprocessing:
            activeAnalysisView(progress)
        case .completed:
            completedView
        case .failed:
            failedView(progress)
        }
    }
    
    private func activeAnalysisView(_ progress: AnalysisProgress) -> some View {
        HStack(spacing: 8) {
            // Animated progress indicator
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    .frame(width: 20, height: 20)
                
                Circle()
                    .trim(from: 0, to: progress.overallProgress)
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress.overallProgress)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(progress.currentStage.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Text("\(Int(progress.overallProgress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let remainingTime = progress.formattedEstimatedTimeRemaining {
                        Text("• \(remainingTime)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    private var completedView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Análise Concluída")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let result = photo.analysisResult {
                    Text("\(Int(result.confidence * 100))% confiança")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
    
    private func failedView(_ progress: AnalysisProgress) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Falha na Análise")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                
                if let errorMessage = progress.errorMessage {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
    }
    
    private var defaultContent: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
                .frame(width: 20, height: 20)
            
            Text("Carregando...")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    private func startProgressTracking() {
        // Only track if photo is in analysis
        guard photo.analysisStatus == .uploading || 
              photo.analysisStatus == .analyzing ||
              photo.analysisStatus == .failed else {
            return
        }
        
        // Get initial progress
        Task { @MainActor in
            progress = analysisService.getAnalysisProgress(for: photo.id)
        }
        
        // Start timer for updates
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
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

// MARK: - Compact Version for List Cells

struct CompactAnalysisProgressIndicator: View {
    let photo: SkinLesionPhoto
    @State private var progress: AnalysisProgress?
    @State private var timer: Timer?
    
    private let analysisService: any AnalysisServiceProtocol
    
    init(photo: SkinLesionPhoto, analysisService: any AnalysisServiceProtocol) {
        self.photo = photo
        self.analysisService = analysisService
    }
    
    var body: some View {
        Group {
            if let progress = progress {
                compactProgressView(progress)
            } else if photo.analysisStatus == .uploading || photo.analysisStatus == .analyzing {
                compactLoadingView
            } else {
                EmptyView()
            }
        }
        .onAppear {
            startProgressTracking()
        }
        .onDisappear {
            stopProgressTracking()
        }
    }
    
    @ViewBuilder
    private func compactProgressView(_ progress: AnalysisProgress) -> some View {
        switch progress.currentStage {
        case .uploading, .preprocessing, .analyzing, .postprocessing:
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 14, height: 14)
                    
                    Circle()
                        .trim(from: 0, to: progress.overallProgress)
                        .stroke(Color.blue, lineWidth: 1.5)
                        .frame(width: 14, height: 14)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: progress.overallProgress)
                }
                
                Text("\(Int(progress.overallProgress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
            
        case .completed, .failed:
            EmptyView()
        }
    }
    
    private var compactLoadingView: some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.6)
                .frame(width: 14, height: 14)
            
            Text("...")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func startProgressTracking() {
        // Only track if photo is in analysis
        guard photo.analysisStatus == .uploading || 
              photo.analysisStatus == .analyzing else {
            return
        }
        
        Task { @MainActor in
            progress = analysisService.getAnalysisProgress(for: photo.id)
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
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
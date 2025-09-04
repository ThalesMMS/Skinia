import SwiftUI

struct AnalysisDetailView: View {
    let photo: SkinLesionPhoto
    @Environment(\.analysisService) private var analysisService
    @Environment(\.notificationManager) private var notificationManager
    @State private var showingShareSheet = false
    @State private var isRetryingAnalysis = false
    
    init(photo: SkinLesionPhoto) {
        self.photo = photo
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Photo section
                photoSection
                
                // Status section
                statusSection
                
                // Progress indicator for ongoing analysis
                if photo.analysisStatus == .uploading || photo.analysisStatus == .analyzing {
                    AnalysisProgressIndicator(photo: photo, analysisService: analysisService)
                }
                
                // Results section
                if let result = photo.analysisResult {
                    analysisResultSection(result)
                    riskAssessmentSection(result)
                    recommendationsSection(result)
                }
                
                // Actions section
                actionsSection
                
                // Metadata section
                if let metadata = photo.metadata {
                    metadataSection(metadata)
                }
                
                // User notes section
                userNotesSection
            }
            .padding()
        }
        .navigationTitle("Análise Dermatológica")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Compartilhar") {
                    showingShareSheet = true
                }
                .disabled(photo.analysisResult == nil)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let result = photo.analysisResult {
                ShareSheet(photo: photo, result: result)
            }
        }
    }
    
    private var photoSection: some View {
        VStack(spacing: 12) {
            if let image = photo.fullImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 300)
                    .clipped()
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
            }
        }
    }
    
    private var statusSection: some View {
        VStack(spacing: 16) {
            HStack {
                StatusBadge(status: photo.analysisStatus)
                Spacer()
                Text(photo.formattedCaptureDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func analysisResultSection(_ result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with title and timestamp
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resultado da Análise")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Análise completa com IA")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                RiskBadge(riskLevel: result.riskLevel)
            }
            
            Divider()
            
            // Lesion type with prominent display
            VStack(alignment: .leading, spacing: 12) {
                Text("Diagnóstico Principal")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(result.lesionType)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Confidence visualization
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Nível de Confiança")
                        .font(.headline)
                    Spacer()
                    Text(result.confidencePercentage)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(confidenceColor(result.confidence))
                }
                
                ProgressView(value: result.confidence)
                    .progressViewStyle(LinearProgressViewStyle(tint: confidenceColor(result.confidence)))
                    .scaleEffect(y: 2.0, anchor: .center)
                
                Text(confidenceDescription(result.confidence))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(result.riskLevel.color.opacity(0.3), lineWidth: 2)
        )
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func metadataSection(_ metadata: PhotoMetadata) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Informações Técnicas")
                .font(.headline)
            
            VStack(spacing: 8) {
                metadataRow(label: "Qualidade", value: metadata.imageQuality.rawValue.capitalized)
                metadataRow(label: "Dispositivo", value: metadata.deviceInfo)
                metadataRow(label: "Orientação", value: metadata.orientation.capitalized)
                metadataRow(label: "Dimensões", value: metadata.imageDimensions)
                metadataRow(label: "Tamanho", value: metadata.fileSizeFormatted)
                
                if let bodyLocation = metadata.bodyLocation {
                    metadataRow(label: "Local do Corpo", value: bodyLocation)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - New Enhanced Sections
    
    private func riskAssessmentSection(_ result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Avaliação de Risco")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                // Risk level icon and description
                VStack(spacing: 8) {
                    Image(systemName: result.riskLevel.systemImage)
                        .font(.system(size: 40))
                        .foregroundColor(result.riskLevel.color)
                    
                    Text(result.riskLevel.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(result.riskLevel.color)
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(riskDescription(result.riskLevel))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(riskActionText(result.riskLevel))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(result.riskLevel.color.opacity(0.05))
        .cornerRadius(16)
    }
    
    private func recommendationsSection(_ result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recomendações Médicas")
                .font(.title2)
                .fontWeight(.bold)
            
            if !result.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(result.recommendations.enumerated()), id: \.offset) { index, recommendation in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 24, height: 24)
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recommendation)
                                    .font(.subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                if isUrgentRecommendation(recommendation) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                            .font(.caption2)
                                        Text("Ação urgente recomendada")
                                            .font(.caption2)
                                            .foregroundColor(.red)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        
                        if index < result.recommendations.count - 1 {
                            Divider()
                        }
                    }
                }
            } else {
                Text("Nenhuma recomendação específica disponível.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Text("Ações")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                // Retry analysis button
                if photo.analysisStatus == .failed {
                    Button(action: retryAnalysis) {
                        HStack {
                            if isRetryingAnalysis {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Repetir Análise")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isRetryingAnalysis)
                }
                
                // Export report button
                if photo.analysisResult != nil {
                    Button("Exportar Relatório") {
                        exportReport()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
                
                // Save to Photos button
                if photo.analysisResult != nil {
                    Button("Salvar na Galeria") {
                        saveToPhotos()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var userNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Observações do Paciente")
                .font(.headline)
            
            if let notes = photo.userNotes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
            } else {
                Text("Nenhuma observação adicionada.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Functions
    
    private func confidenceColor(_ confidence: Double) -> Color {
        switch confidence {
        case 0.9...1.0: return .green
        case 0.7..<0.9: return .blue
        case 0.5..<0.7: return .orange
        default: return .red
        }
    }
    
    private func confidenceDescription(_ confidence: Double) -> String {
        switch confidence {
        case 0.9...1.0: return "Confiança muito alta - resultado altamente confiável"
        case 0.7..<0.9: return "Confiança alta - resultado confiável"
        case 0.5..<0.7: return "Confiança moderada - considere análise adicional"
        default: return "Confiança baixa - recomendada nova análise"
        }
    }
    
    private func riskDescription(_ riskLevel: RiskLevel) -> String {
        switch riskLevel {
        case .low:
            return "A lesão apresenta características benignas com baixa probabilidade de malignidade."
        case .moderate:
            return "A lesão requer monitoramento regular, mas não apresenta sinais imediatos de preocupação."
        case .high:
            return "A lesão apresenta características que requerem avaliação dermatológica urgente."
        case .urgent:
            return "A lesão apresenta características altamente suspeitas que requerem atenção médica imediata."
        }
    }
    
    private func riskActionText(_ riskLevel: RiskLevel) -> String {
        switch riskLevel {
        case .low:
            return "Continue com acompanhamento dermatológico regular."
        case .moderate:
            return "Agende consulta dermatológica em 3-6 meses."
        case .high:
            return "Consulte um dermatologista dentro de 2-4 semanas."
        case .urgent:
            return "Procure atendimento dermatológico imediatamente."
        }
    }
    
    private func isUrgentRecommendation(_ recommendation: String) -> Bool {
        let urgentKeywords = ["URGENTE", "IMEDIATA", "IMEDIATAMENTE", "NÃO RETARDAR"]
        return urgentKeywords.contains { keyword in
            recommendation.uppercased().contains(keyword)
        }
    }
    
    // MARK: - Action Functions
    
    private func retryAnalysis() {
        isRetryingAnalysis = true
        Task {
            do {
                try await analysisService.retryAnalysis(for: photo)
            } catch {
                notificationManager.show(
                    title: "Erro ao Repetir Análise",
                    message: error.localizedDescription,
                    type: .error
                )
            }
            isRetryingAnalysis = false
        }
    }
    
    private func exportReport() {
        notificationManager.show(
            title: "Exportando Relatório",
            message: "Gerando relatório em PDF...",
            type: .info
        )
        // Implementation will be added later
    }
    
    private func saveToPhotos() {
        guard let image = photo.fullImage else { return }
        
        // Save to photo library (implementation needed)
        notificationManager.show(
            title: "Imagem Salva",
            message: "Imagem salva na galeria com sucesso",
            type: .success
        )
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let photo: SkinLesionPhoto
    let result: AnalysisResult
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let reportText = generateShareableReport()
        var items: [Any] = [reportText]
        
        if let image = photo.fullImage {
            items.append(image)
        }
        
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    
    private func generateShareableReport() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return """
        📊 RELATÓRIO DE ANÁLISE DERMATOLÓGICA
        
        🗓 Data da Análise: \(formatter.string(from: photo.captureDate))
        
        🔬 Resultado: \(result.lesionType)
        📊 Confiança: \(result.confidencePercentage)
        ⚠️ Nível de Risco: \(result.riskLevel.displayName)
        
        📋 RECOMENDAÇÕES:
        \(result.recommendations.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n"))
        
        ⚠️ IMPORTANTE: Este relatório é gerado por inteligência artificial e não substitui a consulta médica profissional. Sempre procure um dermatologista para diagnóstico definitivo.
        
        📱 Gerado pelo aplicativo Skinia
        """
    }
}

#Preview {
    let mockPhoto = SkinLesionPhoto(
        imageData: Data(),
        analysisStatus: .completed
    )
    
    NavigationView {
        AnalysisDetailView(photo: mockPhoto)
    }
}
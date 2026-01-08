import Testing
import SwiftData
import Foundation
import CoreGraphics
@testable import Skinia

@MainActor
struct ModelTests {
    
    // MARK: - AnalysisStatus Tests
    
    @Test func analysisStatusDisplayNames() {
        #expect(AnalysisStatus.pending.displayName == "Aguardando Envio")
        #expect(AnalysisStatus.uploading.displayName == "Enviando")
        #expect(AnalysisStatus.analyzing.displayName == "Analisando")
        #expect(AnalysisStatus.completed.displayName == "Concluída")
        #expect(AnalysisStatus.failed.displayName == "Erro")
    }
    
    @Test func analysisStatusSystemImages() {
        #expect(AnalysisStatus.pending.systemImage == "clock")
        #expect(AnalysisStatus.uploading.systemImage == "icloud.and.arrow.up")
        #expect(AnalysisStatus.analyzing.systemImage == "brain.head.profile")
        #expect(AnalysisStatus.completed.systemImage == "checkmark.circle.fill")
        #expect(AnalysisStatus.failed.systemImage == "exclamationmark.triangle.fill")
    }
    
    @Test func analysisStatusColors() {
        #expect(AnalysisStatus.pending.color == "gray")
        #expect(AnalysisStatus.uploading.color == "blue")
        #expect(AnalysisStatus.analyzing.color == "orange")
        #expect(AnalysisStatus.completed.color == "green")
        #expect(AnalysisStatus.failed.color == "red")
    }
    
    // MARK: - RiskLevel Tests
    
    @Test func riskLevelDisplayNames() {
        #expect(RiskLevel.low.displayName == "Baixo Risco")
        #expect(RiskLevel.moderate.displayName == "Risco Moderado")
        #expect(RiskLevel.high.displayName == "Alto Risco")
        #expect(RiskLevel.urgent.displayName == "Urgente")
    }
    
    @Test func riskLevelColors() {
        #expect(RiskLevel.low.color == "green")
        #expect(RiskLevel.moderate.color == "yellow")
        #expect(RiskLevel.high.color == "orange")
        #expect(RiskLevel.urgent.color == "red")
    }
    
    // MARK: - ImageQuality Tests
    
    @Test func imageQualityDisplayNames() {
        #expect(ImageQuality.poor.displayName == "Baixa")
        #expect(ImageQuality.fair.displayName == "Razoável")
        #expect(ImageQuality.good.displayName == "Boa")
        #expect(ImageQuality.excellent.displayName == "Excelente")
    }
    
    // MARK: - SkinLesionPhoto Tests
    
    @Test func skinLesionPhotoInitialization() {
        let testImageData = Data([1, 2, 3, 4, 5])
        let captureDate = Date()
        let photo = SkinLesionPhoto(
            imageData: testImageData,
            captureDate: captureDate,
            analysisStatus: .pending,
            userNotes: "Test notes"
        )
        
        #expect(photo.imageData == testImageData)
        #expect(photo.captureDate == captureDate)
        #expect(photo.analysisStatus == .pending)
        #expect(photo.userNotes == "Test notes")
        #expect(photo.isDeleted == false)
        #expect(photo.id != UUID())
    }
    
    @Test func skinLesionPhotoStatusUpdate() async throws {
        let photo = SkinLesionPhoto(imageData: Data())
        let initialUpdateTime = photo.lastUpdated
        
        // Small delay to ensure time difference
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        photo.updateStatus(.uploading)
        
        #expect(photo.analysisStatus == .uploading)
        #expect(photo.lastUpdated > initialUpdateTime)
    }
    
    @Test func skinLesionPhotoDeletion() {
        let photo = SkinLesionPhoto(imageData: Data())
        #expect(photo.isDeleted == false)
        
        photo.markAsDeleted()
        #expect(photo.isDeleted == true)
        
        photo.restore()
        #expect(photo.isDeleted == false)
    }
    
    @Test func skinLesionPhotoStatusProperties() {
        let photo = SkinLesionPhoto(imageData: Data(), analysisStatus: .pending)

        #expect(photo.isPendingAnalysis == true)
        #expect(photo.isAnalysisComplete == false)
        #expect(photo.hasError == false)

        photo.updateStatus(.completed)
        // Note: isAnalysisComplete requires analysisResult to be non-nil
        #expect(photo.isPendingAnalysis == false)
        #expect(photo.hasError == false)

        photo.updateStatus(.failed)
        #expect(photo.hasError == true)
    }

    @Test func skinLesionPhotoFormattedDatesReuseSharedFormatter() {
        let originalTimeZone = TimeZone.ReferenceType.default
        let saoPauloTimeZone = TimeZone(secondsFromGMT: -3 * 3600)!
        TimeZone.ReferenceType.default = saoPauloTimeZone
        defer { TimeZone.ReferenceType.default = originalTimeZone }

        var components = DateComponents()
        components.year = 2024
        components.month = 5
        components.day = 10
        components.hour = 15
        components.minute = 45
        components.second = 0
        components.timeZone = saoPauloTimeZone

        let calendar = Calendar(identifier: .gregorian)
        let captureDate = calendar.date(from: components)!
        let photo = SkinLesionPhoto(imageData: Data(), captureDate: captureDate)

        #expect(photo.formattedCaptureDate == "10 de mai. de 2024, 15:45")
        #expect(photo.shortCaptureDate == "10/05/2024")

        let firstIdentifiers = SkinLesionPhoto.testingFormatterIdentifiers()
        let secondIdentifiers = SkinLesionPhoto.testingFormatterIdentifiers()

        #expect(firstIdentifiers.full == secondIdentifiers.full)
        #expect(firstIdentifiers.short == secondIdentifiers.short)
    }

    @Test func skinLesionPhotoDaysSinceCapture() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let photo = SkinLesionPhoto(imageData: Data(), captureDate: yesterday)

        #expect(photo.daysSinceCapture == 1)
    }
    
    // MARK: - AnalysisResult Tests
    
    @Test func analysisResultInitialization() {
        let result = AnalysisResult(
            confidence: 0.85,
            lesionType: "Melanoma",
            riskLevel: .high,
            recommendations: ["Consulte um dermatologista", "Monitore mudanças"]
        )
        
        #expect(result.confidence == 0.85)
        #expect(result.lesionType == "Melanoma")
        #expect(result.riskLevel == .high)
        #expect(result.recommendations.count == 2)
        #expect(result.id != UUID())
    }
    
    @Test func analysisResultConfidencePercentage() {
        let result = AnalysisResult(
            confidence: 0.8567,
            lesionType: "Test",
            riskLevel: .low,
            recommendations: []
        )
        
        #expect(result.confidencePercentage == "85.7%")
    }
    
    @Test func analysisResultRiskAssessment() {
        let highRiskResult = AnalysisResult(
            confidence: 0.9,
            lesionType: "Test",
            riskLevel: .high,
            recommendations: []
        )
        
        let urgentResult = AnalysisResult(
            confidence: 0.95,
            lesionType: "Test",
            riskLevel: .urgent,
            recommendations: []
        )
        
        let lowRiskResult = AnalysisResult(
            confidence: 0.3,
            lesionType: "Test",
            riskLevel: .low,
            recommendations: []
        )
        
        #expect(highRiskResult.isHighRisk == true)
        #expect(urgentResult.isHighRisk == true)
        #expect(lowRiskResult.isHighRisk == false)
        
        #expect(urgentResult.requiresUrgentAttention == true)
        #expect(highRiskResult.requiresUrgentAttention == false)
    }
    
    // MARK: - PhotoMetadata Tests
    
    @Test func photoMetadataInitialization() {
        let metadata = PhotoMetadata(
            deviceInfo: "iPhone 15 Pro",
            imageQuality: .excellent,
            bodyLocation: "Braço direito",
            imageSize: CGSize(width: 1920, height: 1080),
            fileSize: 2048000 // 2MB
        )

        #expect(metadata.deviceInfo == "iPhone 15 Pro")
        #expect(metadata.imageQuality == .excellent)
        #expect(metadata.bodyLocation == "Braço direito")
        #expect(metadata.searchableBodyLocation == "braco direito")
        #expect(metadata.imageSize.width == 1920)
        #expect(metadata.fileSize == 2048000)
    }

    @Test func photoMetadataUpdatesSearchableBodyLocation() {
        let metadata = PhotoMetadata(bodyLocation: "Braço direito")
        #expect(metadata.searchableBodyLocation == "braco direito")

        metadata.bodyLocation = "Perna Esquerda"
        #expect(metadata.searchableBodyLocation == "perna esquerda")

        metadata.bodyLocation = nil
        #expect(metadata.searchableBodyLocation == nil)
    }
    
    @Test func photoMetadataFormatting() {
        let metadata = PhotoMetadata(
            imageSize: CGSize(width: 1920, height: 1080),
            fileSize: 2048000 // 2MB
        )
        
        #expect(metadata.imageDimensions == "1920 x 1080")
        #expect(metadata.fileSizeFormatted.contains("2")) // Should contain "2" for 2MB
        #expect(metadata.fileSizeFormatted.contains("MB"))
    }
    
    @Test func photoMetadataQualityCheck() {
        let goodQuality = PhotoMetadata(imageQuality: .good)
        let excellentQuality = PhotoMetadata(imageQuality: .excellent)
        let poorQuality = PhotoMetadata(imageQuality: .poor)
        
        #expect(goodQuality.isGoodQuality == true)
        #expect(excellentQuality.isGoodQuality == true)
        #expect(poorQuality.isGoodQuality == false)
    }
}
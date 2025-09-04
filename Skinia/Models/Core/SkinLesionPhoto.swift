import Foundation
import SwiftData
import UIKit

@Model
final class SkinLesionPhoto {
    var id: UUID
    var imageData: Data
    var captureDate: Date
    var analysisStatus: AnalysisStatus
    var lastUpdated: Date
    var userNotes: String?
    var isDeleted: Bool
    
    // Relacionamentos
    @Relationship(deleteRule: .cascade)
    var analysisResult: AnalysisResult?
    
    @Relationship(deleteRule: .cascade)
    var metadata: PhotoMetadata?
    
    // Relacionamento com exame (uma foto pertence a um exame)
    var exam: Exam?
    
    init(
        imageData: Data,
        captureDate: Date = Date(),
        analysisStatus: AnalysisStatus = .pending,
        userNotes: String? = nil
    ) {
        self.id = UUID()
        self.imageData = imageData
        self.captureDate = captureDate
        self.analysisStatus = analysisStatus
        self.lastUpdated = Date()
        self.userNotes = userNotes
        self.isDeleted = false
    }
    
    func updateStatus(_ status: AnalysisStatus) {
        self.analysisStatus = status
        self.lastUpdated = Date()
    }
    
    func markAsDeleted() {
        self.isDeleted = true
        self.lastUpdated = Date()
    }
    
    func restore() {
        self.isDeleted = false
        self.lastUpdated = Date()
    }
}

extension SkinLesionPhoto {
    var thumbnailImage: UIImage? {
        return UIImage(data: imageData)
    }
    
    var fullImage: UIImage? {
        return UIImage(data: imageData)
    }
    
    var formattedCaptureDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: captureDate)
    }
    
    var shortCaptureDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: captureDate)
    }
    
    var isAnalysisComplete: Bool {
        return analysisStatus == .completed && analysisResult != nil
    }
    
    var isPendingAnalysis: Bool {
        return analysisStatus == .pending || analysisStatus == .uploading || analysisStatus == .analyzing
    }
    
    var hasError: Bool {
        return analysisStatus == .failed
    }
    
    var statusDisplayText: String {
        return analysisStatus.displayName
    }
    
    var statusColor: String {
        return analysisStatus.color
    }
    
    var statusIcon: String {
        return analysisStatus.systemImage
    }
    
    var daysSinceCapture: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: captureDate, to: Date())
        return components.day ?? 0
    }
    
    var needsAttention: Bool {
        return analysisResult?.requiresUrgentAttention == true
    }
    
    var riskLevel: RiskLevel? {
        return analysisResult?.riskLevel
    }
}
import Foundation
import SwiftData

@Model
final class Exam {
    var id: UUID
    var patientName: String?
    var patientID: String?
    var createdDate: Date
    var lastUpdated: Date
    var isDeleted: Bool
    var examNotes: String?
    
    // Relacionamento com fotos (um exame pode ter múltiplas fotos)
    @Relationship(deleteRule: .cascade)
    var photos: [SkinLesionPhoto] = []
    
    init(
        patientName: String? = nil,
        patientID: String? = nil,
        examNotes: String? = nil,
        createdDate: Date = Date()
    ) {
        self.id = UUID()
        self.patientName = patientName
        self.patientID = patientID
        self.examNotes = examNotes
        self.createdDate = createdDate
        self.lastUpdated = createdDate
        self.isDeleted = false
    }
    
    func updatePatientInfo(name: String?, id: String?) {
        self.patientName = name
        self.patientID = id
        self.lastUpdated = Date()
    }
    
    func addPhoto(_ photo: SkinLesionPhoto) {
        photos.append(photo)
        photo.exam = self
        self.lastUpdated = Date()
    }
    
    func markAsDeleted() {
        self.isDeleted = true
        self.lastUpdated = Date()
        // Mark all photos as deleted too
        photos.forEach { $0.markAsDeleted() }
    }
    
    func restore() {
        self.isDeleted = false
        self.lastUpdated = Date()
    }
}

extension Exam {
    var displayName: String {
        if let name = patientName, !name.isEmpty {
            return name
        } else if let id = patientID, !id.isEmpty {
            return "ID: \(id)"
        } else {
            return "Exame \(shortFormattedDate)"
        }
    }
    
    var patientIdentifier: String {
        if let name = patientName, !name.isEmpty,
           let id = patientID, !id.isEmpty {
            return "\(name) (ID: \(id))"
        } else if let name = patientName, !name.isEmpty {
            return name
        } else if let id = patientID, !id.isEmpty {
            return "ID: \(id)"
        } else {
            return "Paciente não identificado"
        }
    }
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: createdDate)
    }
    
    var shortFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: createdDate)
    }
    
    var photoCount: Int {
        return photos.filter { !$0.isDeleted }.count
    }
    
    var completedAnalysesCount: Int {
        return photos.filter { !$0.isDeleted && $0.analysisStatus == .completed }.count
    }
    
    var pendingAnalysesCount: Int {
        return photos.filter { !$0.isDeleted && $0.isPendingAnalysis }.count
    }
    
    var hasUrgentResults: Bool {
        return photos.contains { !$0.isDeleted && $0.needsAttention }
    }
    
    var daysSinceCreation: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: createdDate, to: Date())
        return components.day ?? 0
    }
}
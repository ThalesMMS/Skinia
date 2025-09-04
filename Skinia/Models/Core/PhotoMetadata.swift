import Foundation
import SwiftData
import UIKit

@Model
final class PhotoMetadata {
    var id: UUID
    var deviceInfo: String
    var imageQuality: ImageQuality
    var bodyLocation: String?
    var imageSize: CGSize
    var fileSize: Int64 // Em bytes
    var captureSettings: String? // Informações da câmera (ISO, exposição, etc.)
    var hasFlash: Bool
    var orientation: String
    var creationDate: Date
    
    // Relacionamento com a foto
    var photo: SkinLesionPhoto?
    
    init(
        deviceInfo: String = UIDevice.current.name,
        imageQuality: ImageQuality = .good,
        bodyLocation: String? = nil,
        imageSize: CGSize = .zero,
        fileSize: Int64 = 0,
        captureSettings: String? = nil,
        hasFlash: Bool = false,
        orientation: String = "portrait",
        creationDate: Date = Date()
    ) {
        self.id = UUID()
        self.deviceInfo = deviceInfo
        self.imageQuality = imageQuality
        self.bodyLocation = bodyLocation
        self.imageSize = imageSize
        self.fileSize = fileSize
        self.captureSettings = captureSettings
        self.hasFlash = hasFlash
        self.orientation = orientation
        self.creationDate = creationDate
    }
}

extension PhotoMetadata {
    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var imageDimensions: String {
        return "\(Int(imageSize.width)) x \(Int(imageSize.height))"
    }
    
    var formattedCreationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: creationDate)
    }
    
    var isGoodQuality: Bool {
        return imageQuality == .good || imageQuality == .excellent
    }
}
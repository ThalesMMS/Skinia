import Foundation
import SwiftData
import UIKit

@Model
final class PhotoMetadata {
    var id: UUID
    var deviceInfo: String
    var imageQuality: ImageQuality
    var bodyLocation: String?
    var imageWidth: Double
    var imageHeight: Double
    var fileSize: Int64 // Em bytes
    var captureSettings: String? // Informações da câmera (ISO, exposição, etc.)
    var hasFlash: Bool
    var orientation: String
    var creationDate: Date
    
    // Relacionamento inverso removido para evitar ciclos no SwiftData
    
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
        self.imageWidth = Double(imageSize.width)
        self.imageHeight = Double(imageSize.height)
        self.fileSize = fileSize
        self.captureSettings = captureSettings
        self.hasFlash = hasFlash
        self.orientation = orientation
        self.creationDate = creationDate
    }
}

extension PhotoMetadata {
    var imageSize: CGSize {
        get {
            return CGSize(width: imageWidth, height: imageHeight)
        }
        set {
            imageWidth = Double(newValue.width)
            imageHeight = Double(newValue.height)
        }
    }
    
    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var imageDimensions: String {
        return "\(Int(imageWidth)) x \(Int(imageHeight))"
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
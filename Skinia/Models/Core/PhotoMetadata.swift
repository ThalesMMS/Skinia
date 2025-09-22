import Foundation
import SwiftData
import UIKit

@Model
final class PhotoMetadata {
    var id: UUID
    var deviceInfo: String
    var imageQuality: ImageQuality
    var bodyLocation: String? {
        didSet {
            refreshSearchableBodyLocation()
        }
    }
    var searchableBodyLocation: String?
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
        self.searchableBodyLocation = PhotoMetadata.normalizedBodyLocation(from: bodyLocation)
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
    func refreshSearchableBodyLocation() {
        searchableBodyLocation = PhotoMetadata.normalizedBodyLocation(from: bodyLocation)
    }

    static func populateMissingSearchableBodyLocations(in context: ModelContext) throws {
        let predicate = #Predicate<PhotoMetadata> { metadata in
            metadata.bodyLocation != nil && metadata.searchableBodyLocation == nil
        }
        let descriptor = FetchDescriptor<PhotoMetadata>(predicate: predicate)

        let metadataToUpdate = try context.fetch(descriptor)
        guard !metadataToUpdate.isEmpty else { return }

        metadataToUpdate.forEach { $0.refreshSearchableBodyLocation() }
        try context.save()
    }

    private static func normalizedBodyLocation(from value: String?) -> String? {
        guard let value,
              !value.isEmpty else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return trimmed
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

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
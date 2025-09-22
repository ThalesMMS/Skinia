import Foundation
import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif

enum PreviewPhotoFactory {
    enum Sample: CaseIterable {
        case completedLowRisk
        case pending
        case completedUrgent
    }

    static func makeSamplePhotos() -> [SkinLesionPhoto] {
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

        let completedLowRisk = makePhoto(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            captureDate: baseDate.addingTimeInterval(-2 * 24 * 60 * 60),
            status: .completed,
            userNotes: "Lesão no braço direito",
            bodyLocation: "Braço direito",
            imageSize: CGSize(width: 1024, height: 1024),
            fileSize: 2_048_000,
            sampleImage: .completedLowRisk,
            result: AnalysisResult(
                confidence: 0.87,
                lesionType: "Nevo Melanocítico",
                riskLevel: .low,
                recommendations: [
                    "Monitorar mudanças",
                    "Consulta de rotina em 6 meses"
                ]
            )
        )

        let pending = makePhoto(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            captureDate: baseDate.addingTimeInterval(-3 * 60 * 60),
            status: .pending,
            userNotes: "Nova lesão nas costas",
            bodyLocation: "Costas",
            imageSize: CGSize(width: 1920, height: 1080),
            fileSize: 3_200_000,
            sampleImage: .pending,
            result: nil
        )

        let completedUrgent = makePhoto(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            captureDate: baseDate.addingTimeInterval(-1 * 24 * 60 * 60),
            status: .completed,
            userNotes: "Lesão que mudou de cor",
            bodyLocation: "Perna esquerda",
            imageSize: CGSize(width: 1024, height: 768),
            fileSize: 1_800_000,
            sampleImage: .completedUrgent,
            result: AnalysisResult(
                confidence: 0.92,
                lesionType: "Possível Melanoma",
                riskLevel: .urgent,
                recommendations: [
                    "Consultar dermatologista imediatamente",
                    "Não aguardar",
                    "Procurar atendimento especializado"
                ]
            )
        )

        return [completedLowRisk, pending, completedUrgent]
    }

    static func makeSamplePhoto(_ sample: Sample = .completedLowRisk) -> SkinLesionPhoto {
        switch sample {
        case .completedLowRisk:
            return makeSamplePhotos()[0]
        case .pending:
            return makeSamplePhotos()[1]
        case .completedUrgent:
            return makeSamplePhotos()[2]
        }
    }

    @MainActor
    static func seed(repository: any PhotoRepositoryProtocol) throws {
        try repository.deleteAll()
        for photo in makeSamplePhotos() {
            try repository.save(photo)
        }
    }

    private static func makePhoto(
        id: UUID,
        captureDate: Date,
        status: AnalysisStatus,
        userNotes: String?,
        bodyLocation: String?,
        imageSize: CGSize,
        fileSize: Int64,
        sampleImage: Sample,
        result: AnalysisResult?
    ) -> SkinLesionPhoto {
        let imageData = imageData(for: sampleImage)
        let photo = SkinLesionPhoto(
            imageData: imageData,
            captureDate: captureDate,
            analysisStatus: status,
            userNotes: userNotes
        )
        photo.id = id

        if let result {
            photo.analysisResult = result
        }

        let metadata = PhotoMetadata(
            deviceInfo: "Preview Device",
            imageQuality: status == .pending ? .excellent : .good,
            bodyLocation: bodyLocation,
            imageSize: imageSize,
            fileSize: fileSize,
            captureSettings: "ISO 100, f/1.8",
            hasFlash: false,
            orientation: "portrait",
            creationDate: captureDate
        )
        photo.metadata = metadata

        return photo
    }

    private static func imageData(for sample: Sample) -> Data {
        #if canImport(UIKit)
        let color: UIColor
        switch sample {
        case .completedLowRisk:
            color = .systemBrown
        case .pending:
            color = .systemRed
        case .completedUrgent:
            color = .systemBlue
        }

        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        defer { UIGraphicsEndImageContext() }

        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))

        return UIGraphicsGetImageFromCurrentImageContext()?.pngData() ?? Data()
        #else
        switch sample {
        case .completedLowRisk:
            return Data(repeating: 0xAA, count: 256)
        case .pending:
            return Data(repeating: 0xBB, count: 256)
        case .completedUrgent:
            return Data(repeating: 0xCC, count: 256)
        }
        #endif
    }
}


import XCTest
import PDFKit
import UIKit
@testable import Skinia

@MainActor
final class AnalysisExportServiceTests: XCTestCase {

    private var service: AnalysisExportService!

    override func setUp() {
        super.setUp()
        service = AnalysisExportService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testExportPhotosAsCSVCreatesFileWithExpectedContent() throws {
        let photos = makeSamplePhotos()
        let url = try service.exportPhotos(photos, format: .csv)

        let csvContent = try String(contentsOf: url, encoding: .utf8)
        let rows = csvContent.components(separatedBy: "\n")
        XCTAssertEqual(rows.first, "ID,Data da Captura,Status,Nível de Risco,Tipo de Lesão,Confiança,Localização,Qualidade da Imagem,Notas,Data da Análise")
        XCTAssertEqual(rows.count, photos.count + 1)

        for photo in photos {
            XCTAssertTrue(csvContent.contains(photo.id.uuidString))
        }

        try? FileManager.default.removeItem(at: url)
    }

    func testExportPhotosAsPDFGeneratesDocumentWithPhotoCountPages() throws {
        let photos = makeSamplePhotos()
        let url = try service.exportPhotos(photos, format: .pdf)

        let document = PDFDocument(url: url)
        XCTAssertNotNil(document)
        XCTAssertEqual(document?.pageCount, photos.count)

        try? FileManager.default.removeItem(at: url)
    }

    private func makeSamplePhotos() -> [SkinLesionPhoto] {
        let firstPhoto = SkinLesionPhoto(imageData: makeImageData(color: .systemBlue))
        firstPhoto.userNotes = "Paciente relata leve coceira"
        firstPhoto.metadata = PhotoMetadata(
            bodyLocation: "Antebraço",
            imageSize: CGSize(width: 200, height: 200),
            fileSize: 1024
        )
        firstPhoto.analysisResult = AnalysisResult(
            confidence: 0.82,
            lesionType: "Nevus",
            riskLevel: .low,
            recommendations: ["Continuar monitoramento"],
            analysisDate: Date()
        )

        let secondPhoto = SkinLesionPhoto(imageData: makeImageData(color: .systemRed))
        secondPhoto.metadata = PhotoMetadata(
            bodyLocation: "Costas",
            imageSize: CGSize(width: 220, height: 220),
            fileSize: 2048
        )
        secondPhoto.analysisResult = AnalysisResult(
            confidence: 0.64,
            lesionType: "Melanoma",
            riskLevel: .high,
            recommendations: ["Encaminhar para biópsia"],
            analysisDate: Date()
        )

        return [firstPhoto, secondPhoto]
    }

    private func makeImageData(color: UIColor) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
        }
        return image.pngData() ?? Data()
    }
}

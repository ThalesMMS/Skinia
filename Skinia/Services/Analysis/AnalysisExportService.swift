import Foundation
import PDFKit
import UIKit

enum AnalysisExportFormat {
    case pdf
    case csv
}

@MainActor
protocol AnalysisExportServiceProtocol {
    func exportPhotos(_ photos: [SkinLesionPhoto], format: AnalysisExportFormat) throws -> URL
}

@MainActor
final class AnalysisExportService: AnalysisExportServiceProtocol {

    enum ExportError: LocalizedError {
        case noPhotos
        case failedToCreatePDFPage
        case failedToWritePDF
        case failedToWriteCSV

        var errorDescription: String? {
            switch self {
            case .noPhotos:
                return "Nenhuma foto disponível para exportação."
            case .failedToCreatePDFPage:
                return "Não foi possível gerar o relatório em PDF."
            case .failedToWritePDF:
                return "Falha ao salvar o arquivo PDF."
            case .failedToWriteCSV:
                return "Falha ao salvar o arquivo CSV."
            }
        }
    }

    private let pageSize = CGSize(width: 612, height: 792)
    private let pageMargins = UIEdgeInsets(top: 40, left: 36, bottom: 40, right: 36)
    private let dateFormatter: DateFormatter
    private let dateTimeFormatter: DateFormatter

    init() {
        let captureFormatter = DateFormatter()
        captureFormatter.dateStyle = .medium
        captureFormatter.timeStyle = .short
        captureFormatter.locale = Locale(identifier: "pt_BR")
        self.dateFormatter = captureFormatter

        let fullFormatter = DateFormatter()
        fullFormatter.dateStyle = .medium
        fullFormatter.timeStyle = .short
        fullFormatter.locale = Locale(identifier: "pt_BR")
        self.dateTimeFormatter = fullFormatter
    }

    func exportPhotos(_ photos: [SkinLesionPhoto], format: AnalysisExportFormat) throws -> URL {
        guard !photos.isEmpty else {
            throw ExportError.noPhotos
        }

        switch format {
        case .pdf:
            return try exportAsPDF(photos)
        case .csv:
            return try exportAsCSV(photos)
        }
    }

    private func exportAsPDF(_ photos: [SkinLesionPhoto]) throws -> URL {
        let document = PDFDocument()

        for (index, photo) in photos.enumerated() {
            guard let pageImage = renderPageImage(for: photo, index: index + 1, total: photos.count),
                  let page = PDFPage(image: pageImage) else {
                throw ExportError.failedToCreatePDFPage
            }

            document.insert(page, at: index)
        }

        let url = makeTemporaryURL(extension: "pdf")

        guard document.write(to: url) else {
            throw ExportError.failedToWritePDF
        }

        return url
    }

    private func renderPageImage(for photo: SkinLesionPhoto, index: Int, total: Int) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: pageSize)

        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: pageSize))

            let availableWidth = pageSize.width - pageMargins.left - pageMargins.right
            var currentY = pageMargins.top

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            let title = "Relatório de Análise \(index) de \(total)"
            let titleRect = CGRect(x: pageMargins.left, y: currentY, width: availableWidth, height: 30)
            title.draw(in: titleRect, withAttributes: titleAttributes)
            currentY += 40

            if let photoImage = UIImage(data: photo.imageData) {
                let maxImageHeight: CGFloat = 240
                let aspectRatio = photoImage.size.width / max(photoImage.size.height, 1)
                let targetWidth = min(availableWidth, photoImage.size.width)
                let targetHeight = min(maxImageHeight, targetWidth / max(aspectRatio, 0.1))
                let imageRect = CGRect(
                    x: pageMargins.left,
                    y: currentY,
                    width: targetWidth,
                    height: targetHeight
                )
                photoImage.draw(in: imageRect)
                currentY += targetHeight + 24
            }

            let details = buildDetails(for: photo)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 6
            let detailsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.label,
                .paragraphStyle: paragraphStyle
            ]
            let detailsString = details.joined(separator: "\n")
            let detailsRect = CGRect(
                x: pageMargins.left,
                y: currentY,
                width: availableWidth,
                height: pageSize.height - currentY - pageMargins.bottom
            )
            detailsString.draw(in: detailsRect, withAttributes: detailsAttributes)

            currentY += detailsRect.height + 16

            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let footerText = "Gerado em: \(dateTimeFormatter.string(from: Date()))"
            let footerRect = CGRect(
                x: pageMargins.left,
                y: pageSize.height - pageMargins.bottom - 12,
                width: availableWidth,
                height: 12
            )
            footerText.draw(in: footerRect, withAttributes: footerAttributes)
        }

        return image
    }

    private func buildDetails(for photo: SkinLesionPhoto) -> [String] {
        var details: [String] = []
        details.append("Identificador: \(photo.id.uuidString)")
        details.append("Capturada em: \(dateFormatter.string(from: photo.captureDate))")
        details.append("Status da análise: \(photo.analysisStatus.displayName)")

        if let metadata = photo.metadata {
            if let location = metadata.bodyLocation {
                details.append("Localização: \(location)")
            }
            details.append("Dimensões da imagem: \(Int(metadata.imageWidth)) x \(Int(metadata.imageHeight))")
            details.append("Qualidade da imagem: \(metadata.imageQuality.displayName)")
        }

        if let notes = photo.userNotes, !notes.isEmpty {
            details.append("Observações do paciente: \(notes)")
        }

        if let result = photo.analysisResult {
            details.append("Tipo identificado: \(result.lesionType)")
            details.append("Nível de risco: \(result.riskLevel.displayName)")
            details.append("Confiança do modelo: \(String(format: "%.1f%%", result.confidence * 100)))")
            if !result.recommendationsList.isEmpty {
                details.append("Recomendações: \(result.recommendationsList.joined(separator: ", "))")
            }
            details.append("Data da análise: \(dateTimeFormatter.string(from: result.analysisDate))")
        }

        return details
    }

    private func exportAsCSV(_ photos: [SkinLesionPhoto]) throws -> URL {
        var lines: [String] = []
        lines.append("ID,Data da Captura,Status,Nível de Risco,Tipo de Lesão,Confiança,Localização,Qualidade da Imagem,Notas,Data da Análise")

        for photo in photos {
            let result = photo.analysisResult
            let metadata = photo.metadata
            let columns: [String] = [
                csvField(photo.id.uuidString),
                csvField(dateFormatter.string(from: photo.captureDate)),
                csvField(photo.analysisStatus.displayName),
                csvField(result?.riskLevel.displayName),
                csvField(result?.lesionType),
                csvField(result.map { String(format: "%.2f", $0.confidence) }),
                csvField(metadata?.bodyLocation),
                csvField(metadata?.imageQuality.displayName),
                csvField(photo.userNotes),
                csvField(result.map { dateTimeFormatter.string(from: $0.analysisDate) })
            ]
            lines.append(columns.joined(separator: ","))
        }

        let csvString = lines.joined(separator: "\n")
        guard let data = csvString.data(using: .utf8) else {
            throw ExportError.failedToWriteCSV
        }

        let url = makeTemporaryURL(extension: "csv")
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw ExportError.failedToWriteCSV
        }

        return url
    }

    private func csvField(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "" }
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    private func makeTemporaryURL(extension fileExtension: String) -> URL {
        let directory = FileManager.default.temporaryDirectory
        let filename = "analysis-export-\(UUID().uuidString).\(fileExtension)"
        return directory.appendingPathComponent(filename)
    }
}

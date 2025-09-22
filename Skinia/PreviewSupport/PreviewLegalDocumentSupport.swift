#if DEBUG
import SwiftUI

final class PreviewLegalDocumentOpener: ObservableObject, LegalDocumentOpening {
    @Published var lastOpenedDocument: LegalDocument?

    func open(_ document: LegalDocument) {
        lastOpenedDocument = document
    }
}

struct PreviewLegalDocumentBanner: View {
    let title: String

    var body: some View {
        HStack {
            Image(systemName: "checkmark.seal")
                .font(.headline)
                .foregroundColor(.white)

            Text("Documento simulado: \(title)")
                .font(.footnote)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.7))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Documento legal simulado aberto: \(title)")
    }
}

struct PreviewInstructionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(.top)
            .accessibilityLabel(text)
    }
}
#endif


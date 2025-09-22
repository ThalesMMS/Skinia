import SwiftUI

struct AnalysisUserNotesSectionView: View {
    let notes: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Observações do Paciente")
                .font(.headline)

            if let notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
            } else {
                Text("Nenhuma observação adicionada.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(16)
    }
}

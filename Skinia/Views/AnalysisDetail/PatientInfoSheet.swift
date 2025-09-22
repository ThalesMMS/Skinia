import SwiftUI

struct PatientInfoSheet: View {
    let photo: SkinLesionPhoto
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.Colors.primary)

                        Text("Informações do Paciente")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, DesignSystem.Spacing.lg)

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        infoCard(
                            title: "Data da Análise",
                            value: photo.formattedCaptureDate,
                            icon: "calendar"
                        )

                        if let bodyLocation = photo.metadata?.bodyLocation {
                            infoCard(
                                title: "Local da Lesão",
                                value: bodyLocation,
                                icon: "figure.walk"
                            )
                        }

                        infoCard(
                            title: "Status da Análise",
                            value: photo.analysisStatus.displayName,
                            icon: "stethoscope"
                        )

                        if let notes = photo.userNotes, !notes.isEmpty {
                            infoCard(
                                title: "Observações",
                                value: notes,
                                icon: "note.text",
                                isMultiline: true
                            )
                        }
                    }

                    Spacer()
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .navigationTitle("Paciente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func infoCard(title: String, value: String, icon: String, isMultiline: Bool = false) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.medicalCaption)
                    .foregroundColor(DesignSystem.Colors.textSecondary)

                Text(value)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.text)
                    .lineLimit(isMultiline ? nil : 1)
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
    }
}

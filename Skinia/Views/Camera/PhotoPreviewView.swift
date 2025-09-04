import SwiftUI
import ImageIO
import CoreGraphics

struct PhotoPreviewView: View {
    let image: UIImage
    let metadata: [String: Any]?
    let onSave: (String, String, String, String) -> Void  // bodyLocation, userNotes, patientName, patientID
    let onRetake: () -> Void
    
    @State private var showingBodyLocationPicker = false
    @State private var selectedBodyLocation: String = ""
    @State private var userNotes: String = ""
    @State private var patientName: String = ""
    @State private var patientID: String = ""
    
    private let bodyLocationOptions = [
        "Rosto", "Pescoço", "Braço Direito", "Braço Esquerdo", 
        "Mão Direita", "Mão Esquerda", "Peito", "Costas", 
        "Abdomen", "Perna Direita", "Perna Esquerda", 
        "Pé Direito", "Pé Esquerdo", "Outros"
    ]
    
    // MARK: - Computed Properties
    
    private var isPatientInfoValid: Bool {
        return !patientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
               !patientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Scrollable content including image and form
                ScrollView {
                    VStack(spacing: 20) {
                        // Image preview
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
                            .clipped()
                            .cornerRadius(12)
                            .padding(.horizontal)
                        // Patient Information Section
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("Informações do Paciente")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.text)
                            
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                // Patient Name Field
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                    Text("Nome do Paciente")
                                        .font(DesignSystem.Typography.medicalCaption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    
                                    TextField("Digite o nome completo", text: $patientName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .font(DesignSystem.Typography.body)
                                }
                                
                                // Patient ID Field
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                    Text("ID/Registro do Paciente")
                                        .font(DesignSystem.Typography.medicalCaption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    
                                    TextField("Ex: 12345 ou RG123456", text: $patientID)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .font(DesignSystem.Typography.body)
                                }
                                
                                // Validation message
                                if patientName.isEmpty && patientID.isEmpty {
                                    HStack {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(DesignSystem.Colors.warning)
                                        Text("Preencha pelo menos o nome ou ID do paciente")
                                            .font(DesignSystem.Typography.caption)
                                            .foregroundColor(DesignSystem.Colors.warning)
                                    }
                                    .padding(.top, DesignSystem.Spacing.xs)
                                }
                            }
                        }
                        .padding(DesignSystem.Spacing.lg)
                        .cardStyle()
                        
                        // Body location picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Local do Corpo")
                                .font(.headline)
                            
                            Button {
                                showingBodyLocationPicker = true
                            } label: {
                                HStack {
                                    Text(selectedBodyLocation.isEmpty ? "Selecionar local..." : selectedBodyLocation)
                                        .foregroundColor(selectedBodyLocation.isEmpty ? .secondary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                        }
                        
                        // Notes section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Observações")
                                .font(.headline)
                            
                            TextField("Adicione observações sobre a lesão (opcional)", text: $userNotes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                        }
                        
                        // Metadata info
                        if let metadata = metadata {
                            metadataSection(metadata)
                        }
                        
                        // Add some bottom padding for safe scrolling
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        onSave(selectedBodyLocation, userNotes, patientName, patientID)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Salvar Foto")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isPatientInfoValid && !selectedBodyLocation.isEmpty ? Color.blue : Color(.systemGray4))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isPatientInfoValid || selectedBodyLocation.isEmpty)
                    
                    Button {
                        onRetake()
                    } label: {
                        HStack {
                            Image(systemName: "camera.rotate")
                            Text("Tirar Nova Foto")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Nova Foto")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingBodyLocationPicker) {
                bodyLocationPicker
            }
        }
    }
    
    private var bodyLocationPicker: some View {
        NavigationView {
            List {
                ForEach(bodyLocationOptions, id: \.self) { location in
                    HStack {
                        Text(location)
                        Spacer()
                        if selectedBodyLocation == location {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedBodyLocation = location
                        showingBodyLocationPicker = false
                    }
                }
            }
            .navigationTitle("Local do Corpo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") {
                        showingBodyLocationPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func metadataSection(_ metadata: [String: Any]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Informações da Captura")
                .font(.headline)
            
            VStack(spacing: 6) {
                if let dimensions = extractImageDimensions(metadata) {
                    metadataRow(label: "Dimensões", value: dimensions)
                }
                
                if let orientation = extractOrientation(metadata) {
                    metadataRow(label: "Orientação", value: orientation)
                }
                
                if let hasFlash = extractFlashInfo(metadata) {
                    metadataRow(label: "Flash", value: hasFlash ? "Usado" : "Não usado")
                }
                
                metadataRow(label: "Data/Hora", value: Date().formatted(date: .abbreviated, time: .shortened))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Metadata Extraction Helpers
    
    private func extractImageDimensions(_ metadata: [String: Any]) -> String? {
        if let tiffDict = metadata["{TIFF}"] as? [String: Any],
           let width = tiffDict["ImageWidth"] as? Int,
           let height = tiffDict["ImageLength"] as? Int {
            return "\(width) x \(height)"
        }
        return nil
    }
    
    private func extractOrientation(_ metadata: [String: Any]) -> String? {
        if let orientation = metadata["Orientation"] as? Int {
            switch orientation {
            case 1: return "Normal"
            case 3: return "180°"
            case 6: return "90° CW"
            case 8: return "90° CCW"
            default: return "Outros"
            }
        }
        return nil
    }
    
    private func extractFlashInfo(_ metadata: [String: Any]) -> Bool? {
        if let exifDict = metadata["{Exif}"] as? [String: Any],
           let flash = exifDict["Flash"] as? Int {
            return flash != 0
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    let sampleImage = UIImage(systemName: "photo") ?? UIImage()
    
    PhotoPreviewView(
        image: sampleImage,
        metadata: nil,
        onSave: { location, notes, patientName, patientID in 
            print("Save tapped - Location: \(location), Notes: \(notes), Patient: \(patientName), ID: \(patientID)") 
        },
        onRetake: { print("Retake tapped") }
    )
}
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
        VStack(spacing: 0) {
            // Simple header
            HStack {
                Button("Cancelar") {
                    onRetake()
                }
                
                Spacer()
                
                Text("Nova Foto")
                    .font(.headline)
                
                Spacer()
                
                Text("Cancelar")
                    .opacity(0)
            }
            .padding()
            
            List {
                Section {
                    // Image preview
                    HStack {
                        Spacer()
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                        Spacer()
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    .listRowBackground(Color.clear)
                }
                
                Section(header: Text("Informações do Paciente")) {
                    VStack(alignment: .leading) {
                        Text("Nome do Paciente")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Digite o nome completo", text: $patientName)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .submitLabel(.next)
                            .onSubmit {
                                // Move focus to next field - will be handled by iOS
                            }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("ID/Registro do Paciente")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Ex: 12345 ou RG123456", text: $patientID)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.done)
                            .onSubmit {
                                // Dismiss keyboard
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                    }
                    
                    if patientName.isEmpty && patientID.isEmpty {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.orange)
                            Text("Preencha pelo menos um campo")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Section(header: Text("Local do Corpo")) {
                    Button {
                        print("📍 Body location button tapped")
                        showingBodyLocationPicker = true
                    } label: {
                        HStack {
                            Text(selectedBodyLocation.isEmpty ? "Selecionar local..." : selectedBodyLocation)
                                .foregroundColor(selectedBodyLocation.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Section(header: Text("Observações")) {
                    TextField("Adicione observações sobre a lesão (opcional)", text: $userNotes, axis: .vertical)
                        .lineLimit(3...6)
                        .autocorrectionDisabled()
                }
            }
            .listStyle(InsetGroupedListStyle())
            .scrollDismissesKeyboard(.interactively)
            
            // Action buttons
            VStack(spacing: 12) {
                Button {
                    onSave(selectedBodyLocation, userNotes, patientName, patientID)
                } label: {
                    Text("Salvar Foto")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isPatientInfoValid && !selectedBodyLocation.isEmpty ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isPatientInfoValid || selectedBodyLocation.isEmpty)
                
                Button {
                    onRetake()
                } label: {
                    Text("Tirar Nova Foto")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.blue)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingBodyLocationPicker) {
            bodyLocationPicker
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Pronto") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
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
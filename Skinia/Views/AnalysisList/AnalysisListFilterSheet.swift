import SwiftUI

struct AnalysisListFilterSheet: View {
    let viewModel: AnalysisListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section("Filtrar por Status") {
                    ForEach([AnalysisStatus?.none] + viewModel.statusFilterOptions.map { Optional($0) }, id: \.self) { status in
                        HStack {
                            if let status = status {
                                StatusBadge(status: status)
                            } else {
                                Text("Todos")
                                    .fontWeight(.medium)
                            }

                            Spacer()

                            if viewModel.selectedStatusFilter == status {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.setStatusFilter(status)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Concluído") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

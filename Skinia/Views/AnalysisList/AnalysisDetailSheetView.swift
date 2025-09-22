import SwiftUI

struct AnalysisDetailSheetView: View {
    @ObservedObject var sheetState: AnalysisDetailSheetState
    let dependencyContainer: DependencyContainer

    var body: some View {
        Group {
            if let photo = sheetState.selectedPhoto {
                NavigationView {
                    AnalysisDetailView(
                        photo: photo,
                        photoRepository: dependencyContainer.photoRepository,
                        analysisService: dependencyContainer.analysisService
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Fechar") {
                                sheetState.hideSheet()
                            }
                        }
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .environment(\.analysisService, dependencyContainer.analysisService)
                .environment(\.notificationManager, dependencyContainer.notificationManager)
            } else {
                VStack(spacing: 12) {
                    Text("Error: Photo not found")
                        .foregroundColor(.red)
                    Button("Close") {
                        sheetState.hideSheet()
                    }
                }
                .padding()
            }
        }
    }
}

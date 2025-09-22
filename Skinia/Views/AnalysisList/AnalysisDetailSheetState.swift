import SwiftUI

final class AnalysisDetailSheetState: ObservableObject {
    @Published var selectedPhoto: SkinLesionPhoto?
    @Published var isShowing = false

    func showSheet(with photo: SkinLesionPhoto) {
        print("🔍 SheetState: Setting photo \(photo.id) and showing sheet")
        selectedPhoto = photo
        isShowing = true
    }

    func hideSheet() {
        print("🔍 SheetState: Hiding sheet and clearing photo")
        isShowing = false
        selectedPhoto = nil
    }
}

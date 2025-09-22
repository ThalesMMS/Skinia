import SwiftUI

final class AnalysisDetailSheetState: ObservableObject {
    @Published var selectedPhoto: SkinLesionPhoto?
    @Published var isShowing = false

    func showSheet(with photo: SkinLesionPhoto) {
        selectedPhoto = photo
        isShowing = true
    }

    func hideSheet() {
        isShowing = false
        selectedPhoto = nil
    }
}

import SwiftUI

struct SaveErrorAlertModifier: ViewModifier {
    @Binding var error: Error?
    let retryAction: () -> Void

    func body(content: Content) -> some View {
        content.alert(
            "Não foi possível salvar a foto",
            isPresented: Binding(
                get: { error != nil },
                set: { isPresented in
                    if !isPresented {
                        error = nil
                    }
                }
            )
        ) {
            Button("Tentar novamente") {
                let shouldRetry = error != nil
                error = nil
                if shouldRetry {
                    retryAction()
                }
            }
            Button("Cancelar", role: .cancel) {
                error = nil
            }
        } message: {
            Text("Ocorreu um problema ao salvar sua foto. Verifique sua conexão e tente novamente.")
        }
    }
}

extension View {
    func saveErrorAlert(error: Binding<Error?>, retryAction: @escaping () -> Void) -> some View {
        modifier(SaveErrorAlertModifier(error: error, retryAction: retryAction))
    }
}

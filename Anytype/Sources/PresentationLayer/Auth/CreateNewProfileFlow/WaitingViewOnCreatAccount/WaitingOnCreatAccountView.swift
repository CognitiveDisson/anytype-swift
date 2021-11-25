import SwiftUI

struct WaitingOnCreatAccountView: View {
    @StateObject var viewModel: WaitingOnCreatAccountViewModel
    
    var body: some View {
        VStack {
            WaitingView(
                text: "Setting up the wallet".localized,
                showError: $viewModel.showError,
                errorText: $viewModel.error,
                onErrorTap: {
                    viewModel.showWaitingView = false
                }
            )
        }
        .onAppear {
            self.viewModel.createAccount()
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}

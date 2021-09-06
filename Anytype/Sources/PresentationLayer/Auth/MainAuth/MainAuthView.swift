import SwiftUI


struct MainAuthView: View {
    @ObservedObject var viewModel: MainAuthViewModel
    @State private var showLoginView: Bool = false
    
    var body: some View {
        ZStack {
            navigation
            Gradients.mainBackground()
            contentView
                
            .errorToast(
                isShowing: $viewModel.isShowingError, errorText: viewModel.error
            )
        }
        .navigationBarHidden(true)
        .modifier(LogoOverlay())
        .onAppear {
            viewModel.viewLoaded()
        }
    }
    
    private var contentView: some View {
        VStack() {
            Spacer()
            bottomSheet
                .padding(20)
        }
    }
    
    private var bottomSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                AnytypeText("Welcome to Anytype", style: .heading, color: .textPrimary)
                Spacer.fixedHeight(11)
                AnytypeText("OrganizeEverythingDescription", style: .uxCalloutRegular, color: .textPrimary)
                Spacer.fixedHeight(18)
                buttons
            }
            .padding(EdgeInsets(top: 23, leading: 20, bottom: 10, trailing: 20))
        }
        .background(Color.background)
        .cornerRadius(16.0)
    }
    
    private var buttons: some View {
        HStack(spacing: 10) {
            StandardButton(text: "Sign up", style: .secondary) {
                viewModel.singUp()
            }
            
            NavigationLink(
                destination: viewModel.loginView()
            ) {
                StandardButtonView(text: "Login", style: .primary)
            }
        }
    }
    
    private var navigation: some View {
        NavigationLink(
            destination: viewModel.signUpFlow(),
            isActive: $viewModel.showSignUpFlow
        ) {
            EmptyView()
        }
    }
}


struct MainAuthView_Previews : PreviewProvider {
    static var previews: some View {
        MainAuthView(viewModel: MainAuthViewModel())
    }
}

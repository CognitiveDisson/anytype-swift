import SwiftUI

struct AlphaInviteCodeView: View {
    @StateObject var signUpData: SignUpData
    @State private var showCreateNewProfile = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Gradients.mainBackground()
            bottomSheet
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
    
    private var bottomSheet: some View {
        VStack(spacing: 0) {
            Spacer()
            contentView
                .padding(20)
        }
    }
    
    
    private var contentView: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                AnytypeText("Enter your invitation code".localized, style: .heading, color: .textPrimary)
                Spacer.fixedHeight(11)
                AnytypeText("Do not have invite".localized, style: .uxCalloutRegular, color: .textPrimary)
                Spacer.fixedHeight(30)
                
                AutofocusedTextField(title: "", text: $signUpData.inviteCode)
                    .disableAutocorrection(true)
                    .font(AnytypeFontBuilder.font(anytypeFont: .uxBodyRegular))
                    .foregroundColor(.textPrimary)
                    .placeholder(when: signUpData.inviteCode.isEmpty) {
                        AnytypeText("Invitation code", style: .uxBodyRegular, color: .grayscale50)
                    }
                    .modifier(DividerModifier(spacing: 11.5))
                Spacer.fixedHeight(20)
                
                buttons
            }
            .padding(EdgeInsets(top: 23, leading: 20, bottom: 10, trailing: 20))
        }
        .background(Color.background)
        .cornerRadius(16.0)
    }
    
    private var buttons: some View {
        HStack(spacing: 10) {
            StandardButton(text: "Back".localized, style: .secondary) {
                presentationMode.wrappedValue.dismiss()
            }
            
            NavigationLink(
                destination: CreateNewProfileView(
                    viewModel: CreateNewProfileViewModel(),
                    showCreateNewProfile: $showCreateNewProfile
                ).environmentObject(signUpData),
                isActive: $showCreateNewProfile
            ) {
                StandardButtonView(disabled: signUpData.inviteCode.isEmpty, text: "Confirm", style: .primary)
            }.disabled(signUpData.inviteCode.isEmpty)
        }
    }
}

struct AlphaInviteCodeView_Previews: PreviewProvider {
    static var previews: some View {
        AlphaInviteCodeView(signUpData: SignUpData())
    }
}

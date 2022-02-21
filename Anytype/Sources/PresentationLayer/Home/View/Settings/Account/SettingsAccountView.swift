import SwiftUI
import AnytypeCore
import Amplitude

struct SettingsAccountView: View {
    @EnvironmentObject private var model: SettingsViewModel

    var body: some View {
        VStack(spacing: 0) {
            DragIndicator()
            header
            accessBlock
            dataBlock
            accountBlock
            Spacer.fixedHeight(20)
        }
        .padding(.horizontal, 20)
        .background(Color.backgroundSecondary)
        .cornerRadius(16, corners: .top)
        
        .onAppear {
            Amplitude.instance().logEvent(AmplitudeEventsName.accountSettingsShow)
        }
    }
    
    private var header: some View {
        VStack(spacing: 0) {
            Spacer.fixedHeight(12)
            AnytypeText("Account & data".localized, style: .uxTitle1Semibold, color: .textPrimary)
            Spacer.fixedHeight(12)
        }
    }
    
    private var accessBlock: some View {
        VStack(spacing: 0) {
            section("Access".localized)
            recoveryPhrase
        }
    }
    
    private var recoveryPhrase: some View {
        SettingsSectionItemView(
            name: "Keychain phrase".localized,
            icon: .settings.keychain,
            pressed: $model.keychain
        )
        .sheet(isPresented: $model.keychain) {
            if model.loggingOut {
                KeychainPhraseView(shownInContext: .logout)
            } else {
                KeychainPhraseView(shownInContext: .settings)
            }
        }
    }
    
    private var dataBlock: some View {
        VStack(spacing: 0) {
            section("Data".localized)
            clearCache
        }
    }

    private var clearCache: some View {
        Button(action: { model.clearCacheAlert = true }) {
            HStack(spacing: 0) {
                AnytypeText("Clear file cache".localized, style: .uxBodyRegular, color: .System.red)
                Spacer()
            }
            .padding(.vertical, 14)
            .divider()
        }
    }
    
    private var accountBlock: some View {
        VStack(spacing: 0) {
            section("Account".localized)
            logOut
        }
    }
    
    private var logOut: some View {
        Button(action: { model.loggingOut = true }) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer.fixedHeight(14)
                HStack(spacing: 0) {
                    AnytypeText("Log out".localized, style: .uxBodyRegular, color: .textPrimary)
                    Spacer()
                }
                Spacer.fixedHeight(14)
            }
            .divider()
        }
    }
    
    private func section(_ text: String) -> some View {
        VStack(spacing: 0) {
            Spacer.fixedHeight(26)
            HStack {
                AnytypeText(text, style: .caption1Regular, color: .textSecondary)
                Spacer()
            }
            Spacer.fixedHeight(8)
        }
    }
}

struct SettingsAccountView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.System.blue
            SettingsAccountView()
        }
    }
}
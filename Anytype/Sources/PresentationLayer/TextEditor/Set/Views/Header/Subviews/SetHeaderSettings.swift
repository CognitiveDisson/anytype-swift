import SwiftUI

struct SetHeaderSettings: View {
    let settingsHeight: CGFloat = 56
    
    @EnvironmentObject private var model: EditorSetViewModel
    
    var body: some View {
        HStack {
            AnytypeText(model.dataView.activeView?.name ?? "Untitled".localized, style: .heading, color: .textPrimary)
                .padding()
            Image.arrow.rotationEffect(.degrees(90))
            Spacer()
        }
        .frame(height: settingsHeight)
    }
}

struct SetHeaderSettings_Previews: PreviewProvider {
    static var previews: some View {
        SetHeaderSettings()
    }
}
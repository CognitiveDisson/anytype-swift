import SwiftUI
import BlocksModels

struct EditorSetViewPicker: View {
    @EnvironmentObject var model: EditorSetViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            DragIndicator()
            Spacer.fixedHeight(12)
            AnytypeText("Views".localized, style: .uxTitle1Semibold, color: .textPrimary)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .center, spacing: 0) {
                    Spacer.fixedHeight(12)
                    
                    ForEach(model.dataView.views) { view in
                        viewButton(view)
                    }
                }
            }
        }
        .background(Color.backgroundPrimary)
    }
    
    func viewButton(_ view: DataviewView) -> some View {
        VStack(spacing: 0) {
            Spacer.fixedHeight(12)
            HStack(spacing: 0) {
                if view.isSupported {
                    Button(action: {
                        model.activeViewId = view.id
                        withAnimation {
                            model.showViewPicker = false
                        }
                    }) {
                        AnytypeText(view.name, style: .uxBodyRegular, color: .textPrimary)
                        Spacer(minLength: 5)
                        if view == model.activeView {
                            Image.optionChecked
                        }
                    }
                } else {
                    AnytypeText("\(view.name)", style: .uxBodyRegular, color: .textSecondary)
                    Spacer(minLength: 5)
                    AnytypeText("\(view.type.name) view soon", style: .uxBodyRegular, color: .textSecondary)
                }
            }
            .modifier(DividerModifier(spacing: 14))
            .padding(.horizontal, 20)
        }
    }
}

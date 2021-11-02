import SwiftUI
import Amplitude
import BlocksModels

struct ObjectSettingsContainerView: View {
    
    @ObservedObject var viewModel: ObjectSettingsViewModel
        
    @State private var mainViewPresented = false
    
    @State private var isIconPickerPresented = false
    @State private var isCoverPickerPresented = false
    @State private var isLayoutPickerPresented = false
    @State private var isRelationsViewPresented = false
    
    var body: some View {
        Color.clear
            .ignoresSafeArea()
            .popup(
                isPresented: $mainViewPresented,
                type: .floater(verticalPadding: 42),
                animation: .ripple,
                closeOnTap: false,
                closeOnTapOutside: true,
                backgroundOverlayColor: Color.black.opacity(0.25),
                dismissCallback: {
                    guard !isLayoutPickerPresented else { return }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.dismissHandler()
                    }
                },
                view: {
                    ObjectSettingsView(
                        isCoverPickerPresented: $isCoverPickerPresented,
                        isIconPickerPresented: $isIconPickerPresented,
                        isLayoutPickerPresented: $isLayoutPickerPresented,
                        isRelationsViewPresented: $isRelationsViewPresented
                    )
                        .padding(8)
                        .environmentObject(viewModel)
                }
            )
            .sheet(
                isPresented: $isCoverPickerPresented
            ) {
                ObjectCoverPicker(viewModel: viewModel.coverPickerViewModel)
            }
            .sheet(
                isPresented: $isIconPickerPresented
            ) {
                ObjectIconPicker(viewModel: viewModel.iconPickerViewModel)
            }
            .sheet(
                isPresented: $isRelationsViewPresented
            ) {
                ObjectRelationsView(viewModel: viewModel.relationsViewModel)
            }
            .popup(
                isPresented: $isLayoutPickerPresented,
                type: .floater(verticalPadding: 42),
                closeOnTap: false,
                closeOnTapOutside: true,
                backgroundOverlayColor: Color.black.opacity(0.25),
                view: {
                    ObjectLayoutPicker()
                        .padding(8)
                        .environmentObject(viewModel.layoutPickerViewModel)
                }
            )
            .onChange(of: isLayoutPickerPresented) { showLayoutSettings in
                // Analytics
                if showLayoutSettings {
                    Amplitude.instance().logEvent(AmplitudeEventsName.popupChooseLayout)
                }

                withAnimation() {
                    mainViewPresented = !showLayoutSettings
                }
            }
            .onAppear {
                Amplitude.instance().logEvent(AmplitudeEventsName.popupDocumentMenu)
                
                withAnimation(.ripple) {
                    mainViewPresented = true
                }
            }
    }
}

struct ObjectSettingsContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ObjectSettingsContainerView(
            viewModel: ObjectSettingsViewModel(
                objectId: "dummyPageId",
                objectDetailsService: ObjectDetailsService(
                    objectId: ""
                ),
                popScreenAction: {}
            )
        )
    }
}

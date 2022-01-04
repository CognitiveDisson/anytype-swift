import SwiftUI

struct RelationOptionsSearchView: View {
    
    @Environment(\.presentationMode) private var presentationMode
    
    @ObservedObject var viewModel: RelationOptionsSearchViewModel
    
    @State private var searchText = ""
    
    var body: some View {
        VStack() {
            DragIndicator(bottomPadding: 0)
            SearchBar(text: $searchText, focused: true)
            content
            addButton
        }
        .background(Color.backgroundSecondary)
        .onChange(of: searchText) { viewModel.search(text: $0) }
        .onAppear { viewModel.search(text: searchText) }
    }
    
    private var content: some View {
        Group {
            if viewModel.options.isEmpty {
                emptyState
            } else {
                searchResults
            }
        }
    }
    
    private var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.options) { option in
                    RelationObjectsSearchRowView(
                        data: option,
                        isSelected: viewModel.selectedOptionIds.contains(option.id)
                    ) {
                        viewModel.didTapOnOption(option)
                    }
                }
            }
            .padding(.bottom, 10)
        }
        .modifier(DividerModifier(spacing: 0))
    }
    
    private var emptyState: some View {
        VStack(alignment: .center) {
            Spacer()
            AnytypeText(
                "\("There is no object named".localized) \"\(searchText)\"",
                style: .uxBodyRegular,
                color: .textPrimary
            )
            .multilineTextAlignment(.center)
            AnytypeText(
                "Try to create a new one or search for something else".localized,
                style: .uxBodyRegular,
                color: .textSecondary
            )
            .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var addButton: some View {
        StandardButton(disabled: viewModel.selectedOptionIds.isEmpty, text: "Add".localized, style: .primary) {
            viewModel.didTapAddSelectedOptions()
            presentationMode.wrappedValue.dismiss()
        }
        .if(viewModel.selectedOptionIds.isNotEmpty) {
            $0.overlay(
                HStack(spacing: 0) {
                    Spacer()
                    AnytypeText("\(viewModel.selectedOptionIds.count)", style: .relation1Regular, color: .grayscaleWhite)
                        .frame(minWidth: 15, minHeight: 15)
                        .padding(5)
                        .background(Color.darkAmber)
                        .clipShape(
                            Circle()
                        )
                    Spacer.fixedWidth(12)
                }
            )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
    }
}

//struct RelationOptionsSearchView_Previews: PreviewProvider {
//    static var previews: some View {
//        RelationOptionsSearchView()
//    }
//}
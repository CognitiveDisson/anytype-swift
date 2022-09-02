import SwiftUI
import Kingfisher

struct SetListViewCell: View {
    let configuration: SetContentViewItemConfiguration
    
    var body: some View {
        Button {
            configuration.onItemTap()
        } label: {
            content
        }
        .buttonStyle(LightDimmingButtonStyle())
    }
    
    private var content: some View {
        FlowRelationsView(
            viewModel: FlowRelationsViewModel(
                icon: configuration.icon,
                showIcon: configuration.showIcon,
                title: configuration.title,
                description: configuration.description,
                relations: configuration.relations.filter { $0.hasValue },
                onIconTap: configuration.onIconTap,
                onRelationTap: { _ in }
            )
        )
        .background(Color.backgroundPrimary)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.vertical, 20)
        .clipped()
        .contentShape(Rectangle())
    }
}
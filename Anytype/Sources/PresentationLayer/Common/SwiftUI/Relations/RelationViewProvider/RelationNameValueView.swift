import SwiftUI

class RelationNameValueViewModel: ObservableObject {
    @Published var relation: Relation
    @Published var isHighlighted: Bool = false

    init(relation: Relation) {
        self.relation = relation
    }
}

struct RelationNameValueView: View {
    @ObservedObject var viewModel: RelationNameValueViewModel
    var isEditable: Bool = false
    var onEditTap: ((String) -> ())? = nil
    var showDivider: Bool = true

    @State private var width: CGFloat = .zero
    @State private var height: CGFloat = .zero

    var body: some View {
        HStack(spacing: 8) {
            name
                .frame(width: width * 0.4, alignment: .topLeading)
            Spacer.fixedWidth(8)

            Group {
                if isEditable, viewModel.relation.isEditable {
                    valueViewButton
                } else {
                    valueView
                }
            }
            .frame(maxWidth: .infinity, minHeight: 34, alignment: .center)
            .background(FrameCatcher { height = $0.size.height })
        }
        .background(FrameCatcher { width = $0.size.width })
    }

    private var name: some View {
        AnytypeText(viewModel.relation.name, style: .relation1Regular, color: .textSecondary).lineLimit(1)
    }

    private var valueViewButton: some View {
        Button {
            onEditTap?(viewModel.relation.id)
        } label: {
            valueView
        }
    }

    private var valueView: some View {
        HStack(spacing: 0) {
            RelationValueView(relation: viewModel.relation, style: .regular(allowMultiLine: false))
            Spacer()
        }
    }
}

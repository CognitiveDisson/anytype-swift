import SwiftUI
import AnytypeCore

struct NewRelationRestrictionsSectionView: View {
    
    let model: [ObjectTypeModel]
    let onTap: () -> Void
    
    var body: some View {
        NewRelationSectionView(
            title: "Limit object type".localized,
            contentViewBuilder: {
                contentView
            },
            onTap: onTap,
            isArrowVisible: true
        )
    }
    
    private var contentView: some View {
        Group {
            if model.isNotEmpty {
                filledView
            } else {
                emptyView
            }
        }
    }
    
    private var emptyView: some View {
        AnytypeText("None".localized, style: .uxBodyRegular, color: .textPrimary)
            .lineLimit(1)
    }
    
    private var filledView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(model) { objectTypeModel in
                    objectTypeView(model: objectTypeModel)
                    Spacer.fixedWidth(10)
                }
                Spacer.fixedWidth(30)
            }
        }
        .transparencyEffect(edge: .trailing, length: 40)
    }
    
    private func objectTypeView(model: ObjectTypeModel) -> some View {
        HStack(spacing: 5) {
            AnytypeText(model.emoji.value, style: .uxBodyRegular, color: .textPrimary)
                .lineLimit(1)
            AnytypeText(model.title, style: .uxBodyRegular, color: .textPrimary)
                .lineLimit(1)
        }
    }
}

extension NewRelationRestrictionsSectionView {
    
    struct ObjectTypeModel: Identifiable, Hashable {
        let id: String
        let emoji: Emoji
        let title: String
    }
    
}

struct NewRelationRestrictionsSectionView_Previews: PreviewProvider {
    static var previews: some View {
        NewRelationRestrictionsSectionView(
            model: [
                NewRelationRestrictionsSectionView.ObjectTypeModel(
                    id: UUID().uuidString,
                    emoji: Emoji.default,
                    title: "title 1"
                ),
                NewRelationRestrictionsSectionView.ObjectTypeModel(
                    id: UUID().uuidString,
                    emoji: Emoji("📘")!,
                    title: "title 2"
                ),
                NewRelationRestrictionsSectionView.ObjectTypeModel(
                    id: UUID().uuidString,
                    emoji: Emoji("🤡")!,
                    title: "title 2"
                ),
                NewRelationRestrictionsSectionView.ObjectTypeModel(
                    id: UUID().uuidString,
                    emoji: Emoji("🤡")!,
                    title: "title 2"
                ),
                NewRelationRestrictionsSectionView.ObjectTypeModel(
                    id: UUID().uuidString,
                    emoji: Emoji("🤡")!,
                    title: "title 2"
                ),
                NewRelationRestrictionsSectionView.ObjectTypeModel(
                    id: UUID().uuidString,
                    emoji: Emoji("🤡")!,
                    title: "title 2"
                )
            ],
            onTap: {}
        )
            
    }
}
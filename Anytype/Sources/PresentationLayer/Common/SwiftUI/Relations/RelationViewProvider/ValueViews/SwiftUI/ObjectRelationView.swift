import SwiftUI

struct ObjectRelationView: View {
    let options: [Relation.Object.Option]
    let hint: String
    let style: RelationStyle
    
    var body: some View {
        if options.isNotEmpty {
            objectsList
        } else {
            RelationsListRowPlaceholderView(hint: hint, type: style.placeholderType)
        }
    }
    
    private var objectsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: style.objectRelationStyle.hSpaсingList) {
                ForEach(options) { option in
                    objectView(option: option)
                }
            }.padding(.horizontal, 1)
        }
    }
    
    private func objectView(option: Relation.Object.Option) -> some View {
        HStack(spacing: style.objectRelationStyle.hSpaсingObject) {
            SwiftUIObjectIconImageView(
                iconImage: option.icon,
                usecase: .mention(.body)
            )
                .frame(width: style.objectRelationStyle.size.width, height: style.objectRelationStyle.size.height)
            
            AnytypeText(
                option.title,
                style: .relation1Regular,
                color: .textPrimary
            )
                .lineLimit(1)
        }
    }
}

extension ObjectRelationView {
    struct ObjectRelationStyle {
        let hSpaсingList: CGFloat
        let hSpaсingObject: CGFloat
        let size: CGSize
    }
}


struct ObjectRelationView_Previews: PreviewProvider {
    static var previews: some View {
        ObjectRelationView(options: [], hint: "Hint", style: .regular(allowMultiLine: false))
    }
}
import SwiftUI

struct FileRelationView: View {
    let options: [Relation.File.Option]
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
                ForEach(options) { objectView(option: $0) }
            }
            .padding(.horizontal, 1)
        }
    }
    
    private func objectView(option: Relation.File.Option) -> some View {
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


struct FileRelationView_Previews: PreviewProvider {
    static var previews: some View {
        FileRelationView(options: [], hint: "Hint", style: .regular(allowMultiLine: false))
    }
}

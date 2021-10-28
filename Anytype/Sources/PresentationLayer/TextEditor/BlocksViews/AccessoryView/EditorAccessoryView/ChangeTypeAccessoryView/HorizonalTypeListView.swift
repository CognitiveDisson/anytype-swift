import SwiftUI
import UIKit
import Combine

struct HorizonalTypeListView: View {
    let viewModel: HorizonalTypeListViewModel

    var body: some View {
        Divider()
            .frame(height: 0.5)
            .foregroundColor(Color.grayscale30)
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(viewModel.items) { item in
                    Button {
                        item.action()
                    } label: {
                        TypeView(image: item.image, title: item.title)
                    }
                    .frame(width: 80, height: 90)
                }
            }
        }
    }
}

private struct TypeView: View {
    let image: ObjectIconImage
    let title: String

    var body: some View {
        VStack(spacing: 5) {
            imageView
            AnytypeText(title, style: .caption2Regular, color: .textSecondary)
        }
    }

    private var imageView: some View {
        SwiftUIObjectIconImageView(
            iconImage: image,
            usecase: .editorAccessorySearch
        ).frame(width: 48, height: 48)
    }
}

struct HorizonalTypeListView_Previews: PreviewProvider {
    private final class ItemProvider: TypeListItemProvider {
        var typesPublisher: Published<[HorizonalTypeListViewModel.Item]>.Publisher {
            $items
        }

        @Published var items: [HorizonalTypeListViewModel.Item] =
        [HorizonalTypeListViewModel.Item.searchItem {}]
    }

    static var previews: some View {
        HorizonalTypeListView(
            viewModel: .init(itemProvider: ItemProvider(), searchHandler: {})
        )
        .previewLayout(.fixed(width: 300, height: 96))
    }
}
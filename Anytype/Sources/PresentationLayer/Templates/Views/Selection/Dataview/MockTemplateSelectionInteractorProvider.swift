import Combine

final class MockTemplateSelectionInteractorProvider: TemplateSelectionInteractorProvider {
    var userTemplates: AnyPublisher<[TemplatePreviewModel], Never> { $templates.eraseToAnyPublisher() }
    @Published private var templates = MockTemplatePreviewModel.allPreviews.map { $0.model }
    
    func setDefaultTemplate(model: TemplatePreviewModel) async throws {
        fatalError()
    }
}

struct MockTemplatePreviewModel: Identifiable {
    var id: String { model.id }
    let title: String
    let model: TemplatePreviewModel
}

extension MockTemplatePreviewModel {
    static let allPreviews = [
        blankPreview,
        templateWithTitle,
        onlyIcon,
        iconCoverTitle,
        coverTitle
    ]
    
    static let blankPreview = MockTemplatePreviewModel(
        title: "Blank preview",
        model: .init(model: .blank, alignment: .left, isDefault: false)
    )
    
    static let templateWithTitle = MockTemplatePreviewModel(
        title: "Template with title",
        model: .init(
            model: .installed(
                .init(
                    id: "id",
                    title: "Awesome template",
                    header: .none
                )
            ),
            alignment: .left,
            isDefault: false
        )
    )
    
    static let onlyIcon = MockTemplatePreviewModel(
        title: "Only icon",
        model: .init(
            model: .installed(
                .init(
                    id: "id",
                    title: "Awesome template",
                    header: .filled(
                        state: .iconOnly(
                            .init(
                                icon: .init(
                                    icon: .init(
                                        mode: .icon(.emoji(.lamp)),
                                        usecase: .templatePreview)
                                    ,
                                    layoutAlignment: .left,
                                    onTap: {}
                                ),
                                onCoverTap: {}
                            )
                        )
                    )
                )
            ),
            alignment: .left,
            isDefault: false
        )
    )
    
    static let iconCoverTitle = MockTemplatePreviewModel(
        title: "Preview icon cover title",
        model: .init(
            model: .installed(
                .init(
                    id: "Id",
                    title: "Awesome template",
                    header: .filled(
                        state: .iconAndCover(
                            icon: .init(
                                icon: .init(
                                    mode: .icon(.emoji(.lamp)),
                                    usecase: .templatePreview
                                ),
                                layoutAlignment: .left,
                                onTap: {}
                            ),
                            cover: .init(
                                coverType: .cover(.gradient(.init(start: .red, end: .blue))),
                                onTap: {}))
                    )
                )
            ),
            alignment: .left,
            isDefault: false
        )
    )
    
    static let coverTitle = MockTemplatePreviewModel(
        title: "Preview cover title",
        model: .init(
            model: .installed(
                .init(
                    id: "Id",
                    title: "Awesome template",
                    header: .filled(
                        state: .coverOnly(
                            .init(
                                coverType: .cover(.gradient(.init(start: .red, end: .blue))),
                                onTap: {}
                            )
                        )
                    )
                )
            ),
            alignment: .left,
            isDefault: false
        )
    )
}

import Foundation

struct FilesOptionsSearchModuleBuilder: RelationOptionsSearchModuleBuilderProtocol {
    
    func buildModule(
        excludedOptionIds: [String],
        onSelect: @escaping ([String]) -> Void,
        onCreate _ : @escaping (String) -> Void
    ) -> NewSearchView {
        NewSearchModuleAssembly.filesSearchModule(
            excludedFileIds: excludedOptionIds,
            onSelect: onSelect
        )
    }
    
}
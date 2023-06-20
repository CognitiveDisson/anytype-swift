import ProtobufMessages
import Combine

protocol UsecaseServiceProtocol {
    func setObjectImportUseCaseToSkip() async throws
}

final class UsecaseService: UsecaseServiceProtocol {
    
    func setObjectImportUseCaseToSkip() async throws {
        try await ClientCommands.objectImportUseCase(.with {
            $0.useCase = .skip
        }).invoke()
    }
    
}
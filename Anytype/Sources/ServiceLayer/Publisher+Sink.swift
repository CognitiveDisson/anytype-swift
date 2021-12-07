import Combine
import AnytypeCore

extension Publisher {
    public func sinkWithResult(completion: @escaping (Result<Self.Output, Error>) -> ()) -> AnyCancellable {
        self.sink { sinkCompletion in
            switch sinkCompletion {
            case .finished: return
            case let .failure(error):
                completion(.failure(error))
            }
        } receiveValue: { result in
            completion(.success(result))
        }
    }
    
    public func sinkWithDefaultCompletion(_ actionName: String, receiveValue: @escaping ((Self.Output) -> Void)) -> AnyCancellable {
        self.sink(receiveCompletion: defaultCompletion(actionName), receiveValue: receiveValue)
    }
    
    private func defaultCompletion(_ actionName: String) -> ((Subscribers.Completion<Self.Failure>) -> Void) {
        return { completion in
            switch completion {
            case .finished: return
            case let .failure(error):
                anytypeAssertionFailure("\(actionName) error: \(error)", domain: .defaultCompletion)
            }
        }
    }
}
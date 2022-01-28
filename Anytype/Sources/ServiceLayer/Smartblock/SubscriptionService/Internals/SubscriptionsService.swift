import BlocksModels
import Combine
import AnytypeCore

final class SubscriptionsService: SubscriptionsServiceProtocol {
    private var subscription: AnyCancellable?
    private let toggler: SubscriptionTogglerProtocol
    private let storage: ObjectDetailsStorage
    
    private var turnedOnSubs = [SubscriptionId: SubscriptionCallback]()
    
    init(toggler: SubscriptionTogglerProtocol, storage: ObjectDetailsStorage) {
        self.toggler = toggler
        self.storage = storage
        
        setup()
    }
    
    deinit {
        stopAllSubscriptions()
    }
    
    func stopAllSubscriptions() {
        turnedOnSubs.keys.forEach { stopSubscription(id: $0) }
    }
    
    func stopSubscriptions(ids: [SubscriptionId]) {
        ids.forEach { stopSubscription(id: $0) }
    }
    
    func stopSubscription(id: SubscriptionId) {
        _ = toggler.stopSubscription(id: id)
        turnedOnSubs[id] = nil
    }
    
    func startSubscriptions(data: [SubscriptionData], update: @escaping SubscriptionCallback) {
        data.forEach { startSubscription(data: $0, update: update) }
    }
    
    func startSubscription(data: SubscriptionData, update: @escaping SubscriptionCallback) {
        guard turnedOnSubs[data.identifier].isNil else {
            anytypeAssertionFailure("Subscription: \(data) started on second time", domain: .subscriptionStorage)
            return
        }
        
        turnedOnSubs[data.identifier] = update
        
        guard let (details, count) = toggler.startSubscription(data: data) else { return }
        
        details.forEach { storage.ammend(details: $0) }
        update(data.identifier, .initialData(details))
        update(data.identifier, .pageCount(count))
    }
 
    // MARK: - Private
    private let dependencySubscriptionSuffix = "/dep"
    
    private func setup() {
        subscription = NotificationCenter.Publisher(
            center: .default,
            name: .middlewareEvent,
            object: nil
        )
            .compactMap { $0.object as? EventsBunch }
            .filter { [weak self] event in
                guard let self = self else { return false }
                guard event.contextId.isNotEmpty else { return true } // Empty object id in generic subscription
                
                guard let subscription = SubscriptionId(rawValue: event.contextId) else {
                    return false
                }
                
                return self.turnedOnSubs.keys.contains(subscription)
            }
            .receiveOnMain()
            .sink { [weak self] events in
                self?.handle(events: events)
            }
    }
    
    private func handle(events: EventsBunch) {
        anytypeAssert(events.localEvents.isEmpty, "Local events with emplty objectId: \(events)", domain: .subscriptionStorage)
        
        for event in events.middlewareEvents {
            switch event.value {
            case .objectDetailsAmend(let data):
                let currentDetails = storage.get(id: data.id) ?? ObjectDetails.empty(id: data.id)
                
                let updatedDetails = currentDetails.updated(by: data.details.asDetailsDictionary)
                storage.add(details: updatedDetails)
                
                update(details: updatedDetails, rawSubIds: data.subIds)
            case .subscriptionPosition(let position):
                let update: SubscriptionUpdate = .move(from: position.id, after: position.afterID.isNotEmpty ? position.afterID : nil)
                sendUpdate(update, contextId: events.contextId)
            case .subscriptionAdd(let data):
                guard let details = storage.get(id: data.id) else {
                    anytypeAssertionFailure("No details found for id \(data.id)", domain: .subscriptionStorage)
                    return
                }
                
                let update: SubscriptionUpdate = .add(details, after: data.afterID.isNotEmpty ? data.afterID : nil)
                sendUpdate(update, contextId: events.contextId)
            case .subscriptionRemove(let remove):
                sendUpdate(.remove(remove.id), contextId: events.contextId)
            case .objectRemove:
                break // unsupported (Not supported in middleware converter also)
            case .subscriptionCounters(let data):
                sendUpdate(.pageCount(data.total), contextId: events.contextId)
            case .accountConfigUpdate:
                break
            case .accountDetails:
                break
            default:
                anytypeAssertionFailure("Unupported event \(event)", domain: .subscriptionStorage)
            }
        }
    }
    
    private func sendUpdate(_ update: SubscriptionUpdate, contextId: BlockId) {
        guard let subId = SubscriptionId(rawValue: contextId) else {
            anytypeAssertionFailure("Unsupported object id \(contextId)", domain: .subscriptionStorage)
            return
        }
        guard let action = turnedOnSubs[subId] else { return }
        action(subId, update)
    }
    
    private func update(details: ObjectDetails, rawSubIds: [String]) {
        let ids: [SubscriptionId] = rawSubIds.compactMap { rawId in
            guard let id = SubscriptionId(rawValue: rawId) else {
                if !rawId.hasSuffix(dependencySubscriptionSuffix) {
                    anytypeAssertionFailure("Unrecognized subscription: \(rawId)", domain: .subscriptionStorage)
                }
                return nil
            }
            
            return id
        }
        
        for id in ids {
            guard let action = turnedOnSubs[id] else { continue }
            action(id, .update(details))
        }
    }
}
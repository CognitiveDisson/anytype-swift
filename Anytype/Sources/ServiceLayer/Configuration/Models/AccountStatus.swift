import ProtobufMessages
import CoreGraphics

enum AccountStatus: Equatable {
    case active
    case pendingDeletion(progress: DeletionProgress)
    case deleted
}


struct DeletionProgress: Equatable {
    let deadline: Date
    private let maxDeadline = 30
    
    var deletionProgress: CGFloat {
        return 1 - (CGFloat(daysToDeletion) / CGFloat(maxDeadline)).clamped(0.1, 0.9)
    }
    
    var daysToDeletion: Int {
        Calendar.current
            .numberOfDaysBetween(Date(), and: deadline)
            .clamped(0, maxDeadline)
    }
}

extension Anytype_Model_Account.Status {
    var asModel: AccountStatus? {
        switch self.statusType {
        case .startedDeletion, .deleted:
            return .deleted
        case .active:
            return .active
        case .pendingDeletion:
            return .pendingDeletion(
                progress: DeletionProgress(
                    deadline: Date(timeIntervalSince1970: TimeInterval(deletionDate))
                )
            )
        case .UNRECOGNIZED:
            return nil
        }
    }
}
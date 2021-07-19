import SwiftUI
import Combine
import ProtobufMessages
import Amplitude


class ProfileNameViewModel: ObservableObject, Identifiable {
    var id: String
    @Published var image: UIImage? = nil
    @Published var color: UIColor?
    @Published var name: String = ""
    @Published var peers: String?
    
    init(id: String) {
        self.id = id
    }
    
    var userIcon: UserIconView.IconType {
        if let image = image {
            return UserIconView.IconType.image(.local(image: image))
        } else if let firstCharacter = name.first {
            return UserIconView.IconType.placeholder(firstCharacter)
        } else {
            return UserIconView.IconType.placeholder(nil)
        }
    }
}


class SelectProfileViewModel: ObservableObject {
    let isMultipleAccountsEnabled = false // Not supported yet
    
    private let authService  = ServiceLocator.shared.authService()
    private let fileService = ServiceLocator.shared.fileService()
    
    private var cancellable: AnyCancellable?
    
    @Published var profilesViewModels = [ProfileNameViewModel]()
    @Published var error: String? {
        didSet {
            showError = false
            
            if !error.isNil {
                showError = true
            }
        }
    }
    @Published var showError: Bool = false
    
    func accountRecover() {
        DispatchQueue.global().async { [weak self] in
            self?.handleAccountShowEvent()
            self?.authService.accountRecover { result in
                if case .failure = result {
                    self?.error = "Account recover error"
                }
            }
        }
    }
    
    func selectProfile(id: String) {
        self.authService.selectAccount(id: id) { result in
            DispatchQueue.main.async { [weak self] in
                switch result {
                case .success:
                    // Analytics
                    Amplitude.instance().logEvent(AmplitudeEventsName.accountRecover,
                                                  withEventProperties: [AmplitudeEventsPropertiesKey.accountId : id])
                    self?.showHomeView()
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Private func
    
    private func handleAccountShowEvent() {
        cancellable = NotificationCenter.Publisher(center: .default, name: .middlewareEvent, object: nil)
            .compactMap { notification in
                return notification.object as? Anytype_Event
            }
            .map(\.messages)
            .map {
                $0.filter { message in
                    guard let value = message.value else { return false }
                    
                    if case Anytype_Event.Message.OneOf_Value.accountShow = value {
                        return true
                    }
                    return false
                }
            }
            .filter { $0.count > 0 } 
            .receiveOnMain()
            .sink { [weak self] events in
                guard let self = self else {
                    return
                }
                
                
                if self.isMultipleAccountsEnabled {
                    for event in events {
                        let account = event.accountShow.account
                        
                        let profileViewModel = self.profileViewModelFromAccount(account)
                        self.profilesViewModels.append(profileViewModel)
                    }
                } else {
                    self.selectProfile(id: events[0].accountShow.account.id)
                }
            }
    }
    
    private func profileViewModelFromAccount(_ account: Anytype_Model_Account) -> ProfileNameViewModel {
        let profileViewModel = ProfileNameViewModel(id: account.id)
        profileViewModel.name = account.name
        
        switch account.avatar.avatar {
        case .color(let hexColor):
            profileViewModel.color = UIColor(hexString: hexColor)
        case .image(let file):
            let defaultWidth: CGFloat = 500
            let imageSize = Int32(defaultWidth * UIScreen.main.scale) // we also need device aspect ratio and etc.
            // so, it is better here to subscribe or take event from UIWindow and get its data.
            self.downloadAvatarImage(imageSize: imageSize, hash: file.hash, profileViewModel: profileViewModel)
        default: break
        }
        
        return profileViewModel
    }
    
    private func downloadAvatarImage(imageSize: Int32, hash: String, profileViewModel: ProfileNameViewModel) {
        _ = self.fileService.fetchImageAsBlob(hash: hash, wantWidth: imageSize).receiveOnMain()
            .sink(receiveCompletion: { [weak self] result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }) { blob in
                profileViewModel.image = UIImage(data: blob)
        }
    }
    
    // MARK: - Coordinator
    
//    func showCreateProfileView() -> some View {
//        return CreateNewProfileView(viewModel: CreateNewProfileViewModel())
//    }
    
    func showHomeView() {
        let homeAssembly = HomeViewAssembly()
        windowHolder?.startNewRootView(homeAssembly.createHomeView())
    }
}

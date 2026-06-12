import Foundation
import Rex

public enum AppAction: Actionable {
    case graph(GraphAction)
    case delegate(DelegateAction)

    case userLogin
    case userLogout
    case userLoaded(AppState.User)

    case sendMessage(String)
    case messageReceived(AppState.Message)
    case setTyping(Bool)
    case userJoined(AppState.User)
    case userLeft(AppState.User)

    case clearMessages
    case loadMessages
    case messagesLoaded([AppState.Message])
    case showError(String?)
    case clearError
    case logActivity(String)

    case triggerUserJoin
    case triggerUserLeave
    case triggerMessageSent
    case triggerTyping
    case triggerSystemEvent
}

public enum DelegateAction: Actionable, Equatable {
    case messageToChat(String)
    case addUser(name: String)
    case systemNotification(String)
    case navigatedBack
}

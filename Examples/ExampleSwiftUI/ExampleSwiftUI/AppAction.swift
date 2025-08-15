import Foundation
import Rex

public enum AppAction: ActionType {
    // User actions
    case userLogin
    case userLogout
    case userLoaded(AppState.User)
    
    // Chat actions
    case sendMessage(String)
    case messageReceived(AppState.Message)
    case setTyping(Bool)
    case userJoined(AppState.User)
    case userLeft(AppState.User)
    
    // UI actions
    case clearMessages
    case loadMessages
    case messagesLoaded([AppState.Message])
    case showError(String?)
    case clearError
    
    // Event Bus actions
    case triggerUserJoin
    case triggerUserLeave
    case triggerMessageSent
    case triggerTyping
    case triggerSystemEvent
}

import Foundation
import Rex

// MARK: - App Events
public struct AppEvent: EventType {
    public let name: String
    public let data: [String: String]
    
    public init(name: String, data: [String: String] = [:]) {
        self.name = name
        self.data = data
    }
}

public struct NavigationEvent: EventType {
    public let route: String
    public let parameters: [String: String]
    
    public init(route: String, parameters: [String: String] = [:]) {
        self.route = route
        self.parameters = parameters
    }
}

public struct UserActionEvent: EventType {
    public let action: String
    public let screen: String
    public let metadata: [String: String]
    
    public init(action: String, screen: String, metadata: [String: String] = [:]) {
        self.action = action
        self.screen = screen
        self.metadata = metadata
    }
}

// MARK: - Event Bus Extensions
public extension EventBus {
    // Convenience methods for app events
    @MainActor
    func publishAppEvent(name: String, data: [String: String] = [:]) {
        publish(AppEvent(name: name, data: data))
    }
    
    @MainActor
    func publishNavigation(route: String, parameters: [String: String] = [:]) {
        publish(NavigationEvent(route: route, parameters: parameters))
    }
    
    @MainActor
    func publishUserAction(action: String, screen: String, metadata: [String: String] = [:]) {
        publish(UserActionEvent(action: action, screen: screen, metadata: metadata))
    }
}

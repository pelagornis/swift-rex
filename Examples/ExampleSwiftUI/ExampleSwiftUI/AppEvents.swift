import Foundation
import Rex

public struct AppEvent: EventType {
    public let name: String
    public let data: [String: String]
    
    public init(name: String, data: [String: String] = [:]) {
        self.name = name
        self.data = data
    }
}

// MARK: - Chat App Events
public struct ChatEvent: EventType {
    public let type: String
    public let message: String
    public let sender: String
    public let timestamp: Date
    
    public init(type: String, message: String, sender: String, timestamp: Date = Date()) {
        self.type = type
        self.message = message
        self.sender = sender
        self.timestamp = timestamp
    }
}

public struct UserEvent: EventType {
    public let action: String
    public let username: String
    public let data: [String: String]
    
    public init(action: String, username: String, data: [String: String] = [:]) {
        self.action = action
        self.username = username
        self.data = data
    }
}

public struct SystemEvent: EventType {
    public let event: String
    public let details: [String: String]
    
    public init(event: String, details: [String: String] = [:]) {
        self.event = event
        self.details = details
    }
}

// MARK: - Event Bus Extensions
public extension EventBus {
    // Convenience methods for chat events
    @MainActor
    func publishAppEvent(name: String, data: [String: String] = [:]) {
        publish(AppEvent(name: name, data: data))
    }

    @MainActor
    func publishChatEvent(type: String, message: String, sender: String) {
        publish(ChatEvent(type: type, message: message, sender: sender))
    }
    
    @MainActor
    func publishUserEvent(action: String, username: String, data: [String: String] = [:]) {
        publish(UserEvent(action: action, username: username, data: data))
    }
    
    @MainActor
    func publishSystemEvent(event: String, details: [String: String] = [:]) {
        publish(SystemEvent(event: event, details: details))
    }
}

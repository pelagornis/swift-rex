import Foundation
import Rex

public struct AppState: StateType {
    public var messages: [Message] = []
    public var currentUser: User = User(id: "user1", name: "Me", avatar: "👤")
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    public var lastUpdated: Date = Date()
    public var isTyping: Bool = false
    public var onlineUsers: [User] = []
    
    public struct Message: Codable, Equatable, Identifiable {
        public let id: String
        public let text: String
        public let sender: User
        public let timestamp: Date
        public let type: MessageType
        
        public init(id: String = UUID().uuidString, text: String, sender: User, type: MessageType = .text) {
            self.id = id
            self.text = text
            self.sender = sender
            self.timestamp = Date()
            self.type = type
        }
        
        public enum MessageType: String, Codable {
            case text = "text"
            case image = "image"
            case system = "system"
        }
    }
    
    public struct User: Codable, Equatable, Identifiable {
        public let id: String
        public let name: String
        public let avatar: String
        
        public init(id: String, name: String, avatar: String) {
            self.id = id
            self.name = name
            self.avatar = avatar
        }
    }
    
    public init() {
        // Add some sample messages
        let botUser = User(id: "bot", name: "ChatBot", avatar: "🤖")
        let systemUser = User(id: "system", name: "System", avatar: "⚙️")
        
        messages = [
            Message(text: "Welcome to Swift-Rex Chat!", sender: systemUser, type: .system),
            Message(text: "Hello! How can I help you today?", sender: botUser),
            Message(text: "Hi! I'm learning about EventBus", sender: currentUser)
        ]
        
        onlineUsers = [
            currentUser,
            botUser,
            User(id: "user2", name: "Alice", avatar: "👩"),
            User(id: "user3", name: "Bob", avatar: "👨")
        ]
    }
}

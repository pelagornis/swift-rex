import Foundation
import Combine
import Rex

public struct AppReducer: Reducer {
    public init() {}
    
    public func reduce(state: inout AppState, action: AppAction) -> [Effect<AppAction>] {
        switch action {
        // User actions
        case .userLogin:
            state.isLoading = true
            state.errorMessage = nil
            return [
                Effect { emitter in
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    let user = AppState.User(
                        id: "user\(Int.random(in: 1000...9999))",
                        name: "User\(Int.random(in: 1...100))",
                        avatar: "👤"
                    )
                    await emitter.withValue { emitter in
                        emitter.send(.userLoaded(user))
                    }
                }
            ]
            
        case .userLogout:
            state.currentUser = AppState.User(id: "guest", name: "Guest", avatar: "👤")
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        case .userLoaded(let user):
            state.currentUser = user
            state.isLoading = false
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        // Chat actions
        case .sendMessage(let text):
            let message = AppState.Message(text: text, sender: state.currentUser)
            state.messages.append(message)
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        case .messageReceived(let message):
            state.messages.append(message)
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        case .setTyping(let isTyping):
            state.isTyping = isTyping
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        case .userJoined(let user):
            if !state.onlineUsers.contains(where: { $0.id == user.id }) {
                state.onlineUsers.append(user)
                let systemMessage = AppState.Message(
                    text: "\(user.name) joined the chat",
                    sender: AppState.User(id: "system", name: "System", avatar: "⚙️"),
                    type: .system
                )
                state.messages.append(systemMessage)
                state.lastUpdated = Date()
            }
            return [Effect { _ in }]
            
        case .userLeft(let user):
            state.onlineUsers.removeAll { $0.id == user.id }
            let systemMessage = AppState.Message(
                text: "\(user.name) left the chat",
                sender: AppState.User(id: "system", name: "System", avatar: "⚙️"),
                type: .system
            )
            state.messages.append(systemMessage)
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        // UI actions
        case .clearMessages:
            state.messages.removeAll()
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        case .loadMessages:
            state.isLoading = true
            state.errorMessage = nil
            return [
                Effect { emitter in
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    let messages = [
                        AppState.Message(
                            text: "Welcome back!",
                            sender: AppState.User(id: "bot", name: "ChatBot", avatar: "🤖")
                        ),
                        AppState.Message(
                            text: "How can I help you today?",
                            sender: AppState.User(id: "bot", name: "ChatBot", avatar: "🤖")
                        )
                    ]
                    await emitter.withValue { emitter in
                        emitter.send(.messagesLoaded(messages))
                    }
                }
            ]
            
        case .messagesLoaded(let messages):
            state.messages = messages
            state.isLoading = false
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        case .showError(let message):
            state.errorMessage = message
            state.isLoading = false
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        case .clearError:
            state.errorMessage = nil
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        // Event Bus actions
        case .triggerUserJoin:
            return [
                Effect { emitter in
                    let newUser = AppState.User(id: "guest\(Int.random(in: 1000...9999))", name: "Guest", avatar: "👤")
                    await emitter.withValue { emitter in
                        emitter.send(.userJoined(newUser))
                    }
                }
            ]
            
        case .triggerUserLeave:
            let availableUsers = state.onlineUsers.filter { $0.id != state.currentUser.id }
            if let randomUser = availableUsers.randomElement() {
                return [
                    Effect { emitter in
                        await emitter.withValue { emitter in
                            emitter.send(.userLeft(randomUser))
                        }
                    }
                ]
            }
            return [Effect { _ in }]
            
        case .triggerMessageSent:
            return [
                Effect { emitter in
                    let botUser = AppState.User(id: "bot", name: "ChatBot", avatar: "🤖")
                    let responses = [
                        "That's interesting!",
                        "Tell me more about that.",
                        "I see what you mean.",
                        "Thanks for sharing!",
                        "Great point!"
                    ]
                    let randomResponse = responses.randomElement() ?? "Interesting!"
                    let message = AppState.Message(text: randomResponse, sender: botUser)
                    await emitter.withValue { emitter in
                        await emitter.send(.messageReceived(message))
                    }
                }
            ]
            
        case .triggerTyping:
            return [
                Effect { emitter in
                    await emitter.withValue { emitter in
                        await emitter.send(.setTyping(true))
                    }
                    
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    
                    await emitter.withValue { emitter in
                        await emitter.send(.setTyping(false))
                    }
                }
            ]
            
        case .triggerSystemEvent:
            return [
                Effect { emitter in
                    let systemMessage = AppState.Message(
                        text: "System maintenance in 5 minutes",
                        sender: AppState.User(id: "system", name: "System", avatar: "⚙️"),
                        type: .system
                    )
                    await emitter.withValue { emitter in
                        await emitter.send(.messageReceived(systemMessage))
                    }
                }
            ]
        }
    }
}

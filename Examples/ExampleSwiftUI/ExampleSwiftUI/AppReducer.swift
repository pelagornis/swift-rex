import Foundation
import Rex

public struct AppReducer: Reducer {
    private let navigation = GraphNavigationReducer<AppState>()

    public init() {}

    public func reduce(state: inout AppState, action: AppAction) -> [Effect<AppAction>] {
        switch action {
        case .graph(let graphAction):
            _ = navigation.reduce(state: &state, action: graphAction)
            if case .push(let id, _, _) = graphAction {
                appendLog(&state, "🧭 Pushed: \(id.rawValue)")
            } else if case .pop = graphAction {
                appendLog(&state, "🧭 Popped navigation node")
            }
            return []

        case .delegate(let delegateAction):
            return reduceDelegate(state: &state, action: delegateAction)

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
                    emitter.send(.userLoaded(user))
                }
            ]

        case .userLogout:
            state.currentUser = AppState.User(id: "guest", name: "Guest", avatar: "👤")
            state.lastUpdated = Date()
            return []

        case .userLoaded(let user):
            state.currentUser = user
            state.isLoading = false
            state.lastUpdated = Date()
            appendLog(&state, "👤 Logged in as \(user.name)")
            return []

        case .sendMessage(let text):
            let message = AppState.Message(text: text, sender: state.currentUser)
            state.messages.append(message)
            state.lastUpdated = Date()
            return []

        case .messageReceived(let message):
            state.messages.append(message)
            state.lastUpdated = Date()
            return []

        case .setTyping(let isTyping):
            state.isTyping = isTyping
            state.lastUpdated = Date()
            return []

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
            return []

        case .userLeft(let user):
            state.onlineUsers.removeAll { $0.id == user.id }
            let systemMessage = AppState.Message(
                text: "\(user.name) left the chat",
                sender: AppState.User(id: "system", name: "System", avatar: "⚙️"),
                type: .system
            )
            state.messages.append(systemMessage)
            state.lastUpdated = Date()
            return []

        case .clearMessages:
            state.messages.removeAll()
            state.lastUpdated = Date()
            return []

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
                    emitter.send(.messagesLoaded(messages))
                }
            ]

        case .messagesLoaded(let messages):
            state.messages = messages
            state.isLoading = false
            state.lastUpdated = Date()
            return []

        case .showError(let message):
            state.errorMessage = message
            state.isLoading = false
            state.lastUpdated = Date()
            return []

        case .clearError:
            state.errorMessage = nil
            state.lastUpdated = Date()
            return []

        case .logActivity(let message):
            appendLog(&state, message)
            return []

        case .triggerUserJoin:
            appendLog(&state, "▶️ Simulating user join…")
            return [
                Effect { emitter in
                    let newUser = AppState.User(
                        id: "guest\(Int.random(in: 1000...9999))",
                        name: "Guest",
                        avatar: "👤"
                    )
                    emitter.send(.userJoined(newUser))
                }
            ]

        case .triggerUserLeave:
            let availableUsers = state.onlineUsers.filter { $0.id != state.currentUser.id }
            if let randomUser = availableUsers.randomElement() {
                appendLog(&state, "▶️ Simulating user leave…")
                return [
                    Effect { emitter in
                        emitter.send(.userLeft(randomUser))
                    }
                ]
            }
            return []

        case .triggerMessageSent:
            appendLog(&state, "▶️ Simulating bot reply…")
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
                    emitter.send(.messageReceived(message))
                }
            ]

        case .triggerTyping:
            appendLog(&state, "▶️ Simulating typing indicator…")
            return [
                Effect(id: GraphEffectID.scoped(node: "chat", name: "typing")) { emitter in
                    emitter.send(.setTyping(true))
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    emitter.send(.setTyping(false))
                }
            ]

        case .triggerSystemEvent:
            appendLog(&state, "▶️ Simulating system event…")
            return [
                Effect { emitter in
                    let systemMessage = AppState.Message(
                        text: "System maintenance in 5 minutes",
                        sender: AppState.User(id: "system", name: "System", avatar: "⚙️"),
                        type: .system
                    )
                    emitter.send(.messageReceived(systemMessage))
                }
            ]
        }
    }

    private func reduceDelegate(state: inout AppState, action: DelegateAction) -> [Effect<AppAction>] {
        switch action {
        case .messageToChat(let text):
            let message = AppState.Message(
                text: text,
                sender: AppState.User(id: "second", name: "SecondView", avatar: "📱")
            )
            state.messages.append(message)
            appendLog(&state, "💬 Message from Second Page: \(text)")
            state.lastUpdated = Date()
            return []

        case .addUser(let name):
            let user = AppState.User(id: UUID().uuidString, name: name, avatar: "👤")
            state.onlineUsers.append(user)
            appendLog(&state, "👤 User added from Second Page: \(name)")
            state.lastUpdated = Date()
            return []

        case .systemNotification(let text):
            let message = AppState.Message(
                text: text,
                sender: AppState.User(id: "system", name: "System", avatar: "⚙️"),
                type: .system
            )
            state.messages.append(message)
            appendLog(&state, "⚙️ System: \(text)")
            state.lastUpdated = Date()
            return []

        case .navigatedBack:
            appendLog(&state, "🏠 Second page returned to first page")
            return []
        }
    }

    private func appendLog(_ state: inout AppState, _ message: String) {
        let entry = AppState.ActivityLogEntry(message: message)
        state.activityLog.insert(entry, at: 0)
        if state.activityLog.count > 20 {
            state.activityLog.removeLast()
        }
    }
}

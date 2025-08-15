# Swift-Rex

![Official](https://badge.pelagornis.com/official.svg)
[![Swift Version](https://img.shields.io/badge/Swift-6.1+-orange.svg)](https://swift.org)
[![iOS Version](https://img.shields.io/badge/iOS-13.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Swift Package Manager](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager)

Swift-Rex is a modern state management library that supports both SwiftUI and UIKit. Inspired by TCA (The Composable Architecture) and Redux, it provides a simple and intuitive API for managing application state.

## 🚀 Key Features

- 🎯 **Simple State Management**: Store, Reducer, Action pattern
- 🔄 **Async Processing**: Effect system for handling side effects
- 🔌 **Middleware Support**: Extensible system for logging, analytics, debugging, and more
- 📱 **Cross-Platform**: Support for both SwiftUI and UIKit
- ⚡ **Performance Optimized**: Efficient state updates and subscription system

- 📡 **Event Bus**: Global event system for cross-component communication

## 📦 Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/pelagornis/swift-rex.git", from: "1.0.0")
]
```

## 📖 Documentation

The documentation for releases and `main` are available here:

- [`main`](https://pelagornis.github.io/swift-rex/main/documentation/rex/)

## 🎯 Basic Usage

### 1. Define State

```swift
import Rex

struct AppState: StateType {
    var count: Int = 0
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var lastUpdated: Date = Date()
    var user: User?
    var theme: Theme = .light

    struct User: Codable, Equatable {
        let id: Int
        let name: String
        let email: String
    }

    enum Theme: String, CaseIterable, Codable {
        case light, dark, system
    }
}
```

### 2. Define Actions

```swift
enum AppAction: ActionType {
    // Counter actions
    case increment
    case decrement
    case reset
    case setCount(Int)

    // Async actions
    case loadFromServer
    case loadedFromServer(Int)
    case loadUser
    case userLoaded(AppState.User)

    // Error handling
    case setError(String?)
    case clearError

    // Theme actions
    case setTheme(AppState.Theme)

    // UI actions
    case showLoading
    case hideLoading
}
```

### 3. Define Reducer

```swift
struct AppReducer: Reducer {
    func reduce(state: inout AppState, action: AppAction) -> [Effect<AppAction>] {
        switch action {
        case .increment:
            state.count += 1
            state.lastUpdated = Date()
            return [Effect { _ in }]

        case .decrement:
            state.count -= 1
            state.lastUpdated = Date()
            return [Effect { _ in }]

        case .loadFromServer:
            state.isLoading = true
            state.errorMessage = nil
            return [
                Effect { emitter in
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    await emitter.withValue { emitter in
                        await emitter.send(.loadedFromServer(500))
                    }
                }
            ]

        case .loadedFromServer(let value):
            state.count = value
            state.isLoading = false
            state.lastUpdated = Date()
            return [Effect { _ in }]

        // ... other actions
        }
    }
}
```

### 4. Create Store

```swift
let store = Store(
    initialState: AppState(),
    reducer: AppReducer()
)
```

## 📱 SwiftUI Integration

### Using ObservableStore

```swift
import SwiftUI
import Rex

struct ContentView: View {
    @StateObject var store: ObservableStore<AppReducer>

    var body: some View {
        VStack(spacing: 20) {
            Text("Count: \(store.state.count)")
                .font(.title)

            HStack(spacing: 12) {
                Button("+1") { store.send(.increment) }
                Button("-1") { store.send(.decrement) }
            }

            Button("Load from Server") {
                store.send(.loadFromServer)
            }
            .disabled(store.state.isLoading)
        }
        .padding()
        .environmentObject(store)
    }
}

// Initialize Store in App
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Custom AppStore Usage

```swift
@MainActor
class AppStore: ObservableObject {
    @Published var state: AppState
    let store: Store<AppReducer>

    init(store: Store<AppReducer>) {
        self.store = store
        self.state = store.getInitialState()

        store.subscribe { [weak self] newState in
            Task { @MainActor in
                self?.state = newState
            }
        }
    }

    func send(_ action: AppAction) {
        store.dispatch(action)
    }

    func getEventBus() -> EventBus {
        return store.getEventBus()
    }
}

struct ContentView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        // UI implementation
    }
}
```

## 🎨 UIKit Integration

In UIKit, you can use `Store` directly for a simple implementation:

```swift
import UIKit
import Rex

class ViewController: UIViewController {
    private let store: Store<AppReducer>

    private let label = UILabel()
    private let incrementButton = UIButton(type: .system)
    private let decrementButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)

    init() {
        self.store = Store(
            initialState: AppState(),
            reducer: AppReducer()
        )
        super.init(nibName: nil, bundle: nil)

        store.subscribe { [weak self] _ in
            Task { @MainActor in
                self?.updateUI()
            }
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI()
    }

    private func updateUI() {
        label.text = "Count: \(store.state.count)"
        store.state.isLoading ? spinner.startAnimating() : spinner.stopAnimating()
    }

    @objc private func increment() { store.dispatch(.increment) }
    @objc private func decrement() { store.dispatch(.decrement) }
    @objc private func load() { store.dispatch(.loadFromServer) }
}

// Initialize Store in SceneDelegate
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let ws = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: ws)

        let viewController = ViewController()
        let navigationController = UINavigationController(rootViewController: viewController)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}
```

## 🔄 Effects

Effect system for handling asynchronous operations and side effects:

```swift
// Network request
Effect { emitter in
    let data = try await URLSession.shared.data(from: url)
    let response = try JSONDecoder().decode(Response.self, from: data.0)
            await emitter.withValue { emitter in
            emitter.send(.dataLoaded(response))
        }
}

// Timer
Effect { emitter in
    for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect() {
        await emitter.withValue { emitter in
            emitter.send(.timerTick)
        }
    }
}

// Send multiple actions
Effect { emitter in
            await emitter.withValue { emitter in
            emitter.send(.action1)
            emitter.send(.action2)
        }
}
```

## 🔌 Middleware

Middleware system for logging, analytics, debugging, and more:

```swift
struct LoggingMiddleware: Middleware {
    func process(state: AppState, action: AppAction, emit: @escaping (AppAction) -> Void) async -> [Effect<AppAction>] {
        print("[LoggingMiddleware] Action: \(action), State: \(state)")
        return [.none]
    }
}

struct AnalyticsMiddleware: Middleware {
    func process(state: AppState, action: AppAction, emit: @escaping (AppAction) -> Void) async -> [Effect<AppAction>] {
        // Send analytics event
        Analytics.track(action: action)
        return [.none]
    }
}

// Add middleware to Store (optional)
let store = Store(
    initialState: AppState(),
    reducer: AppReducer(),
    middlewares: [
        LoggingMiddleware(),
        AnalyticsMiddleware()
    ]
)
```

## 📡 Event Bus

EventBus provides a global event system for handling cross-component communication and side effects. Each Store has its own EventBus instance for isolated event handling.

### Basic Usage

```swift
// Custom events
struct UserLoggedInEvent: EventType {
    let userId: String
    let timestamp: Date
}

struct NetworkErrorEvent: EventType {
    let error: String
    let code: Int
}

// Publishing events
store.getEventBus().publish(UserLoggedInEvent(userId: "123"))
store.getEventBus().publish(NetworkErrorEvent(error: "Connection failed", code: 500))

// Using convenience methods
store.getEventBus().publishAppEvent(name: "user_action", data: ["action": "login"])
store.getEventBus().publishNavigation(route: "/profile", parameters: ["userId": "123"])
store.getEventBus().publishUserAction(action: "button_tap", screen: "login", metadata: ["button": "login"])

// Subscribing to events
store.getEventBus().subscribe(to: UserLoggedInEvent.self) { event in
    print("User logged in: \(event.userId)")
}

// Subscribe with filter
store.getEventBus().subscribe(
    to: NetworkErrorEvent.self,
    where: { $0.code >= 500 },
    handler: { event in
        print("Critical error: \(event.error)")
    }
)

// Subscribe to all events
store.getEventBus().subscribe { event in
    print("Event: \(event)")
}
```

### Event Bus Use Cases

1. **User Authentication**: Handle login/logout events across the app
2. **Navigation**: Manage navigation state and deep linking
3. **Error Handling**: Global error management and user notifications
4. **Analytics**: Track user actions and app usage
5. **Cross-Component Communication**: Communicate between unrelated components
6. **Background Tasks**: Handle app lifecycle and background processing

### Event Bus in SwiftUI

```swift
struct ContentView: View {
    @ObservedObject var store: AppStore

    @State private var eventLog: [String] = []

    var body: some View {
        VStack {
            // Event log display
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(eventLog, id: \.self) { log in
                        Text(log)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                }
            }
            .frame(maxHeight: 200)

            // Event publishing buttons
            Button("Send Message") {
                Task { @MainActor in
                    store.getEventBus().publishChatEvent(
                        type: "user_message",
                        message: "Hello from SwiftUI!",
                        sender: "User"
                    )
                }
            }
        }
        .onAppear {
            setupEventListeners()
        }
    }

    private func setupEventListeners() {
        Task { @MainActor in
            // Subscribe to chat events
            store.getEventBus().subscribe(to: ChatEvent.self) { event in
                eventLog.insert("💬 \(event.type): \(event.message)", at: 0)
                if eventLog.count > 20 {
                    eventLog.removeLast()
                }
            }

            // Subscribe to user events
            store.getEventBus().subscribe(to: UserEvent.self) { event in
                eventLog.insert("👤 \(event.action): \(event.username)", at: 0)
                if eventLog.count > 20 {
                    eventLog.removeLast()
                }
            }
        }
    }
}
```

### Event Bus in UIKit

```swift
class ViewController: UIViewController {
    private let store: Store<AppReducer>

    private let logTextView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupEventListeners()
    }

    private func setupEventListeners() {
        Task { @MainActor in
            // Subscribe to navigation events
            store.getEventBus().subscribe(to: NavigationEvent.self) { event in
                self.addLog("🧭 Navigation: \(event.route)")
                self.navigate(to: event.route, parameters: event.parameters)
            }

            // Subscribe to user action events
            store.getEventBus().subscribe(to: UserActionEvent.self) { event in
                self.addLog("👆 Action: \(event.action) on \(event.screen)")
            }
        }
    }

    private func addLog(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        let logEntry = "[\(timestamp)] \(message)\n"
        logTextView.text += logEntry
    }

    @objc private func sendEvent() {
        Task { @MainActor in
            store.getEventBus().publishAppEvent(
                name: "button_pressed",
                data: ["button": "send_event"]
            )
        }
    }
}
```

### Multi-Page Event Bus Communication

```swift
// First page (ContentView)
struct ContentView: View {
    @ObservedObject var store: AppStore
    @State private var showingSecondPage = false

    var body: some View {
        VStack {
            Button("Go to Second Page") {
                showingSecondPage = true
            }
        }
        .sheet(isPresented: $showingSecondPage) {
            SecondView(store: store)
        }
    }
}

// Second page (SecondView)
struct SecondView: View {
    @ObservedObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Button("Send Message to First Page") {
                Task { @MainActor in
                    store.getEventBus().publishChatEvent(
                        type: "message_from_second",
                        message: "Hello from Second Page!",
                        sender: "SecondView"
                    )
                }
            }

            Button("Back") {
                Task { @MainActor in
                    store.getEventBus().publishSystemEvent(
                        event: "navigation",
                        details: ["action": "back_to_first"]
                    )
                }
                dismiss()
            }
        }
    }
}
```

## 📋 Example Apps

The project includes example apps for both SwiftUI and UIKit:

- **SwiftUI Example**: Chat app demonstrating Event Bus functionality
- **UIKit Example**: Game app demonstrating multi-page Event Bus communication

Run the example apps to see all Swift-Rex features in action.

## License

**swift-rex** is under MIT license. See the [LICENSE](LICENSE) file for more info.

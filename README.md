# Swift-Rex

Swift-Rex is a modern state management library that supports both SwiftUI and UIKit. Inspired by TCA (The Composable Architecture) and Redux, it provides a simple and intuitive API.

## Key Features

- 🎯 **Simple State Management**: Store, Reducer, Action pattern
- 🔄 **Async Processing**: Effect system for handling side effects
- 🔌 **Middleware Support**: Extensible system for logging, analytics, debugging, and more
- 📱 **Cross-Platform**: Support for both SwiftUI and UIKit
- ⚡ **Performance Optimized**: Efficient state updates and subscription system
- 🕒 **Time Travel**: State history tracking for debugging

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/your-username/swift-rex.git", from: "1.0.0")
]
```

## Basic Usage

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
            return [.none]

        case .decrement:
            state.count -= 1
            state.lastUpdated = Date()
            return [.none]

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
            return [.none]

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
) {
    LoggingMiddleware()
}
```

## SwiftUI Integration

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
        .loading(store) {
            ProgressView("Loading...")
        }
        .errorAlert(
            store,
            errorKeyPath: \.errorMessage,
            dismissAction: .clearError
        )
    }
}

// Initialize Store in App
@main
struct MyApp: App {
    let store = Store(
        initialState: AppState(),
        reducer: AppReducer()
    )

    var body: some Scene {
        WindowGroup {
            ContentView(store: ObservableStore(store: store))
        }
    }
}
```

### SwiftUI View Modifiers

```swift
// Show loading state
.loading(store) {
    ProgressView("Loading...")
}

// Custom loading state
.loading(store, keyPath: \.isLoading) {
    CustomLoadingView()
}

// Error alert
.errorAlert(
    store,
    errorKeyPath: \.errorMessage,
    dismissAction: .clearError
)

// Conditional rendering
.if(store.state.isLoading) { view in
    view.overlay(ProgressView())
}

// Binding
Picker("Theme", selection: store.binding(
    for: \.theme,
    action: { .setTheme($0) }
)) {
    ForEach(AppState.Theme.allCases, id: \.self) { theme in
        Text(theme.rawValue.capitalized).tag(theme)
    }
}
```

## UIKit Integration

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

    init(store: Store<AppReducer>) {
        self.store = store
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

// Initialize Store in AppDelegate
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let store = Store(
            initialState: AppState(),
            reducer: AppReducer()
        )

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = ViewController(store: store)
        window?.makeKeyAndVisible()

        return true
    }
}
```

## Effects

Effect system for handling asynchronous operations and side effects:

```swift
// Network request
Effect { emitter in
    let data = try await URLSession.shared.data(from: url)
    let response = try JSONDecoder().decode(Response.self, from: data.0)
    await emitter.withValue { emitter in
        await emitter.send(.dataLoaded(response))
    }
}

// Timer
Effect { emitter in
    for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect() {
        await emitter.withValue { emitter in
            await emitter.send(.timerTick)
        }
    }
}

// Send multiple actions
Effect { emitter in
    await emitter.withValue { emitter in
        await emitter.send(.action1)
        await emitter.send(.action2)
    }
}
```

## Middleware

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

// Add middleware to Store
let store = Store(
    initialState: AppState(),
    reducer: AppReducer()
) {
    LoggingMiddleware()
    AnalyticsMiddleware()
}
```

## License

MIT License - see the [LICENSE](LICENSE) file for details.

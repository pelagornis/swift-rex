# Getting Started

Learn how to integrate Swift-Rex into your iOS app and create your first state management setup.

## Overview

This guide will walk you through setting up Swift-Rex in your project and creating a simple counter app to demonstrate the basic concepts.

## Installation

### Swift Package Manager

Add Swift-Rex to your project using Swift Package Manager:

1. In Xcode, go to **File** > **Add Package Dependencies**
2. Enter the repository URL: `https://github.com/pelagornis/swift-rex.git`
3. Select the version you want to use
4. Click **Add Package**

### Manual Installation

If you prefer to add it manually, add this to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/pelagornis/swift-rex.git", from: "vTag")
]
```

## Your First Swift-Rex App

Let's create a simple counter app to demonstrate the basic concepts.

### 1. Define Your State

First, define what your app's state looks like:

```swift
import Rex

struct AppState: StateType {
    var count: Int = 0
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var lastUpdated: Date = Date()
}
```

### 2. Define Your Actions

Next, define the actions that can change your state:

```swift
enum AppAction: ActionType {
    case increment
    case decrement
    case reset
    case setCount(Int)
    case loadFromServer
    case loadedFromServer(Int)
    case showError(String?)
    case clearError
}
```

### 3. Create Your Reducer

Create a reducer that handles state changes:

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

        case .reset:
            state.count = 0
            state.lastUpdated = Date()
            return [.none]

        case .setCount(let count):
            state.count = count
            state.lastUpdated = Date()
            return [.none]

        case .loadFromServer:
            state.isLoading = true
            state.errorMessage = nil
            return [
                Effect { emitter in
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    let randomCount = Int.random(in: 1...100)
                    await emitter.send(.loadedFromServer(randomCount))
                }
            ]

        case .loadedFromServer(let count):
            state.count = count
            state.isLoading = false
            state.lastUpdated = Date()
            return [.none]

        case .showError(let message):
            state.errorMessage = message
            state.isLoading = false
            state.lastUpdated = Date()
            return [.none]

        case .clearError:
            state.errorMessage = nil
            state.lastUpdated = Date()
            return [.none]
        }
    }
}
```

### 4. Create Your Store

Create a store that manages your state:

```swift
let store = Store(
    initialState: AppState(),
    reducer: AppReducer()
) {
    LoggingMiddleware()
}
```

### 5. Use in SwiftUI

Create a SwiftUI view that uses your store:

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

            Button("Reset") { store.send(.reset) }

            Button("Load from Server") {
                store.send(.loadFromServer)
            }
            .disabled(store.state.isLoading)

            if store.state.isLoading {
                ProgressView("Loading...")
            }

            if let error = store.state.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .onTapGesture {
                        store.send(.clearError)
                    }
            }
        }
        .padding()
    }
}

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

### 6. Use in UIKit

For UIKit, you can use the store directly:

```swift
import UIKit
import Rex

class ViewController: UIViewController {
    private let store: Store<AppReducer>
    private let label = UILabel()
    private let incrementButton = UIButton(type: .system)
    private let decrementButton = UIButton(type: .system)

    init(store: Store<AppReducer>) {
        self.store = store
        super.init(nibName: nil, bundle: nil)

        store.subscribe { [weak self] newState in
            Task { @MainActor in
                self?.updateUI(with: newState)
            }
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI(with: store.state)
    }

    private func setupUI() {
        // Setup your UI elements here
        incrementButton.addTarget(self, action: #selector(increment), for: .touchUpInside)
        decrementButton.addTarget(self, action: #selector(decrement), for: .touchUpInside)
    }

    private func updateUI(with state: AppState) {
        label.text = "Count: \(state.count)"
    }

    @objc private func increment() { store.dispatch(.increment) }
    @objc private func decrement() { store.dispatch(.decrement) }
}
```

## Next Steps

Now that you have a basic understanding of Swift-Rex, explore these topics:

- <doc:BasicConcepts> - Learn about the core concepts
- <doc:StateManagement> - Understand state management patterns
- <doc:SwiftUIIntegration> - Deep dive into SwiftUI integration
- <doc:UIKitIntegration> - Learn about UIKit integration
- <doc:EventBus> - Explore cross-component communication

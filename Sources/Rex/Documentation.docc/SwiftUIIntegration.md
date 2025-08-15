# SwiftUI Integration

Learn how to integrate Swift-Rex with SwiftUI applications.

## Overview

Swift-Rex provides seamless integration with SwiftUI through the `ObservableStore` class and various property wrappers. This integration allows you to use Swift-Rex's state management system while taking advantage of SwiftUI's reactive UI framework.

## ObservableStore

### Basic Usage

`ObservableStore` is an `ObservableObject` that wraps a Swift-Rex `Store`, making it compatible with SwiftUI's reactive system.

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

            Button("Load Data") {
                store.send(.loadData)
            }
            .disabled(store.state.isLoading)
        }
        .padding()
    }
}
```

### Store Initialization

Create the store in your app's entry point:

```swift
@main
struct MyApp: App {
    let store = Store(
        initialState: AppState(),
        reducer: AppReducer()
    ) {
        LoggingMiddleware()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: ObservableStore(store: store))
        }
    }
}
```

## Property Wrappers

### @StateObject

Use `@StateObject` for the root view that owns the store:

```swift
struct ContentView: View {
    @StateObject var store: ObservableStore<AppReducer>
    
    var body: some View {
        // Your UI here
    }
}
```

### @ObservedObject

Use `@ObservedObject` for child views that receive the store:

```swift
struct ChildView: View {
    @ObservedObject var store: ObservableStore<AppReducer>
    
    var body: some View {
        Button("Increment") {
            store.send(.increment)
        }
    }
}
```

## State Access

### Direct State Access

Access state properties directly through the store:

```swift
struct UserProfileView: View {
    @ObservedObject var store: ObservableStore<AppReducer>
    
    var body: some View {
        VStack {
            if let user = store.state.user {
                Text("Welcome, \(user.name)")
                Text("Email: \(user.email)")
            } else {
                Text("Please log in")
            }
            
            if store.state.isLoading {
                ProgressView()
            }
        }
    }
}
```

### Computed Properties

Use computed properties for derived state:

```swift
struct TodoListView: View {
    @ObservedObject var store: ObservableStore<AppReducer>
    
    private var filteredTodos: [Todo] {
        switch store.state.todo.filter {
        case .all:
            return store.state.todo.todos
        case .completed:
            return store.state.todo.todos.filter { $0.isCompleted }
        case .incomplete:
            return store.state.todo.todos.filter { !$0.isCompleted }
        }
    }
    
    var body: some View {
        List(filteredTodos, id: \.id) { todo in
            TodoRowView(todo: todo) {
                store.send(.todo(.toggle(todo.id)))
            }
        }
    }
}
```

## Action Dispatching

### Simple Actions

Dispatch actions directly from UI events:

```swift
Button("Increment") {
    store.send(.increment)
}
```

### Actions with Parameters

Pass data to actions:

```swift
TextField("Todo title", text: $todoText)
    .onSubmit {
        store.send(.todo(.add(todoText)))
        todoText = ""
    }
```

### Conditional Actions

Dispatch actions based on conditions:

```swift
Button("Save") {
    if store.state.user != nil {
        store.send(.saveUser)
    } else {
        store.send(.showError("User not found"))
    }
}
```

## Loading and Error States

### Loading States

Handle loading states in your UI:

```swift
struct DataView: View {
    @ObservedObject var store: ObservableStore<AppReducer>
    
    var body: some View {
        Group {
            if store.state.isLoading {
                VStack {
                    ProgressView()
                    Text("Loading data...")
                }
            } else {
                DataContentView(store: store)
            }
        }
    }
}
```

### Error Handling

Display and handle errors:

```swift
struct ErrorView: View {
    @ObservedObject var store: ObservableStore<AppReducer>
    
    var body: some View {
        Group {
            if let error = store.state.errorMessage {
                VStack {
                    Text("Error")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(error)
                        .multilineTextAlignment(.center)
                    
                    Button("Dismiss") {
                        store.send(.clearError)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }
}
```

## Event Bus Integration

### Subscribing to Events

Use the EventBus for cross-component communication:

```swift
struct ContentView: View {
    @StateObject var store: ObservableStore<AppReducer>
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var eventLog: [String] = []
    
    var body: some View {
        VStack {
            // Your main UI
            MainView(store: store)
            
            // Event log
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(eventLog, id: \.self) { log in
                        Text(log)
                            .font(.caption)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .onAppear {
            setupEventListeners()
        }
    }
    
    private func setupEventListeners() {
        Task { @MainActor in
            store.getEventBus().subscribe { event in
                eventLog.insert("Event: \(type(of: event))", at: 0)
                if eventLog.count > 20 {
                    eventLog.removeLast()
                }
            }
            .store(in: &cancellables)
        }
    }
}
```

### Publishing Events

Publish events from your UI:

```swift
Button("Send Notification") {
    Task { @MainActor in
        store.getEventBus().publish(
            NotificationEvent(
                title: "User Action",
                message: "Button was tapped"
            )
        )
    }
}
```

## Custom AppStore

### Creating a Custom Store

For more complex applications, you can create a custom `AppStore`:

```swift
@MainActor
class AppStore: ObservableObject {
    @Published var state: AppState
    let store: Store<AppReducer>

    init(store: Store<AppReducer>) {
        self.store = store
        self.state = store.state

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
```

### Using Custom Store

Use your custom store in SwiftUI views:

```swift
struct ContentView: View {
    @ObservedObject var store: AppStore
    
    var body: some View {
        VStack {
            Text("Count: \(store.state.count)")
            Button("Increment") {
                store.send(.increment)
            }
        }
    }
}
```

## Best Practices

### 1. Use @StateObject for Root Views

Always use `@StateObject` for views that own the store:

```swift
struct ContentView: View {
    @StateObject var store: ObservableStore<AppReducer>
    // ...
}
```

### 2. Use @ObservedObject for Child Views

Use `@ObservedObject` for views that receive the store:

```swift
struct ChildView: View {
    @ObservedObject var store: ObservableStore<AppReducer>
    // ...
}
```

### 3. Keep Views Focused

Don't pass the entire store to every view. Only pass what's needed:

```swift
// ❌ Don't pass entire store
struct TodoRowView: View {
    @ObservedObject var store: ObservableStore<AppReducer>
    
    var body: some View {
        // Access store.state.todo.todos[index]
    }
}

// ✅ Pass only what's needed
struct TodoRowView: View {
    let todo: Todo
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Text(todo.title)
            Spacer()
            Button("Toggle") {
                onToggle()
            }
        }
    }
}
```

### 4. Use Computed Properties

Use computed properties for derived state:

```swift
struct TodoListView: View {
    @ObservedObject var store: ObservableStore<AppReducer>
    
    private var completedTodos: [Todo] {
        store.state.todo.todos.filter { $0.isCompleted }
    }
    
    var body: some View {
        List(completedTodos, id: \.id) { todo in
            TodoRowView(todo: todo)
        }
    }
}
```

### 5. Handle Loading States

Always provide loading indicators:

```swift
if store.state.isLoading {
    ProgressView("Loading...")
} else {
    // Your content
}
```

### 6. Manage Event Bus Subscriptions

Always store cancellables to prevent memory leaks:

```swift
@State private var cancellables: Set<AnyCancellable> = []

store.getEventBus().subscribe { event in
    // Handle event
}
.store(in: &cancellables)
```

## Next Steps

Now that you understand SwiftUI integration, explore:

- <doc:UIKitIntegration> - Learn about UIKit integration
- <doc:EventBus> - Explore cross-component communication
- <doc:Middleware> - Add logging and analytics
- <doc:BestPractices> - Advanced patterns and tips

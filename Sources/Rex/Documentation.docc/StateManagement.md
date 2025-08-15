# State Management

Learn how to effectively manage application state with Swift-Rex.

## Overview

State management is the core of any Swift-Rex application. Understanding how to structure and manage your state effectively is crucial for building maintainable and scalable applications.

## State Structure

### Single State Tree

Swift-Rex uses a single state tree that represents the entire state of your application. This makes it easy to track changes and debug issues.

```swift
struct AppState: StateType {
    // User state
    var user: User?
    var isAuthenticated: Bool = false

    // UI state
    var isLoading: Bool = false
    var errorMessage: String? = nil

    // Feature state
    var counter: CounterState = CounterState()
    var todo: TodoState = TodoState()
    var settings: SettingsState = SettingsState()

    // App state
    var lastUpdated: Date = Date()
}
```

### Nested State

Break down your state into smaller, focused pieces:

```swift
struct CounterState {
    var count: Int = 0
    var history: [Int] = []
}

struct TodoState {
    var todos: [Todo] = []
    var filter: TodoFilter = .all
    var isLoading: Bool = false
}

struct SettingsState {
    var theme: Theme = .light
    var notifications: Bool = true
    var language: Language = .english
}
```

## State Updates

### Immutable Updates

Always create new state rather than modifying existing state:

```swift
// ❌ Wrong - Direct mutation
state.count += 1

// ✅ Correct - Create new state
state.count = state.count + 1
```

### Batch Updates

When updating multiple properties, do it in a single action:

```swift
case .userLoggedIn(let user):
    state.user = user
    state.isAuthenticated = true
    state.errorMessage = nil
    state.lastUpdated = Date()
    return [.none]
```

## State Normalization

### Normalized Data

Store related data in a normalized structure for better performance:

```swift
struct AppState: StateType {
    // Normalized entities
    var users: [String: User] = [:]
    var posts: [String: Post] = [:]
    var comments: [String: Comment] = [:]

    // References
    var currentUserId: String?
    var selectedPostId: String?

    // UI state
    var isLoading: Bool = false
    var errorMessage: String? = nil
}
```

### Benefits of Normalization

- **Performance**: Faster lookups and updates
- **Consistency**: Single source of truth for each entity
- **Memory**: Reduced memory usage
- **Updates**: Easier to update related data

## State Composition

### Combining Reducers

Split your reducer into smaller, focused reducers:

```swift
struct AppReducer: Reducer {
    func reduce(state: inout AppState, action: AppAction) -> [Effect<AppAction>] {
        switch action {
        case let .counter(action):
            return counterReducer.reduce(state: &state.counter, action: action)

        case let .todo(action):
            return todoReducer.reduce(state: &state.todo, action: action)

        case let .settings(action):
            return settingsReducer.reduce(state: &state.settings, action: action)

        case .userLoggedIn(let user):
            state.user = user
            state.isAuthenticated = true
            return [.none]
        }
    }
}
```

### Action Composition

Use associated values to compose actions:

```swift
enum AppAction: ActionType {
    case counter(CounterAction)
    case todo(TodoAction)
    case settings(SettingsAction)
    case user(UserAction)
}

enum CounterAction: ActionType {
    case increment
    case decrement
    case reset
}

enum TodoAction: ActionType {
    case add(String)
    case remove(String)
    case toggle(String)
    case setFilter(TodoFilter)
}
```

## State Persistence

### Saving State

Persist important state to disk:

```swift
struct AppReducer: Reducer {
    func reduce(state: inout AppState, action: AppAction) -> [Effect<AppAction>] {
        switch action {
        case .userLoggedIn(let user):
            state.user = user
            state.isAuthenticated = true
            return [
                Effect { emitter in
                    // Save user to disk
                    try await UserDefaults.standard.setValue(
                        user.id,
                        forKey: "currentUserId"
                    )
                    await emitter.send(.userSaved)
                }
            ]
        }
    }
}
```

### Loading State

Load persisted state on app launch:

```swift
struct AppReducer: Reducer {
    func reduce(state: inout AppState, action: AppAction) -> [Effect<AppAction>] {
        switch action {
        case .loadPersistedState:
            return [
                Effect { emitter in
                    if let userId = UserDefaults.standard.string(forKey: "currentUserId") {
                        let user = try await UserService.fetchUser(id: userId)
                        await emitter.send(.userLoaded(user))
                    }
                }
            ]
        }
    }
}
```

## State Validation

### Input Validation

Validate state changes in your reducer:

```swift
case .setCount(let count):
    guard count >= 0 else {
        state.errorMessage = "Count cannot be negative"
        return [.none]
    }
    state.count = count
    state.lastUpdated = Date()
    return [.none]
```

### State Constraints

Enforce business rules in your state:

```swift
struct AppState: StateType {
    var count: Int = 0 {
        didSet {
            // Ensure count never goes below 0
            if count < 0 {
                count = 0
            }
        }
    }
}
```

## Performance Optimization

### Selective Updates

Only update what has changed:

```swift
case .updateUserProfile(let profile):
    // Only update if profile actually changed
    if state.user?.profile != profile {
        state.user?.profile = profile
        state.lastUpdated = Date()
    }
    return [.none]
```

### Computed Properties

Use computed properties for derived state:

```swift
extension AppState {
    var completedTodos: [Todo] {
        todos.filter { $0.isCompleted }
    }

    var incompleteTodos: [Todo] {
        todos.filter { !$0.isCompleted }
    }

    var todoCount: Int {
        todos.count
    }
}
```

## Best Practices

### 1. Keep State Minimal

Only store what you need:

```swift
// ❌ Don't store derived data
struct AppState {
    var todos: [Todo] = []
    var completedTodos: [Todo] = [] // Redundant
}

// ✅ Store only source data
struct AppState {
    var todos: [Todo] = []
}
```

### 2. Use Descriptive Names

Make your state properties self-documenting:

```swift
// ❌ Unclear
var flag: Bool = false

// ✅ Clear
var isUserLoggedIn: Bool = false
```

### 3. Group Related State

Keep related properties together:

```swift
struct AppState {
    // Authentication
    var user: User?
    var isAuthenticated: Bool = false
    var authToken: String?

    // UI State
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var currentTab: Tab = .home

    // Feature State
    var counter: CounterState = CounterState()
    var todo: TodoState = TodoState()
}
```

### 4. Handle Loading States

Always track loading states for async operations:

```swift
case .loadUser:
    state.isLoading = true
    state.errorMessage = nil
    return [
        Effect { emitter in
            let user = try await UserService.fetchUser()
            await emitter.send(.userLoaded(user))
        }
    ]
```

### 5. Error Handling

Provide meaningful error messages:

```swift
case .loadUserFailed(let error):
    state.isLoading = false
    state.errorMessage = "Failed to load user: \(error.localizedDescription)"
    return [.none]
```

## Next Steps

Now that you understand state management, explore:

- <doc:Store> - Learn about the Store implementation
- <doc:Reducer> - Understand Reducer patterns
- <doc:Effect> - Handle side effects
- <doc:BestPractices> - Advanced patterns and tips

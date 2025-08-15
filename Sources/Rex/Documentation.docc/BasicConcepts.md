# Basic Concepts

Learn the fundamental concepts that make up the Swift-Rex architecture.

## Overview

Swift-Rex is built around a few core concepts that work together to provide a predictable and manageable state management system. Understanding these concepts is key to building effective applications with Swift-Rex.

## State

State represents the current condition of your application at any point in time. It's the single source of truth for your app's data.

### Key Characteristics

- **Immutable**: State should never be modified directly
- **Serializable**: State can be saved and restored
- **Predictable**: Given the same inputs, state changes are always the same
- **Observable**: Changes to state trigger UI updates

### Example

```swift
struct AppState: StateType {
    var count: Int = 0
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var lastUpdated: Date = Date()
    var user: User?
}
```

## Actions

Actions describe what happened in your application. They are the only way to change state.

### Key Characteristics

- **Descriptive**: Actions clearly describe what happened
- **Immutable**: Actions contain only the data needed to describe the event
- **Serializable**: Actions can be logged and replayed
- **Type-Safe**: Actions are strongly typed

### Example

```swift
enum AppAction: ActionType {
    // User interactions
    case increment
    case decrement
    case setCount(Int)
    
    // Async operations
    case loadUser
    case userLoaded(User)
    case loadFailed(String)
    
    // UI state
    case showLoading
    case hideLoading
    case setError(String?)
}
```

## Reducers

Reducers are pure functions that take the current state and an action, then return a new state and any effects.

### Key Principles

- **Pure Functions**: Reducers have no side effects
- **Predictable**: Same state + action always produces same result
- **Immutable**: Always return new state, never modify existing state
- **Composable**: Reducers can be combined and split

### Example

```swift
struct AppReducer: Reducer {
    func reduce(state: inout AppState, action: AppAction) -> [Effect<AppAction>] {
        switch action {
        case .increment:
            state.count += 1
            state.lastUpdated = Date()
            return [.none]
            
        case .loadUser:
            state.isLoading = true
            state.errorMessage = nil
            return [
                Effect { emitter in
                    let user = try await UserService.fetchUser()
                    await emitter.send(.userLoaded(user))
                }
            ]
            
        case .userLoaded(let user):
            state.user = user
            state.isLoading = false
            state.lastUpdated = Date()
            return [.none]
        }
    }
}
```

## Store

The store is the central coordinator that holds the state, dispatches actions, and manages effects.

### Responsibilities

- **State Management**: Holds the current application state
- **Action Dispatching**: Processes actions through the reducer
- **Effect Execution**: Runs side effects and async operations
- **Subscription Management**: Notifies subscribers of state changes

### Example

```swift
let store = Store(
    initialState: AppState(),
    reducer: AppReducer()
) {
    LoggingMiddleware()
}

// Subscribe to state changes
store.subscribe { newState in
    print("State updated: \(newState)")
}

// Dispatch actions
store.dispatch(.increment)
store.dispatch(.loadUser)
```

## Effects

Effects represent side effects or asynchronous operations that can't be performed in the reducer.

### Use Cases

- **Network Requests**: API calls and data fetching
- **File Operations**: Reading and writing files
- **Timers**: Scheduled operations
- **Device Services**: Camera, location, etc.

### Example

```swift
// Network request effect
Effect { emitter in
    let data = try await URLSession.shared.data(from: url)
    let response = try JSONDecoder().decode(User.self, from: data.0)
    await emitter.send(.userLoaded(response))
}

// Timer effect
Effect { emitter in
    for await _ in Timer.publish(every: 1, on: .main, in: .common).autoconnect() {
        await emitter.send(.timerTick)
    }
}
```

## Data Flow

Swift-Rex follows a unidirectional data flow:

1. **User Interaction**: User performs an action (e.g., taps a button)
2. **Action Dispatch**: An action is dispatched to the store
3. **Middleware Processing**: Actions pass through middleware (logging, analytics, etc.)
4. **Reducer Processing**: The reducer processes the action and updates state
5. **Effect Execution**: Any effects returned by the reducer are executed
6. **State Update**: The store updates its state
7. **UI Update**: Subscribers are notified and the UI updates

### Visual Flow

```
User Action → Action Dispatch → Middleware → Reducer → Effects → State Update → UI Update
```

## Benefits

This architecture provides several key benefits:

- **Predictability**: State changes are predictable and traceable
- **Debugging**: Easy to debug with action logging and time travel
- **Testing**: Pure functions are easy to test
- **Performance**: Efficient updates and minimal re-renders
- **Scalability**: Architecture scales well with app complexity
- **Maintainability**: Clear separation of concerns

## Next Steps

Now that you understand the basic concepts, explore:

- <doc:StateManagement> - Learn about state management patterns
- <doc:Store> - Deep dive into the Store
- <doc:Reducer> - Learn about Reducer patterns
- <doc:Effect> - Understand Effects and side effects

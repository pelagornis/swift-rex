import Foundation
import Combine

/// The central coordinator for state management in Swift-Rex.
///
/// The `Store` is the heart of the Swift-Rex architecture. It holds the current state,
/// dispatches actions to the reducer, manages effects, and notifies subscribers of
/// state changes. It serves as the single source of truth for your application's state.
///
/// ## Overview
///
/// The store is responsible for:
/// - Holding the current application state
/// - Dispatching actions to the reducer
/// - Executing effects returned by the reducer
/// - Notifying subscribers when state changes
/// - Managing middleware for logging, analytics, and debugging
/// - Providing access to the EventBus for cross-component communication
///
/// ## Key Features
///
/// - **State Management**: Centralized state storage and updates
/// - **Action Dispatching**: Process actions through the reducer
/// - **Effect Execution**: Handle async operations and side effects
/// - **Subscription System**: Notify subscribers of state changes
/// - **Middleware Support**: Extensible system for cross-cutting concerns
/// - **Event Bus Integration**: Built-in event system for component communication
///
/// ## Example
///
/// ```swift
/// // Create a store
/// let store = Store(
///     initialState: AppState(),
///     reducer: AppReducer()
/// ) {
///     LoggingMiddleware()
///     AnalyticsMiddleware()
/// }
///
/// // Subscribe to state changes
/// store.subscribe { newState in
///     print("State updated: \(newState)")
/// }
///
/// // Dispatch actions
/// store.dispatch(.increment)
/// store.dispatch(.loadUser)
///
/// // Access EventBus
/// store.getEventBus().publish(UserLoggedInEvent(userId: "123"))
/// ```
///
/// ## Thread Safety
///
/// The store is designed to be thread-safe. All state updates happen on the main
/// thread, and the store uses appropriate synchronization to ensure consistency.
/// However, you should always dispatch actions from the main thread for best results.
///
/// ## Lifecycle
///
/// The store is typically created once at app startup and shared throughout
/// the application. It can be injected into view controllers, SwiftUI views,
/// or other components that need access to the state.
public final class Store<R: Reducer> {
    /// The current state of the application.
    ///
    /// This property provides read-only access to the current state. To modify
    /// the state, dispatch actions through the `dispatch(_:)` method.
    public private(set) var state: R.State
    
    /// The reducer that processes actions and updates the state.
    private let reducer: R
    
    /// The middleware chain that processes actions before and after the reducer.
    private let middlewares: [AnyMiddleware<R.State, R.Action>]
    
    /// The EventBus instance for cross-component communication.
    private let eventBus: EventBus
    
    /// Combine cancellables for managing subscriptions.
    private var cancellables: Set<AnyCancellable> = []
    
    /// Subscribers that should be notified when state changes.
    private var subscribers: [(R.State) -> Void] = []
    
    /// A lock for ensuring thread-safe access to the store.
    private let lock = NSLock()
    
    /// Creates a new store with the specified initial state, reducer, and middleware.
    ///
    /// - Parameters:
    ///   - initialState: The initial state of the application.
    ///   - reducer: The reducer that will process actions and update the state.
    ///   - middlewares: A closure that returns an array of middleware to apply.
    ///     Defaults to an empty array if no middleware is needed.
    ///   - eventBus: An optional EventBus instance. If not provided, a new one will be created.
    public init(
        initialState: R.State,
        reducer: R,
        middlewares: @escaping () -> [AnyMiddleware<R.State, R.Action>] = { [] },
        eventBus: EventBus = EventBus()
    ) {
        self.state = initialState
        self.reducer = reducer
        self.middlewares = middlewares()
        self.eventBus = eventBus
    }
    
    /// Dispatches an action to the store.
    ///
    /// This method processes the action through the middleware chain, then
    /// through the reducer, and finally executes any effects returned by the reducer.
    /// State changes are automatically propagated to all subscribers.
    ///
    /// - Parameter action: The action to dispatch.
    public func dispatch(_ action: R.Action) {
        lock.lock()
        defer { lock.unlock() }
        
        // Process through middleware
        Task {
            for middleware in middlewares {
                let effects = await middleware.process(
                    state: state,
                    action: action,
                    emit: { [weak self] action in
                        self?.dispatch(action)
                    }
                )
                
                for effect in effects {
                    await effect.run { [weak self] action in
                        self?.dispatch(action)
                    }
                }
            }
            
            // Process through reducer
            var newState = state
            let effects = reducer.reduce(state: &newState, action: action)
            
            // Update state
            await MainActor.run {
                self.state = newState
                self.notifySubscribers()
            }
            
            // Execute effects
            for effect in effects {
                await effect.run { [weak self] action in
                    self?.dispatch(action)
                }
            }
        }
    }
    
    /// Subscribes to state changes.
    ///
    /// The provided closure will be called whenever the state changes. The closure
    /// receives the new state as a parameter.
    ///
    /// - Parameter subscriber: A closure that will be called with the new state.
    public func subscribe(_ subscriber: @escaping (R.State) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        
        subscribers.append(subscriber)
        
        // Immediately call with current state
        subscriber(state)
    }
    
    /// Provides access to the EventBus for cross-component communication.
    ///
    /// The EventBus allows components to publish and subscribe to events without
    /// direct coupling. This is useful for handling cross-cutting concerns like
    /// navigation, analytics, and error handling.
    ///
    /// - Returns: The EventBus instance associated with this store.
    @MainActor
    public func getEventBus() -> EventBus {
        return eventBus
    }
    
    /// Notifies all subscribers of the current state.
    ///
    /// This method is called automatically whenever the state changes. You typically
    /// don't need to call this method directly.
    private func notifySubscribers() {
        for subscriber in subscribers {
            subscriber(state)
        }
    }
}

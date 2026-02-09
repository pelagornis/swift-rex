import Foundation

/// A thread-safe store that manages application state using the Redux pattern.
///
/// The Store is the central hub of the state management system. It holds the application state,
/// processes actions through middlewares and reducers, and notifies subscribers of state changes.
/// All state updates are processed sequentially to ensure consistency and prevent race conditions.
///
/// ## Example
/// ```swift
/// struct AppState: State {
///     var count: Int = 0
/// }
///
/// enum AppAction: Action {
///     case increment
///     case decrement
/// }
///
/// struct AppReducer: Reducer {
///     func reduce(state: inout AppState, action: AppAction) -> [Effect<AppAction>] {
///         switch action {
///         case .increment:
///             state.count += 1
///         case .decrement:
///             state.count -= 1
///         }
///         return []
///     }
/// }
///
/// let store = Store(initialState: AppState(), reducer: AppReducer())
/// store.dispatch(.increment)
/// ```
public final class Store<R: Reducer>: Sendable {
    /// State type from the reducer.
    public typealias State = R.State
    /// Action type from the reducer.
    public typealias Action = R.Action

    private let dispatchActor: DispatchActor<R.State, R.Action, R>
    private let stateActor: StateActor<R.State>
    private let subscribersActor: SubscribersActor<R.State>
    private let reducer: R
    private let middlewares: [AnyMiddleware<R.State, R.Action>]
    private let eventBus: EventBus
    private let initialState: R.State

    /// Creates a new Store instance.
    ///
    /// - Parameters:
    ///   - initialState: The initial state of the application.
    ///   - reducer: The reducer that processes actions and updates state.
    ///   - middlewares: A closure that returns an array of middlewares to process actions.
    ///   - eventBus: An optional EventBus for cross-component communication.
    public init(
        initialState: R.State,
        reducer: R,
        middlewares: @escaping () -> [AnyMiddleware<R.State, R.Action>] = { [] },
        eventBus: EventBus = EventBus()
    ) {
        self.stateActor = StateActor(initialState)
        self.subscribersActor = SubscribersActor()
        self.reducer = reducer
        let middlewaresArray = middlewares()
        self.middlewares = middlewaresArray
        self.eventBus = eventBus
        self.initialState = initialState
        
        // Initialize DispatchActor with Store references
        self.dispatchActor = DispatchActor(
            stateActor: stateActor,
            subscribersActor: subscribersActor,
            reducer: reducer,
            middlewares: middlewaresArray
        )
    }

    /// The current state of the store.
    ///
    /// Accessing this property is asynchronous and will return the current state.
    /// State updates are processed sequentially to ensure consistency.
    public var state: R.State {
        get async {
            await stateActor.state
        }
    }

    /// Returns the initial state that was used when creating the store.
    ///
    /// - Returns: The initial state value.
    public func getInitialState() -> R.State {
        return initialState
    }

    /// Dispatches an action to be processed by the store.
    ///
    /// The action will be processed through all middlewares first, then through the reducer.
    /// State updates and subscriber notifications happen sequentially to ensure order.
    ///
    /// - Parameter action: The action to dispatch.
    public func dispatch(_ action: R.Action) {
        Task {
            await dispatchActor.dispatch(action) { [weak self] action in
                self?.dispatch(action)
            }
        }
    }

    /// Subscribes to state changes.
    ///
    /// The subscriber will be called immediately with the current state, and then
    /// whenever the state changes.
    ///
    /// - Parameter subscriber: A closure that receives state updates.
    public func subscribe(_ subscriber: @escaping @Sendable (R.State) -> Void) {
        Task {
            await subscribersActor.addSubscriber(subscriber)
            let currentState = await stateActor.state
            subscriber(currentState)
        }
    }

    /// Returns the EventBus associated with this store.
    ///
    /// - Returns: The EventBus instance for publishing and subscribing to events.
    @MainActor
    public func getEventBus() -> EventBus {
        return eventBus
    }
}

/// An actor that ensures sequential processing of actions.
///
/// This actor guarantees that all actions are processed one at a time,
/// preventing race conditions and ensuring state consistency.
private actor DispatchActor<State, Action, R: Reducer> where R.State == State, R.Action == Action {
    private let stateActor: StateActor<State>
    private let subscribersActor: SubscribersActor<State>
    private let reducer: R
    private let middlewares: [AnyMiddleware<State, Action>]
    
    init(
        stateActor: StateActor<State>,
        subscribersActor: SubscribersActor<State>,
        reducer: R,
        middlewares: [AnyMiddleware<State, Action>]
    ) {
        self.stateActor = stateActor
        self.subscribersActor = subscribersActor
        self.reducer = reducer
        self.middlewares = middlewares
    }
    
    /// Processes an action through middlewares and reducer, updating state sequentially.
    ///
    /// This method ensures that all actions are processed in order by using actor isolation.
    /// It first processes middlewares, then applies the reducer, updates state, notifies subscribers,
    /// and finally runs any effects returned by the reducer.
    ///
    /// - Parameters:
    ///   - action: The action to process.
    ///   - dispatchCallback: A closure to dispatch new actions (used for effects).
    func dispatch(
        _ action: Action,
        dispatchCallback: @escaping @Sendable (Action) -> Void
    ) async {
        // Get current state
        let currentState = await stateActor.state
        
        // Process through all middlewares
        for middleware in middlewares {
            let effects = await middleware.process(
                state: currentState,
                action: action,
                emit: dispatchCallback
            )
            
            // Run middleware effects
            for effect in effects {
                await effect.run(dispatch: dispatchCallback)
            }
        }
        
        // Apply reducer to update state
        var newState = currentState
        let effects = reducer.reduce(state: &newState, action: action)
        
        // Update state and notify subscribers
        await stateActor.setState(newState)
        await subscribersActor.notifySubscribers(newState)
        
        // Run reducer effects
        for effect in effects {
            await effect.run(dispatch: dispatchCallback)
        }
    }
}

/// An actor that manages the application state.
///
/// This actor ensures thread-safe access to the state.
private actor StateActor<State> {
    var state: State

    init(_ initialState: State) {
        self.state = initialState
    }

    /// Updates the state to a new value.
    ///
    /// - Parameter newState: The new state value.
    func setState(_ newState: State) {
        state = newState
    }
}

/// An actor that manages state subscribers.
///
/// This actor ensures thread-safe management of subscribers and notifications.
private actor SubscribersActor<State> {
    var subscribers: [@Sendable (State) -> Void] = []

    /// Adds a new subscriber to the list.
    ///
    /// - Parameter subscriber: The closure to call when state changes.
    func addSubscriber(_ subscriber: @escaping @Sendable (State) -> Void) {
        subscribers.append(subscriber)
    }

    /// Notifies all subscribers of a state change.
    ///
    /// - Parameter state: The new state to notify subscribers about.
    func notifySubscribers(_ state: State) {
        for subscriber in subscribers {
            subscriber(state)
        }
    }
}

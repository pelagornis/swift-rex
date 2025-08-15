import Foundation

/// A protocol that defines the requirements for reducers in the Swift-Rex architecture.
///
/// Reducers are pure functions that take the current state and an action, then return
/// a new state and any effects that should be executed. They are the core of the
/// state management system, responsible for all state transitions.
///
/// ## Overview
///
/// Reducers are the single source of truth for how your application's state changes
/// in response to actions. They should be pure functions with no side effects,
/// making them predictable and testable.
///
/// ## Key Principles
///
/// - **Pure Functions**: Reducers should not have side effects or depend on external state
/// - **Immutable Updates**: Always return a new state rather than modifying the existing one
/// - **Predictable**: Given the same state and action, a reducer should always return the same result
/// - **Composable**: Reducers can be combined and split into smaller, focused reducers
///
/// ## Example
///
/// ```swift
/// struct AppReducer: Reducer {
///     func reduce(state: inout AppState, action: AppAction) -> [Effect<AppAction>] {
///         switch action {
///         case .increment:
///             state.count += 1
///             state.lastUpdated = Date()
///             return [.none]
///             
///         case .decrement:
///             state.count -= 1
///             state.lastUpdated = Date()
///             return [.none]
///             
///         case .loadUser:
///             state.isLoading = true
///             state.errorMessage = nil
///             return [
///                 Effect { emitter in
///                     let user = try await UserService.fetchUser()
///                     await emitter.send(.userLoaded(user))
///                 }
///             ]
///             
///         case .userLoaded(let user):
///             state.user = user
///             state.isLoading = false
///             state.lastUpdated = Date()
///             return [.none]
///             
///         case .loadFailed(let error):
///             state.errorMessage = error
///             state.isLoading = false
///             state.lastUpdated = Date()
///             return [.none]
///         }
///     }
/// }
/// ```
///
/// ## Effects
///
/// Reducers can return effects that represent side effects or asynchronous operations.
/// Effects are executed by the store and can dispatch new actions when they complete.
/// Use `.none` when no effects are needed.
///
/// ## Best Practices
///
/// - Keep reducers focused on a single domain or feature
/// - Use switch statements to handle all possible actions
/// - Always update `lastUpdated` when state changes
/// - Handle loading and error states consistently
/// - Return effects for async operations, not for synchronous state updates
public protocol Reducer {
    /// The type of state this reducer manages.
    associatedtype State: StateType
    
    /// The type of actions this reducer can handle.
    associatedtype Action: ActionType
    
    /// Reduces the current state based on the given action.
    ///
    /// This method is called by the store whenever an action is dispatched.
    /// It should examine the action and update the state accordingly, then
    /// return any effects that should be executed.
    ///
    /// - Parameters:
    ///   - state: The current state to be updated. This is an `inout` parameter
    ///     that should be modified directly.
    ///   - action: The action that triggered this reduction.
    /// - Returns: An array of effects that should be executed. Return `[.none]`
    ///   if no effects are needed.
    func reduce(state: inout State, action: Action) -> [Effect<Action>]
}

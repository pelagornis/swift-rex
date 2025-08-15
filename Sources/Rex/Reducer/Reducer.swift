import Foundation

/// A protocol that defines the core logic for transforming state based on actions.
///
/// Reducers are pure functions that take the current state and an action,
/// then return a new state and any effects that should be executed.
/// They are the heart of the state management system and should contain
/// all the business logic for state transitions.
///
/// ## Example
/// ```swift
/// struct AppReducer: Reducer {
///     func reduce(state: inout AppState, action: AppAction) -> [Effect<AppAction>] {
///         switch action {
///         case .increment:
///             state.count += 1
///             state.lastUpdated = Date()
///             return [Effect { _ in }]
///             
///         case .loadUser:
///             state.isLoading = true
///             return [
///                 Effect { emitter in
///                     let user = try await fetchUser()
///                     await emitter.withValue { emitter in
///                         emitter.send(.userLoaded(user))
///                     }
///                 }
///             ]
///         }
///     }
/// }
/// ```
public protocol Reducer: Sendable {
    /// The type of state this reducer manages.
    associatedtype State: StateType
    
    /// The type of actions this reducer can handle.
    associatedtype Action: ActionType
    
    /// Transforms the current state based on the given action.
    ///
    /// - Parameters:
    ///   - state: The current state to transform. This parameter is modified in place.
    ///   - action: The action that describes the state change.
    /// - Returns: An array of effects that should be executed as a result of this action.
    func reduce(state: inout State, action: Action) -> [Effect<Action>]
}

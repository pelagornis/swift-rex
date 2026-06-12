import Foundation

/// A type-erased reducer for combining heterogeneous reducers.
public struct AnyReducer<State: Statable, Action: Actionable>: Reducer {
    private let _reduce: @Sendable (inout State, Action) -> [Effect<Action>]

    public init<R: Reducer>(_ reducer: R) where R.State == State, R.Action == Action {
        _reduce = { state, action in
            reducer.reduce(state: &state, action: action)
        }
    }

    public func reduce(state: inout State, action: Action) -> [Effect<Action>] {
        _reduce(&state, action)
    }
}

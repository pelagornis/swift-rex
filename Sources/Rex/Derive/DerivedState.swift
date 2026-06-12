import Foundation

/// A memoized derived value computed from base state.
public struct DerivedState<State: Statable, Value: Equatable & Sendable>: Sendable {
    private let compute: @Sendable (State) -> Value
    private var cachedState: State?
    private var cachedValue: Value?

    public init(_ compute: @escaping @Sendable (State) -> Value) {
        self.compute = compute
    }

    /// Returns the derived value, recomputing only when the input state changes.
    public mutating func value(from state: State) -> Value {
        if let cachedState, cachedState == state, let cachedValue {
            return cachedValue
        }
        let value = compute(state)
        cachedState = state
        cachedValue = value
        return value
    }

    public mutating func invalidate() {
        cachedState = nil
        cachedValue = nil
    }
}

/// Computes a derived value from state without caching (for one-off use in views).
public func derive<State: Statable, Value: Equatable & Sendable>(
    from state: State,
    _ compute: (State) -> Value
) -> Value {
    compute(state)
}

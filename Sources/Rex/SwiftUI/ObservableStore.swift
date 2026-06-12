#if canImport(SwiftUI)
import SwiftUI

/// A SwiftUI-friendly wrapper around `Store` that holds state on the Main Actor and exposes
/// type-safe bindings and action dispatch.
///
/// Use `ObservableStore` as the single source of truth in SwiftUI:
/// - `state` is `@Published` and drives view updates.
/// - `send(_:)` dispatches actions; only `Reducer.Action` is accepted.
/// - `binding(_:send:)` builds two-way bindings that dispatch actions on change.
///
/// ## Example
/// ```swift
/// struct CounterView: View {
///     @ObservedObject var store: ObservableStore<AppReducer>
///
///     var body: some View {
///         VStack {
///             Text("\(store.state.count)")
///             TextField("Name", text: store.binding(\.name, send: AppAction.setName))
///             Button("Increment") { store.send(.increment) }
///         }
///     }
/// }
/// ```
@MainActor
public final class ObservableStore<R: Reducer>: ObservableObject, Sendable {
    /// State type from the reducer.
    public typealias State = R.State
    /// Action type from the reducer.
    public typealias Action = R.Action

    public let store: Store<R>
    @Published public private(set) var state: State

    public init(store: Store<R>) {
        self.store = store
        self.state = store.getInitialState()

        Task {
            store.subscribe { [weak self] newState in
                Task { @MainActor in
                    self?.state = newState
                }
            }
        }
    }

    /// Dispatches an action to the store. Only actions of type `R.Action` are accepted.
    public func send(_ action: Action) {
        store.dispatch(action)
    }

    /// Returns a type-safe two-way binding that reads from `state` and dispatches an action on write.
    ///
    /// - Parameters:
    ///   - keyPath: Key path into `State` for the value (e.g. `\.name`).
    ///   - send: Closure that turns the new value into an action (e.g. `AppAction.setName`).
    /// - Returns: A `Binding<Value>` suitable for SwiftUI controls.
    public func binding<Value>(
        _ keyPath: KeyPath<State, Value>,
        send: @escaping (Value) -> Action
    ) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { self.send(send($0)) }
        )
    }

    public func getEventBus() -> EventBus {
        return store.getEventBus()
    }
}
#endif

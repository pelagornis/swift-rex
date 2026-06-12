import Foundation

/// Pulls back a child reducer into a parent state/action domain (feature scoping).
public struct ScopeReducer<
    ParentState: Statable,
    ParentAction: Actionable,
    Child: Reducer
>: Reducer, @unchecked Sendable {
    private let child: Child
    private let scopeState: WritableKeyPath<ParentState, Child.State>
    private let embedAction: @Sendable (Child.Action) -> ParentAction
    private let extractAction: @Sendable (ParentAction) -> Child.Action?

    public init(
        _ child: Child,
        state scopeState: WritableKeyPath<ParentState, Child.State>,
        action embedAction: @escaping @Sendable (Child.Action) -> ParentAction,
        extract extractAction: @escaping @Sendable (ParentAction) -> Child.Action?
    ) {
        self.child = child
        self.scopeState = scopeState
        self.embedAction = embedAction
        self.extractAction = extractAction
    }

    public typealias State = ParentState
    public typealias Action = ParentAction

    public func reduce(state: inout ParentState, action: ParentAction) -> [Effect<ParentAction>] {
        guard let childAction = extractAction(action) else {
            return []
        }

        let childEffects = child.reduce(state: &state[keyPath: scopeState], action: childAction)
        return childEffects.map { mapEffect($0, embed: embedAction) }
    }
}

public extension Reducer {
    /// Scopes this reducer to a child domain within a parent reducer.
    func scope<ParentState: Statable, ParentAction: Actionable>(
        state scopeState: WritableKeyPath<ParentState, State>,
        action embedAction: @escaping @Sendable (Action) -> ParentAction,
        extract extractAction: @escaping @Sendable (ParentAction) -> Action?
    ) -> ScopeReducer<ParentState, ParentAction, Self> {
        ScopeReducer(
            self,
            state: scopeState,
            action: embedAction,
            extract: extractAction
        )
    }
}

private func mapEffect<ParentAction: Actionable, ChildAction: Actionable>(
    _ effect: Effect<ChildAction>,
    embed: @escaping @Sendable (ChildAction) -> ParentAction
) -> Effect<ParentAction> {
    let mappedID: EffectID? = effect.id.map { EffectID("scoped:\($0.rawValue)") }

    return Effect(id: mappedID, cancelInFlight: effect.cancelInFlight) {
        AsyncStream { continuation in
            let task = Task {
                for await action in effect.makeStream() {
                    continuation.yield(embed(action))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

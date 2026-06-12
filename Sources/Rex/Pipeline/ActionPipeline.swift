import Foundation

/// Result of a full pipeline pass for a single action.
struct PipelineResult<State: Statable, Action: Actionable>: Sendable {
    var preReducerEffects: [Effect<Action>]
    var stateAfter: State
    var postReducerEffects: [Effect<Action>]
}

/// Orchestrates action processing through pipeline hooks and reducer.
struct ActionPipeline<State: Statable, Action: Actionable, R: Reducer>: Sendable
where R.State == State, R.Action == Action {
    private let hooks: [AnyPipelineHook<State, Action>]
    private let reducer: R

    init(hooks: [AnyPipelineHook<State, Action>], reducer: R) {
        self.hooks = hooks
        self.reducer = reducer
    }

    /// Runs hooks and reducer. Returns `nil` when aborted.
    func process(
        _ incomingAction: Action,
        stateBefore: State,
        dispatchCallback: @escaping @Sendable (Action) -> Void
    ) async -> PipelineResult<State, Action>? {
        var action = incomingAction
        var context = PipelineContext(
            action: action,
            stateBefore: stateBefore,
            dispatch: dispatchCallback
        )

        guard await runHooks(.willReceive(action), context: &context, action: &action) else {
            return nil
        }

        let preReducerEffects = context.effects
        context.effects = []

        guard await runHooks(.willReduce(action, stateBefore), context: &context, action: &action) else {
            return nil
        }

        var stateAfter = stateBefore
        let reducerEffects = reducer.reduce(state: &stateAfter, action: action)
        context.stateAfter = stateAfter

        guard await runHooks(
            .didReduce(action, before: stateBefore, after: stateAfter),
            context: &context,
            action: &action
        ) else {
            return nil
        }

        var postReducerEffects = reducerEffects + context.effects
        context.effects = []

        guard await runHooks(
            .willRunEffects(action, effectCount: postReducerEffects.count),
            context: &context,
            action: &action
        ) else {
            return nil
        }

        postReducerEffects.append(contentsOf: context.effects)

        _ = await runHooks(.didRunEffects(action), context: &context, action: &action)
        _ = await runHooks(.didComplete(action), context: &context, action: &action)

        return PipelineResult(
            preReducerEffects: preReducerEffects,
            stateAfter: stateAfter,
            postReducerEffects: postReducerEffects
        )
    }

    private func runHooks(
        _ phase: PipelinePhase<Action, State>,
        context: inout PipelineContext<Action, State>,
        action: inout Action
    ) async -> Bool {
        for hook in hooks {
            let result = await hook.handle(phase: phase, context: context)

            switch result {
            case .continue:
                continue

            case .transform(let newAction):
                action = newAction
                context.action = newAction

            case .abort:
                return false

            case .appendEffects(let effects):
                context.effects.append(contentsOf: effects)
            }
        }
        return true
    }
}

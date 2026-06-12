import Foundation

/// Cancels graph-node-scoped effects when nodes are unmounted from ``StateGraph``.
public final class GraphLifecyclePipelineHook<State: GraphStateContainer, Action: Actionable>: PipelineHook {
    private let effectRunnerBox = EffectRunnerBox<Action>()
    private let storage = MountedStorage()

    public init() {}

    func bind(effectRunner: EffectRunner<Action>) {
        effectRunnerBox.runner = effectRunner
    }

    public func handle(
        phase: PipelinePhase<Action, State>,
        context: PipelineContext<Action, State>
    ) async -> HookResult<Action> {
        guard case .didReduce = phase else {
            return .continue
        }

        let currentMounted = context.stateAfter?.graph.mounted ?? context.stateBefore.graph.mounted
        let lastMounted = await storage.snapshot()
        let unmounted = lastMounted.subtracting(currentMounted)

        if let runner = effectRunnerBox.runner {
            for nodeID in unmounted {
                await runner.cancelMatchingPrefix(GraphEffectID.prefix(for: nodeID))
            }
        }

        await storage.update(currentMounted)
        return .continue
    }
}

private actor MountedStorage {
    private var mounted: Set<GraphNodeID> = []

    func snapshot() -> Set<GraphNodeID> {
        mounted
    }

    func update(_ mounted: Set<GraphNodeID>) {
        self.mounted = mounted
    }
}

private final class EffectRunnerBox<Action: Actionable>: @unchecked Sendable {
    var runner: EffectRunner<Action>?
}

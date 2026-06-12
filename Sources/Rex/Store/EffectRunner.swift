import Foundation

/// Tracks long-lived ``Effect`` streams and applies cancellation policies.
actor EffectRunner<Action: Actionable> {
    private var running: [EffectID: Task<Void, Never>] = [:]

    /// Runs effects. Effects with an ``EffectID`` are started concurrently; others are awaited sequentially.
    func run(
        _ effects: [Effect<Action>],
        dispatch: @escaping @Sendable (Action) -> Void
    ) async {
        for effect in effects {
            if effect.id != nil {
                startTracked(effect, dispatch: dispatch)
            } else {
                await effect.run(dispatch: dispatch)
            }
        }
    }

    func cancel(id: EffectID) {
        running[id]?.cancel()
        running[id] = nil
    }

    func cancelAll() {
        for task in running.values {
            task.cancel()
        }
        running.removeAll()
    }

    /// Cancels all tracked effects whose id starts with the given prefix.
    func cancelMatchingPrefix(_ prefix: String) {
        for id in running.keys where id.rawValue.hasPrefix(prefix) {
            cancel(id: id)
        }
    }

    private func startTracked(
        _ effect: Effect<Action>,
        dispatch: @escaping @Sendable (Action) -> Void
    ) {
        guard let id = effect.id else { return }

        if effect.cancelInFlight {
            running[id]?.cancel()
        }

        let task = Task { [weak self] in
            for await action in effect.makeStream() {
                if Task.isCancelled { break }
                dispatch(action)
            }
            await self?.remove(id)
        }
        running[id] = task
    }

    private func remove(_ id: EffectID) {
        running[id] = nil
    }
}

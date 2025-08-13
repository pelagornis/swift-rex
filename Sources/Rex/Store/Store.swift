import Foundation

public final class Store<R: Reducer>: @unchecked Sendable where R.State: StateType {
    public private(set) var state: R.State
    private let reducer: R
    private let middlewares: [AnyMiddleware<R.State, R.Action>]
    private let effectEmitter: ActorIsolated<EffectEmitter<R.Action>>
    private let effectQueue: EffectQueue<R.Action>
    private let timeTravel: TimeTravelMiddleware<R.State, R.Action>?

    private var subscribers: [@Sendable (R.State) -> Void] = []
    private let queue = DispatchQueue(label: "rex.store.serial")

    public init(
        initialState: R.State,
        reducer: R,
        middlewares: [AnyMiddleware<R.State, R.Action>] = [],
        effectStrategy: EffectStrategy = .concurrent,
        enableTimeTravel: Bool = false
    ) {
        self.state = initialState
        self.reducer = reducer
        self.middlewares = middlewares
        self.effectEmitter = ActorIsolated(value: EffectEmitter<R.Action>())
        self.effectQueue = EffectQueue(strategy: effectStrategy, emitter: effectEmitter)

        if enableTimeTravel {
            let tt = TimeTravelMiddleware<R.State, R.Action>()
            Task { await tt.record(initialState) }
            self.timeTravel = tt
        } else {
            self.timeTravel = nil
        }

        Task { [weak self] in
            guard let self = self else { return }
            await self.effectEmitter.withValue { emitter in
                await emitter.setSendAction { [weak self] action in
                    self?.dispatch(action)
                }
            }
        }
    }

    public func subscribe(_ subscriber: @Sendable @escaping (R.State) -> Void) {
        queue.sync {
            self.subscribers.append(subscriber)
            subscriber(self.state)
        }
    }

    private func notify() {
        for sub in subscribers {
            sub(state)
        }
    }

    public func dispatch(_ action: R.Action) {
        queue.async { [weak self] in
            guard let self = self else { return }

            Task { [weak self] in
                guard let self = self else { return }
                var collectedEffects: [Effect<R.Action>] = []

                for middleware in self.middlewares {
                    let effects = await middleware.process(state: self.state, action: action, emit: { [weak self] a in
                        self?.dispatch(a)
                    })
                    collectedEffects.append(contentsOf: effects)
                }

                let producedEffects = self.reducer.reduce(state: &self.state, action: action)
                collectedEffects.append(contentsOf: producedEffects)

                if let tt = self.timeTravel {
                    await tt.record(self.state)
                }

                for effect in collectedEffects {
                    await self.effectQueue.enqueue(effect)
                }

                self.notify()
            }
        }
    }

    public func jumpTo(index: Int) {
        guard let tt = timeTravel else { return }
        Task {
            if let s = await tt.jumpTo(index) {
                self.queue.async {
                    self.state = s
                    self.notify()
                }
            }
        }
    }

    public func undo() {
        guard let tt = timeTravel else { return }
        Task {
            if let s = await tt.undo() {
                self.queue.async {
                    self.state = s
                    self.notify()
                }
            }
        }
    }

    public func redo() {
        guard let tt = timeTravel else { return }
        Task {
            if let s = await tt.redo() {
                self.queue.async {
                    self.state = s
                    self.notify()
                }
            }
        }
    }
}

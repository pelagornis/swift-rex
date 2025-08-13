public enum EffectStrategy: Sendable {
    case sequential
    case concurrent
    case latestOnly
}

public actor EffectQueue<A: Action> {
    private let strategy: EffectStrategy
    private let emitter: ActorIsolated<EffectEmitter<A>>

    private var tasks: [Task<Void, Never>] = []
    private var latestTasks: [String: Task<Void, Never>] = [:]

    public init(strategy: EffectStrategy = .concurrent, emitter: ActorIsolated<EffectEmitter<A>>) {
        self.strategy = strategy
        self.emitter = emitter
    }

    public func enqueue(_ effect: Effect<A>, key: String? = nil) {
        switch strategy {
        case .concurrent:
            let task = Task {
                await effect.run(emitter)
            }
            tasks.append(task)

        case .sequential:
            // 이전 작업이 끝날 때까지 대기 후 실행
            let previousTask = tasks.last
            let task = Task {
                if let previousTask = previousTask {
                    _ = await previousTask.result
                }
                await effect.run(emitter)
            }
            tasks.append(task)

        case .latestOnly:
            guard let key = key else {
                let task = Task {
                    await effect.run(emitter)
                }
                tasks.append(task)
                return
            }

            if let oldTask = latestTasks[key] {
                oldTask.cancel()
            }

            let task = Task {
                await effect.run(emitter)
            }
            latestTasks[key] = task
        }
    }

    public func cancelAll() {
        for task in tasks {
            task.cancel()
        }
        for task in latestTasks.values {
            task.cancel()
        }
        tasks.removeAll()
        latestTasks.removeAll()
    }
}

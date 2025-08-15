public enum EffectStrategy: Sendable {
    case sequential
    case concurrent
    case latestOnly
}

public actor EffectQueue<Action: ActionType> {
    private let strategy: EffectStrategy
    private let dispatch: @Sendable (Action) -> Void

    private var tasks: [Task<Void, Never>] = []
    private var latestTasks: [String: Task<Void, Never>] = [:]

    public init(strategy: EffectStrategy = .concurrent, dispatch: @escaping @Sendable (Action) -> Void) {
        self.strategy = strategy
        self.dispatch = dispatch
    }

    public func enqueue(_ effect: Effect<Action>, key: String? = nil) {
        let dispatch = self.dispatch
        let effect = effect
        
        switch strategy {
        case .concurrent:
            let task = Task {
                await effect.run(dispatch: dispatch)
            }
            tasks.append(task)

        case .sequential:
            // 이전 작업이 끝날 때까지 대기 후 실행
            let previousTask = tasks.last
            let task = Task {
                if let previousTask = previousTask {
                    _ = await previousTask.result
                }
                await effect.run(dispatch: dispatch)
            }
            tasks.append(task)

        case .latestOnly:
            guard let key = key else {
                let task = Task {
                    await effect.run(dispatch: dispatch)
                }
                tasks.append(task)
                return
            }

            if let oldTask = latestTasks[key] {
                oldTask.cancel()
            }

            let task = Task {
                await effect.run(dispatch: dispatch)
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

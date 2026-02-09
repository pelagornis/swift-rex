/// Defines the strategy for executing effects in the queue.
public enum EffectStrategy: Sendable {
    /// Effects are executed sequentially, one after another.
    case sequential
    /// Effects are executed concurrently, all at the same time.
    case concurrent
    /// Only the latest effect with the same key is executed, canceling previous ones.
    case latestOnly
}

/// An actor that manages a queue of effects with different execution strategies.
///
/// The EffectQueue provides control over how effects are executed, allowing for
/// sequential, concurrent, or latest-only execution patterns.
///
/// ## Example
/// ```swift
/// let queue = EffectQueue<AppAction>(strategy: .sequential) { action in
///     store.dispatch(action)
/// }
///
/// queue.enqueue(Effect.just(.increment))
/// queue.enqueue(Effect.just(.decrement))
/// ```
public actor EffectQueue<Action: ActionProtocol> {
    private let strategy: EffectStrategy
    private let dispatch: @Sendable (Action) -> Void

    private var tasks: [Task<Void, Never>] = []
    private var latestTasks: [String: Task<Void, Never>] = [:]

    /// Creates a new EffectQueue with the specified strategy.
    ///
    /// - Parameters:
    ///   - strategy: The execution strategy for effects. Defaults to `.concurrent`.
    ///   - dispatch: A closure that dispatches actions returned by effects.
    public init(strategy: EffectStrategy = .concurrent, dispatch: @escaping @Sendable (Action) -> Void) {
        self.strategy = strategy
        self.dispatch = dispatch
    }

    /// Adds an effect to the queue for execution.
    ///
    /// The effect will be executed according to the queue's strategy:
    /// - `.concurrent`: Executes immediately alongside other effects
    /// - `.sequential`: Waits for previous effects to complete
    /// - `.latestOnly`: Cancels previous effects with the same key before executing
    ///
    /// - Parameters:
    ///   - effect: The effect to enqueue.
    ///   - key: An optional key for `.latestOnly` strategy. Effects with the same key will cancel previous ones.
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
            // Wait for previous task to complete before executing
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

    /// Cancels all pending and running effects in the queue.
    ///
    /// This method cancels all tasks in both the regular task queue and the latest-only task map.
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

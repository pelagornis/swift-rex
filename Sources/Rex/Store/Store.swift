import Foundation
import Combine

public final class Store<R: Reducer>: Sendable {
    private let stateActor: StateActor<R.State>
    private let cancellablesActor: CancellablesActor
    private let subscribersActor: SubscribersActor<R.State>
    private let reducer: R
    private let middlewares: [AnyMiddleware<R.State, R.Action>]
    private let eventBus: EventBus
    private let lock = NSLock()

    public init(
        initialState: R.State,
        reducer: R,
        middlewares: @escaping () -> [AnyMiddleware<R.State, R.Action>] = { [] },
        eventBus: EventBus = EventBus()
    ) {
        self.stateActor = StateActor(initialState)
        self.cancellablesActor = CancellablesActor()
        self.subscribersActor = SubscribersActor()
        self.reducer = reducer
        self.middlewares = middlewares()
        self.eventBus = eventBus
    }

    public var state: R.State {
        get async {
            await stateActor.state
        }
    }

    public func dispatch(_ action: R.Action) {
        lock.lock()
        defer { lock.unlock() }

        let currentMiddlewares = middlewares
        let currentReducer = reducer

        Task { @MainActor in
            let currentState = await stateActor.state
            
            for middleware in currentMiddlewares {
                let effects = await middleware.process(
                    state: currentState,
                    action: action,
                    emit: { [weak self] action in
                        self?.dispatch(action)
                    }
                )

                for effect in effects {
                    await effect.run { [weak self] action in
                        self?.dispatch(action)
                    }
                }
            }

            var newState = currentState
            let effects = currentReducer.reduce(state: &newState, action: action)

            await stateActor.setState(newState)
            await subscribersActor.notifySubscribers(newState)

            for effect in effects {
                await effect.run { [weak self] action in
                    self?.dispatch(action)
                }
            }
        }
    }

    public func subscribe(_ subscriber: @escaping @Sendable (R.State) -> Void) {
        lock.lock()
        defer { lock.unlock() }

        Task {
            await subscribersActor.addSubscriber(subscriber)
            let currentState = await stateActor.state
            subscriber(currentState)
        }
    }

    @MainActor
    public func getEventBus() -> EventBus {
        return eventBus
    }
}

private actor StateActor<State> {
    var state: State

    init(_ initialState: State) {
        self.state = initialState
    }

    func setState(_ newState: State) {
        state = newState
    }
}

private actor CancellablesActor {
    var cancellables: Set<AnyCancellable> = []

    func add(_ cancellable: AnyCancellable) {
        cancellables.insert(cancellable)
    }

    func removeAll() {
        cancellables.removeAll()
    }
}

private actor SubscribersActor<State> {
    var subscribers: [@Sendable (State) -> Void] = []

    func addSubscriber(_ subscriber: @escaping @Sendable (State) -> Void) {
        subscribers.append(subscriber)
    }

    func notifySubscribers(_ state: State) {
        for subscriber in subscribers {
            subscriber(state)
        }
    }
}

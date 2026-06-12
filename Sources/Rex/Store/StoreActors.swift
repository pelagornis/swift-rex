import Foundation

actor StateActor<State> {
    var state: State

    init(_ initialState: State) {
        self.state = initialState
    }

    func setState(_ newState: State) {
        state = newState
    }
}

actor SubscribersActor<State> {
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

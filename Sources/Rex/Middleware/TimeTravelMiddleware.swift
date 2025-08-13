import Foundation

public actor TimeTravelState<State: StateType & Codable> {
    var history: [State] = []
    var currentIndex: Int = -1
}

extension TimeTravelState {
    func modifyHistory(_ newState: State) {
        if currentIndex < history.count - 1 {
            history = Array(history.prefix(currentIndex + 1))
        }
        history.append(newState)
        currentIndex += 1
    }

    func jumpTo(_ idx: Int) -> State? {
        guard idx >= 0 && idx < history.count else { return nil }
        currentIndex = idx
        return history[idx]
    }

    func undo() -> State? {
        guard currentIndex > 0 else { return nil }
        currentIndex -= 1
        return history[currentIndex]
    }

    func redo() -> State? {
        guard currentIndex < history.count - 1 else { return nil }
        currentIndex += 1
        return history[currentIndex]
    }
}

public final class TimeTravelMiddleware<State: StateType & Codable, Action: ActionType>: Middleware {
    private let state = TimeTravelState<State>()

    public init() {}
    
    public func process(state: State, action: Action, emit: @escaping (Action) -> Void) async -> [Effect<Action>] {
        []
    }

    public func record(_ newState: State) async {
        await state.modifyHistory(newState)
    }

    public func jumpTo(_ idx: Int) async -> State? {
        await state.jumpTo(idx)
    }

    public func undo() async -> State? {
        await state.undo()
    }

    public func redo() async -> State? {
        await state.redo()
    }
}

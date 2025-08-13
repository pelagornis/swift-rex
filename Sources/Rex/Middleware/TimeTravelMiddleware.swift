import Foundation

public actor TimeTravelState<S: State & Codable> {
    var history: [S] = []
    var currentIndex: Int = -1
}

extension TimeTravelState {
    func modifyHistory(_ newState: S) {
        if currentIndex < history.count - 1 {
            history = Array(history.prefix(currentIndex + 1))
        }
        history.append(newState)
        currentIndex += 1
    }

    func jumpTo(_ idx: Int) -> S? {
        guard idx >= 0 && idx < history.count else { return nil }
        currentIndex = idx
        return history[idx]
    }

    func undo() -> S? {
        guard currentIndex > 0 else { return nil }
        currentIndex -= 1
        return history[currentIndex]
    }

    func redo() -> S? {
        guard currentIndex < history.count - 1 else { return nil }
        currentIndex += 1
        return history[currentIndex]
    }
}

public final class TimeTravelMiddleware<S: State & Codable, A: Action>: Middleware {
    private let state = TimeTravelState<S>()

    public init() {}
    
    public func process(state: S, action: A, emit: @escaping (A) -> Void) async -> [Effect<A>] {
        []
    }

    public func record(_ newState: S) async {
        await state.modifyHistory(newState)
    }

    public func jumpTo(_ idx: Int) async -> S? {
        await state.jumpTo(idx)
    }

    public func undo() async -> S? {
        await state.undo()
    }

    public func redo() async -> S? {
        await state.redo()
    }
}

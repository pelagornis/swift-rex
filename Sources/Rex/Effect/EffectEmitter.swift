import Foundation

public struct EffectEmitter<Action>: Sendable {
    private let dispatch: @Sendable (Action) -> Void

    init(dispatch: @escaping @Sendable (Action) -> Void) {
        self.dispatch = dispatch
    }

    public func send(_ action: Action) {
        dispatch(action)
    }

    public func withValue(_ operation: @Sendable (EffectEmitter<Action>) async -> Void) async {
        await operation(self)
    }
}

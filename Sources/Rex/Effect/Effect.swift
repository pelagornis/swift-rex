import Foundation

public struct Effect<Action: ActionType>: Sendable {
    private let operation: @Sendable (EffectEmitter<Action>) async -> Void

    public init(_ operation: @escaping @Sendable (EffectEmitter<Action>) async -> Void) {
        self.operation = operation
    }

    public func run(dispatch: @escaping @Sendable (Action) -> Void) async {
        let emitter = EffectEmitter(dispatch: dispatch)
        await operation(emitter)
    }
}

public extension Effect {
    static var none: Effect<Action> {
        Effect { _ in }
    }
}

import Foundation

public struct Effect<Action: ActionType>: Sendable {
    public let run: @Sendable (ActorIsolated<EffectEmitter<Action>>) async -> Void

    public init(_ run: @escaping @Sendable (ActorIsolated<EffectEmitter<Action>>) async -> Void) {
        self.run = run
    }

    public static var none: Effect {
        Effect { _ in }
    }
}

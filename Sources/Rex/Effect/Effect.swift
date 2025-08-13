import Foundation

public struct Effect<A: Action>: Sendable {
    public let run: @Sendable (ActorIsolated<EffectEmitter<A>>) async -> Void

    public init(_ run: @escaping @Sendable (ActorIsolated<EffectEmitter<A>>) async -> Void) {
        self.run = run
    }

    public static var none: Effect {
        Effect { _ in }
    }
}

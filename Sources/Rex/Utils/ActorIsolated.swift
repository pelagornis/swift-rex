import Foundation

public final class ActorIsolated<Value: Sendable>: Sendable {
    private let actor: _Actor<Value>

    public init(value: Value) {
        actor = _Actor(value)
    }

    public func withValue<T: Sendable>(_ work: @Sendable (Value) async throws -> T) async rethrows -> T {
        try await actor.withValue(work)
    }
}

private actor _Actor<Value: Sendable> {
    var value: Value

    init(_ value: Value) {
        self.value = value
    }

    func withValue<T: Sendable>(_ work: @Sendable (Value) async throws -> T) async rethrows -> T {
        try await work(value)
    }
}

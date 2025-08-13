import Foundation

public protocol Middleware: Sendable {
    associatedtype S: State
    associatedtype A: Action

    func process(state: S, action: A, emit: @escaping (A) -> Void) async -> [Effect<A>]
}

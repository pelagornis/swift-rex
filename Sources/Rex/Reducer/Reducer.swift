import Foundation

public protocol Reducer {
    associatedtype S: State
    associatedtype A: Action

    func reduce(state: inout S, action: A) -> [Effect<A>]
}

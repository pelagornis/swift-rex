import Foundation

@resultBuilder
public struct ReducerBuilder<S: State, A: Action> {
    public static func buildBlock(_ parts: ((inout S, A) -> [Effect<A>])...) -> (inout S, A) -> [Effect<A>] {
        { state, action in
            for part in parts {
                let effects = part(&state, action)
                if !effects.isEmpty { return effects }
            }
            return []
        }
    }

    public static func buildIf(_ component: ((inout S, A) -> [Effect<A>])?) -> ((inout S, A) -> [Effect<A>]) {
        component ?? { _, _ in [] }
    }

    public static func buildEither(first: @escaping (inout S, A) -> [Effect<A>]) -> (inout S, A) -> [Effect<A>] {
        first
    }

    public static func buildEither(second: @escaping (inout S, A) -> [Effect<A>]) -> (inout S, A) -> [Effect<A>] {
        second
    }

    public static func buildArray(_ components: [((inout S, A) -> [Effect<A>])]) -> (inout S, A) -> [Effect<A>] {
        { state, action in
            for part in components {
                let effects = part(&state, action)
                if !effects.isEmpty { return effects }
            }
            return []
        }
    }
}

import Foundation

@resultBuilder
public struct ReducerBuilder<State: StateType, Action: ActionType> {
    public static func buildBlock(_ parts: ((inout State, Action) -> [Effect<Action>])...) -> (inout State, Action) -> [Effect<Action>] {
        { state, action in
            for part in parts {
                let effects = part(&state, action)
                if !effects.isEmpty { return effects }
            }
            return []
        }
    }

    public static func buildIf(_ component: ((inout State, Action) -> [Effect<Action>])?) -> ((inout State, Action) -> [Effect<Action>]) {
        component ?? { _, _ in [] }
    }

    public static func buildEither(first: @escaping (inout State, Action) -> [Effect<Action>]) -> (inout State, Action) -> [Effect<Action>] {
        first
    }

    public static func buildEither(second: @escaping (inout State, Action) -> [Effect<Action>]) -> (inout State, Action) -> [Effect<Action>] {
        second
    }

    public static func buildArray(_ components: [((inout State, Action) -> [Effect<Action>])]) -> (inout State, Action) -> [Effect<Action>] {
        { state, action in
            for part in components {
                let effects = part(&state, action)
                if !effects.isEmpty { return effects }
            }
            return []
        }
    }
}

import Foundation

/// A reducer that handles ``GraphAction`` and mutates ``StateGraph`` on conforming state.
public struct GraphNavigationReducer<State: GraphStateContainer>: Reducer {
    public init() {}

    public func reduce(state: inout State, action: GraphAction) -> [Effect<GraphAction>] {
        switch action {
        case .push(let id, let parent, let dependency):
            state.graph.push(id, from: parent, dependency: dependency)
            return []

        case .pop:
            _ = state.graph.pop()
            return []

        case .popTo(let id):
            _ = state.graph.popTo(id)
            return []

        case .popToRoot:
            _ = state.graph.popToRoot()
            return []
        }
    }
}

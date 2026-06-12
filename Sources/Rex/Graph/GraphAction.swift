import Foundation

/// Navigation actions that mutate ``StateGraph``.
public enum GraphAction: Actionable, Equatable {
    case push(GraphNodeID, parent: GraphNodeID? = nil, dependency: String? = nil)
    case pop
    case popTo(GraphNodeID)
    case popToRoot
}

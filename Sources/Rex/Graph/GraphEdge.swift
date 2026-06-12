import Foundation

/// The kind of relationship between graph nodes.
public enum GraphEdgeKind: Sendable, Codable, Equatable {
    /// Navigation relationship (push / pop).
    case navigation
    /// Dependency injection edge from parent to child.
    case dependency(String)
}

/// A directed edge in a ``StateGraph``.
public struct GraphEdge: Sendable, Codable, Equatable {
    public let to: GraphNodeID
    public let kind: GraphEdgeKind

    public init(to: GraphNodeID, kind: GraphEdgeKind) {
        self.to = to
        self.kind = kind
    }

    public static func navigation(to id: GraphNodeID) -> GraphEdge {
        GraphEdge(to: id, kind: .navigation)
    }

    public static func dependency(_ key: String, to id: GraphNodeID) -> GraphEdge {
        GraphEdge(to: id, kind: .dependency(key))
    }
}

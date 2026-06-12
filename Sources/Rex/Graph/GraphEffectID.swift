import Foundation

/// Builds effect IDs scoped to a graph node for lifecycle-aware cancellation.
public enum GraphEffectID {
    public static func scoped(node: GraphNodeID, name: String = "default") -> EffectID {
        EffectID("graph:\(node.rawValue):\(name)")
    }

    public static func prefix(for node: GraphNodeID) -> String {
        "graph:\(node.rawValue):"
    }
}

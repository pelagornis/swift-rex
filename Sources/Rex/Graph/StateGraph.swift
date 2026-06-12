import Foundation

/// Metadata for a single node in the graph topology.
public struct GraphNodeMetadata: Statable, Equatable, Codable {
    public var parentID: GraphNodeID?
    public var children: [GraphEdge]
    public var isMounted: Bool

    public init(
        parentID: GraphNodeID? = nil,
        children: [GraphEdge] = [],
        isMounted: Bool = false
    ) {
        self.parentID = parentID
        self.children = children
        self.isMounted = isMounted
    }
}

/// A tree-shaped state graph that models navigation paths and feature dependencies.
///
/// Feature state lives in the parent ``GraphStateContainer``; the graph tracks topology and lifecycle.
public struct StateGraph: Statable, Equatable, Codable {
    public var rootID: GraphNodeID
    public var activePath: [GraphNodeID]
    public var nodes: [GraphNodeID: GraphNodeMetadata]

    public init(
        rootID: GraphNodeID = "root",
        activePath: [GraphNodeID]? = nil,
        nodes: [GraphNodeID: GraphNodeMetadata]? = nil
    ) {
        self.rootID = rootID
        self.activePath = activePath ?? [rootID]
        if let nodes {
            self.nodes = nodes
        } else {
            self.nodes = [
                rootID: GraphNodeMetadata(parentID: nil, children: [], isMounted: true)
            ]
        }
    }

    /// Node IDs that are currently mounted (lifecycle active).
    public var mounted: Set<GraphNodeID> {
        Set(nodes.filter(\.value.isMounted).map(\.key))
    }

    /// The node at the top of the navigation stack.
    public var activeNodeID: GraphNodeID? {
        activePath.last
    }

    /// Pushes a child node onto the navigation stack and mounts it.
    @discardableResult
    public mutating func push(
        _ id: GraphNodeID,
        from parent: GraphNodeID? = nil,
        dependency: String? = nil
    ) -> Bool {
        let parentID = parent ?? activeNodeID ?? rootID
        guard nodes[parentID] != nil else { return false }

        var edgeKind: GraphEdgeKind = .navigation
        if let dependency {
            edgeKind = .dependency(dependency)
        }

        if nodes[id] == nil {
            nodes[id] = GraphNodeMetadata(parentID: parentID, children: [], isMounted: true)
        } else {
            nodes[id]?.parentID = parentID
            nodes[id]?.isMounted = true
        }

        let edge = GraphEdge(to: id, kind: edgeKind)
        if !nodes[parentID]!.children.contains(edge) {
            nodes[parentID]?.children.append(edge)
        }

        if activePath.last != id {
            activePath.append(id)
        }
        return true
    }

    /// Pops the top navigation node and unmounts it.
    @discardableResult
    public mutating func pop() -> GraphNodeID? {
        guard activePath.count > 1 else { return nil }
        let removed = activePath.removeLast()
        unmount(removed)
        return removed
    }

    /// Pops until the given node is active.
    @discardableResult
    public mutating func popTo(_ id: GraphNodeID) -> [GraphNodeID] {
        var removed: [GraphNodeID] = []
        while activePath.count > 1, activePath.last != id {
            if let popped = pop() {
                removed.append(popped)
            }
        }
        return removed
    }

    /// Pops to the root node.
    @discardableResult
    public mutating func popToRoot() -> [GraphNodeID] {
        popTo(rootID)
    }

    /// Marks a node as unmounted without removing topology (for lifecycle cleanup).
    public mutating func unmount(_ id: GraphNodeID) {
        guard id != rootID else { return }
        nodes[id]?.isMounted = false
    }

    /// Returns direct child node IDs for a parent.
    public func children(of parent: GraphNodeID) -> [GraphNodeID] {
        nodes[parent]?.children.map(\.to) ?? []
    }

    /// Returns dependency edges from parent to children.
    public func dependencies(from parent: GraphNodeID) -> [(key: String, node: GraphNodeID)] {
        nodes[parent]?.children.compactMap { edge in
            if case .dependency(let key) = edge.kind {
                return (key, edge.to)
            }
            return nil
        } ?? []
    }
}

/// State that embeds a ``StateGraph`` for navigation and feature lifecycle.
public protocol GraphStateContainer: Statable {
    var graph: StateGraph { get set }
}

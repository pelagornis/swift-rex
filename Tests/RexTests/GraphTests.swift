import XCTest
import Rex
import RexTesting

// MARK: - Graph Test Models

struct SettingsState: Statable {
    var value: String = ""
}

enum SettingsAction: Actionable, Equatable {
    case set(String)
}

struct GraphAppState: Statable, GraphStateContainer {
    var graph: StateGraph = StateGraph()
    var rootCount: Int = 0
    var settings: SettingsState = SettingsState()
}

enum GraphAppAction: Actionable, Equatable {
    case graph(GraphAction)
    case rootIncrement
    case settings(SettingsAction)
}

struct GraphAppReducer: Reducer {
    private let navigation = GraphNavigationReducer<GraphAppState>()
    private let settings = ScopeReducer(
        SettingsReducer(),
        state: \GraphAppState.settings,
        action: { GraphAppAction.settings($0) },
        extract: {
            if case .settings(let action) = $0 { return action }
            return nil
        }
    )

    func reduce(state: inout GraphAppState, action: GraphAppAction) -> [Effect<GraphAppAction>] {
        switch action {
        case .graph(let graphAction):
            _ = navigation.reduce(state: &state, action: graphAction)
            return []

        case .rootIncrement:
            state.rootCount += 1
            return []

        case .settings:
            return settings.reduce(state: &state, action: action)
        }
    }
}

struct SettingsReducer: Reducer {
    func reduce(state: inout SettingsState, action: SettingsAction) -> [Effect<SettingsAction>] {
        switch action {
        case .set(let value):
            state.value = value
            return []
        }
    }
}

// MARK: - Graph Tests

final class GraphTests: XCTestCase {
    func testStateGraphPushPop() {
        var graph = StateGraph()
        XCTAssertEqual(graph.activePath, ["root"])

        XCTAssertTrue(graph.push("settings"))
        XCTAssertEqual(graph.activePath, ["root", "settings"])
        XCTAssertTrue(graph.mounted.contains("settings"))

        XCTAssertEqual(graph.pop(), "settings")
        XCTAssertEqual(graph.activePath, ["root"])
        XCTAssertFalse(graph.mounted.contains("settings"))
    }

    func testGraphStoreNavigation() async {
        let graphStore = GraphStore(
            initialState: GraphAppState(),
            reducer: GraphAppReducer(),
            embedGraphAction: { .graph($0) }
        )

        graphStore.push("settings")
        try? await Task.sleep(nanoseconds: 50_000_000)

        let state = await graphStore.store.state
        XCTAssertEqual(state.graph.activePath, ["root", "settings"])

        graphStore.pop()
        try? await Task.sleep(nanoseconds: 50_000_000)

        let popped = await graphStore.store.state
        XCTAssertEqual(popped.graph.activePath, ["root"])
    }

    func testGraphLifecycleCancelsNodeEffects() async {
        enum LifecycleAction: Actionable, Equatable {
            case graph(GraphAction)
            case startSettingsStream
            case settingsTick(Int)
        }

        struct LifecycleState: Statable, GraphStateContainer {
            var graph: StateGraph = StateGraph()
            var settingsTick: Int = 0
        }

        struct LifecycleReducer: Reducer {
            private let navigation = GraphNavigationReducer<LifecycleState>()

            func reduce(state: inout LifecycleState, action: LifecycleAction) -> [Effect<LifecycleAction>] {
                switch action {
                case .graph(let graphAction):
                    _ = navigation.reduce(state: &state, action: graphAction)
                    return []

                case .startSettingsStream:
                    return [
                        Effect(id: GraphEffectID.scoped(node: "settings", name: "tick"), cancelInFlight: true) { emitter in
                            for index in 1...50 {
                                try? await Task.sleep(nanoseconds: 20_000_000)
                                emitter.send(.settingsTick(index))
                            }
                        }
                    ]

                case .settingsTick(let value):
                    state.settingsTick = value
                    return []
                }
            }
        }

        let graphStore = GraphStore(
            initialState: LifecycleState(),
            reducer: LifecycleReducer(),
            embedGraphAction: { .graph($0) }
        )

        graphStore.push("settings")
        graphStore.dispatch(.startSettingsStream)
        try? await Task.sleep(nanoseconds: 60_000_000)
        graphStore.pop()
        try? await Task.sleep(nanoseconds: 100_000_000)

        let finalState = await graphStore.store.state
        XCTAssertLessThan(finalState.settingsTick, 50)
    }

    func testScopeReducer() async {
        let testStore = TestStore(
            initialState: GraphAppState(),
            reducer: GraphAppReducer()
        )

        await testStore.send(.settings(.set("hello")))
        var expected = GraphAppState()
        expected.settings.value = "hello"
        testStore.assertState(expected)
    }

    func testDerivedStateMemoization() {
        var derived = DerivedState<GraphAppState, Int> { $0.rootCount * 2 }
        var state = GraphAppState(rootCount: 2)

        XCTAssertEqual(derived.value(from: state), 4)
        XCTAssertEqual(derived.value(from: state), 4)

        state.rootCount = 3
        XCTAssertEqual(derived.value(from: state), 6)
    }
}

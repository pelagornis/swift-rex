import Foundation
import Rex
import XCTest

/// A test harness that drives a ``Store`` and asserts state changes.
public final class TestStore<R: Reducer>: @unchecked Sendable {
    public private(set) var state: R.State
    private let store: Store<R>
    private let timeoutNanoseconds: UInt64

    public init(
        initialState: R.State,
        reducer: R,
        middlewares: @escaping () -> [AnyMiddleware<R.State, R.Action>] = { [] },
        pipelineHooks: @escaping () -> [AnyPipelineHook<R.State, R.Action>] = { [] },
        timeout: TimeInterval = 1.0
    ) {
        self.state = initialState
        self.timeoutNanoseconds = UInt64(timeout * 1_000_000_000)
        self.store = Store(
            initialState: initialState,
            reducer: reducer,
            middlewares: middlewares,
            pipelineHooks: pipelineHooks
        )
        store.subscribe { [weak self] newState in
            self?.state = newState
        }
    }

    /// Dispatches an action and waits until state changes or timeout.
    public func send(
        _ action: R.Action,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let before = state
        store.dispatch(action)
        let updated = await waitForChange(from: before)
        if !updated {
            XCTFail("Timed out waiting for state change after action \(action)", file: file, line: line)
        }
    }

    /// Asserts the current state equals the expected value.
    public func assertState(
        _ expected: R.State,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(state, expected, file: file, line: line)
    }

    /// Returns the underlying store for advanced scenarios.
    public var underlyingStore: Store<R> {
        store
    }

    private func waitForChange(from before: R.State) async -> Bool {
        let steps = max(1, Int(timeoutNanoseconds / 1_000_000))
        for _ in 0..<steps {
            if state != before {
                return true
            }
            let current = await store.state
            if current != before {
                state = current
                return true
            }
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
        return state != before
    }
}

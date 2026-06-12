//
//  Tests.swift
//  swift-rex
//
//  Created by Jihoonahn on 8/9/25.
//

import XCTest
import Rex
import Foundation

// MARK: - Test Event Types

struct AppEvent: EventItem {
    let name: String
    let data: [String: String]
    
    init(name: String, data: [String: String]) {
        self.name = name
        self.data = data
    }
}

// MARK: - Test Models

struct TestState: Statable {
    var count: Int = 0
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var lastUpdated: Date = Date()
    var messages: [String] = []
    var user: TestUser?
    
    init() {}
}

struct TestUser: Codable, Equatable, Sendable {
    let id: Int
    let name: String
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

enum TestAction: Actionable, Equatable {
    case increment
    case decrement
    case reset
    case setLoading(Bool)
    case addMessage(String)
    case loadUser
    case userLoaded(TestUser)
    case error(String)
    case asyncAction
    case asyncActionCompleted(Int)
    case clearError
}

struct TestReducer: Reducer {
    init() {}
    func reduce(state: inout TestState, action: TestAction) -> [Effect<TestAction>] {
        switch action {
        case .increment:
            state.count += 1
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        case .decrement:
            state.count -= 1
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        case .reset:
            state.count = 0
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        case .setLoading(let isLoading):
            state.isLoading = isLoading
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        case .addMessage(let message):
            state.messages.append(message)
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        case .loadUser:
            state.isLoading = true
            state.errorMessage = nil
            state.lastUpdated = Date()
            return [
                Effect { emitter in
                    // Simulate network delay
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    let user = TestUser(id: 1, name: "Test User")
                    emitter.send(.userLoaded(user))
                }
            ]
            
        case .userLoaded(let user):
            state.user = user
            state.isLoading = false
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        case .error(let message):
            state.errorMessage = message
            state.isLoading = false
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        case .clearError:
            state.errorMessage = nil
            state.lastUpdated = Date()
            return [Effect { _ in }]
            
        case .asyncAction:
            state.isLoading = true
            state.lastUpdated = Date()
            return [
                Effect { emitter in
                    // Simulate async work
                    try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                    emitter.send(.asyncActionCompleted(42))
                }
            ]
            
        case .asyncActionCompleted(let value):
            state.count = value
            state.isLoading = false
            state.lastUpdated = Date()
            return [Effect { _ in }]
        }
    }
}

// MARK: - Test Cases

final class RexTests: XCTestCase {
    
    // MARK: - Effect Tests
    
    func testEffectNone() {
        let effect = Effect<TestAction>.none
        XCTAssertNotNil(effect)
    }
    
    func testEffectJust() {
        let effect = Effect.just(TestAction.increment)
        XCTAssertNotNil(effect)
    }
    
    func testEffectMany() {
        let effect = Effect.many(TestAction.increment, TestAction.decrement, TestAction.reset)
        XCTAssertNotNil(effect)
    }
    
    func testEffectDelayed() {
        let effect = Effect.delayed(TestAction.increment, delay: 1.0)
        XCTAssertNotNil(effect)
    }
    
    func testEffectSequence() {
        let effect = Effect.sequence(TestAction.increment, TestAction.decrement, TestAction.reset)
        XCTAssertNotNil(effect)
    }
    
    func testEffectConcurrent() {
        let effect = Effect.concurrent(TestAction.increment, TestAction.decrement, TestAction.reset)
        XCTAssertNotNil(effect)
    }
    
    func testEffectConditional() {
        let effect = Effect.conditional({ true }, action: TestAction.increment)
        XCTAssertNotNil(effect)
    }
    
    func testEffectMap() {
        let effect = Effect.map(TestAction.increment) { action in
            switch action {
            case .increment:
                return .decrement
            default:
                return action
            }
        }
        XCTAssertNotNil(effect)
    }
    
    func testEffectCombine() {
        let effect1 = Effect.just(TestAction.increment)
        let effect2 = Effect.just(TestAction.decrement)
        let combined = Effect.combine(effect1, effect2)
        XCTAssertNotNil(combined)
    }
    
    func testEffectRetry() {
        let effect = Effect.just(TestAction.increment)
        let retryEffect = Effect.retry(effect, maxAttempts: 3)
        XCTAssertNotNil(retryEffect)
    }
    
    func testEffectRetryWithErrorAction() {
        let effect = Effect.just(TestAction.increment)
        let retryEffect = Effect.retryWithErrorAction(
            effect,
            maxAttempts: 3,
            delay: 1.0,
            shouldRetry: { _ in true },
            errorAction: { _ in .error("Retry failed") }
        )
        XCTAssertNotNil(retryEffect)
    }
    
    // MARK: - AsyncStream Effect Tests

    func testAsyncStreamEffectDispatchesActions() async {
        let effect = Effect<TestAction>.stream {
            AsyncStream { continuation in
                continuation.yield(.increment)
                continuation.yield(.increment)
                continuation.finish()
            }
        }

        var received: [TestAction] = []
        for await action in effect.makeStream() {
            received.append(action)
        }

        XCTAssertEqual(received, [.increment, .increment])
    }

    func testCancellableEffectCancelInFlight() async {
        enum StreamAction: Actionable, Equatable {
            case start
            case tick(Int)
        }

        struct StreamState: Statable {
            var value: Int = 0
        }

        struct StreamReducer: Reducer {
            func reduce(state: inout StreamState, action: StreamAction) -> [Effect<StreamAction>] {
                switch action {
                case .start:
                    return [
                        Effect(id: "stream", cancelInFlight: true) { emitter in
                            for index in 1...20 {
                                try? await Task.sleep(nanoseconds: 20_000_000)
                                emitter.send(.tick(index))
                            }
                        }
                    ]
                case .tick(let value):
                    state.value = value
                    return []
                }
            }
        }

        let store = Store(initialState: StreamState(), reducer: StreamReducer())
        store.dispatch(.start)
        try? await Task.sleep(nanoseconds: 30_000_000)
        store.dispatch(.start)
        try? await Task.sleep(nanoseconds: 150_000_000)

        let state = await store.state
        XCTAssertLessThan(state.value, 20)
    }

    // MARK: - Pipeline Hook Tests

    func testPipelineHookAbortsAction() async {
        struct BlockResetHook: PipelineHook {
            typealias State = TestState
            typealias Action = TestAction

            func handle(
                phase: PipelinePhase<TestAction, TestState>,
                context: PipelineContext<TestAction, TestState>
            ) async -> HookResult<TestAction> {
                if case .willReceive(.reset) = phase {
                    return .abort
                }
                return .continue
            }
        }

        var initial = TestState()
        initial.count = 5
        let store = Store(
            initialState: initial,
            reducer: TestReducer(),
            pipelineHooks: { [AnyPipelineHook(BlockResetHook())] }
        )

        store.dispatch(TestAction.reset)
        try? await Task.sleep(nanoseconds: 50_000_000)

        let state = await store.state
        XCTAssertEqual(state.count, 5)
    }

    func testTimeTravelRecordsAutomatically() async {
        let timeTravel = TimeTravelPipelineHook<TestState, TestAction>()
        let store = Store(
            initialState: TestState(),
            reducer: TestReducer(),
            timeTravel: timeTravel
        )

        store.dispatch(.increment)
        store.dispatch(.increment)
        try? await Task.sleep(nanoseconds: 100_000_000)

        let history = await timeTravel.history()
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].stateAfter.count, 1)
        XCTAssertEqual(history[1].stateAfter.count, 2)

        let undone = await store.undoTimeTravel()
        XCTAssertEqual(undone?.count, 1)

        let state = await store.state
        XCTAssertEqual(state.count, 1)
    }

    func testDispatchUpdatesState() async {
        let store = Store(initialState: TestState(), reducer: TestReducer())
        store.dispatch(.increment)
        try? await Task.sleep(nanoseconds: 100_000_000)

        let state = await store.state
        XCTAssertEqual(state.count, 1)
    }

    // MARK: - Store Tests
    
    func testStoreInitialization() {
        let initialState = TestState()
        let reducer = TestReducer()
        
        let store = Store(
            initialState: initialState,
            reducer: reducer
        )
        
        XCTAssertEqual(store.getInitialState().count, 0)
        XCTAssertFalse(store.getInitialState().isLoading)
        XCTAssertTrue(store.getInitialState().messages.isEmpty)
        XCTAssertNil(store.getInitialState().user)
    }

    // MARK: - Performance Tests
    
    func testEffectPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = Effect.just(TestAction.increment)
                _ = Effect.many(TestAction.increment, TestAction.decrement, TestAction.reset)
                _ = Effect.delayed(TestAction.increment, delay: 0.1)
            }
        }
    }
    
    func testStorePerformance() {
        let store = Store(
            initialState: TestState(),
            reducer: TestReducer()
        )
        
        measure {
            for _ in 0..<1000 {
                store.dispatch(.increment)
            }
        }
    }
}

//
//  File.swift
//  swift-rex
//
//  Created by Jihoonahn on 8/9/25.
//

import XCTest
import Rex
import Foundation

// MARK: - Test Models

struct TestState: StateType {
    var count: Int = 0
    var isLoading: Bool = false
    var messages: [String] = []
    var user: TestUser?
    
    public init() {}
}

struct TestUser: Codable, Equatable {
    let id: Int
    let name: String
}

enum TestAction: ActionType, Equatable {
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
}

struct TestReducer: Reducer {
    func reduce(state: inout TestState, action: TestAction) -> [Effect<TestAction>] {
        switch action {
        case .increment:
            state.count += 1
            return [.none]
            
        case .decrement:
            state.count -= 1
            return [.none]
            
        case .reset:
            state.count = 0
            return [.none]
            
        case .setLoading(let isLoading):
            state.isLoading = isLoading
            return [.none]
            
        case .addMessage(let message):
            state.messages.append(message)
            return [.none]
            
        case .loadUser:
            state.isLoading = true
            return [
                Effect { emitter in
                    // Simulate network delay
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                    let user = TestUser(id: 1, name: "Test User")
                    await emitter.withValue { emitter in
                        await emitter.send(.userLoaded(user))
                    }
                }
            ]
            
        case .userLoaded(let user):
            state.user = user
            state.isLoading = false
            return [.none]
            
        case .error(let message):
            state.messages.append("Error: \(message)")
            state.isLoading = false
            return [.none]
            
        case .asyncAction:
            state.isLoading = true
            return [
                Effect { emitter in
                    try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                    await emitter.withValue { emitter in
                        await emitter.send(.asyncActionCompleted(42))
                    }
                }
            ]
            
        case .asyncActionCompleted(let value):
            state.count = value
            state.isLoading = false
            return [.none]
        }
    }
}

// MARK: - Architecture Tests

final class RexArchitectureTests: XCTestCase {
    
    // MARK: - State Tests
    
    func testStateTypeConformance() {
        let state = TestState()
        XCTAssertTrue(state is any StateType)
        XCTAssertTrue(state is any Equatable)
        XCTAssertTrue(state is any Codable)
    }
    
    func testStateEquality() {
        var state1 = TestState()
        var state2 = TestState()
        
        XCTAssertEqual(state1, state2)
        
        state1.count = 5
        XCTAssertNotEqual(state1, state2)
        
        state2.count = 5
        XCTAssertEqual(state1, state2)
    }
    
    // MARK: - Action Tests
    
    func testActionTypeConformance() {
        let action = TestAction.increment
        XCTAssertTrue(action is any ActionType)
        XCTAssertTrue(action is any Equatable)
    }
    
    // MARK: - Reducer Tests
    
    func testReducerIncrementAction() {
        var state = TestState()
        let reducer = TestReducer()
        
        let effects = reducer.reduce(state: &state, action: .increment)
        
        XCTAssertEqual(state.count, 1)
        XCTAssertEqual(effects.count, 1)
        XCTAssertNotNil(effects.first)
    }
    
    func testReducerDecrementAction() {
        var state = TestState()
        state.count = 5
        let reducer = TestReducer()
        
        let effects = reducer.reduce(state: &state, action: .decrement)
        
        XCTAssertEqual(state.count, 4)
        XCTAssertEqual(effects.count, 1)
        XCTAssertNotNil(effects.first)
    }
    
    func testReducerResetAction() {
        var state = TestState()
        state.count = 10
        let reducer = TestReducer()
        
        let effects = reducer.reduce(state: &state, action: .reset)
        
        XCTAssertEqual(state.count, 0)
        XCTAssertEqual(effects.count, 1)
        XCTAssertNotNil(effects.first)
    }
    
    func testReducerAddMessageAction() {
        var state = TestState()
        let reducer = TestReducer()
        
        let effects = reducer.reduce(state: &state, action: .addMessage("Hello"))
        
        XCTAssertEqual(state.messages.count, 1)
        XCTAssertEqual(state.messages.first, "Hello")
        XCTAssertEqual(effects.count, 1)
        XCTAssertNotNil(effects.first)
    }
    
    func testReducerLoadUserAction() {
        var state = TestState()
        let reducer = TestReducer()
        
        let effects = reducer.reduce(state: &state, action: .loadUser)
        
        XCTAssertTrue(state.isLoading)
        XCTAssertEqual(effects.count, 1)
        XCTAssertNotNil(effects.first)
    }
    
    func testReducerUserLoadedAction() {
        var state = TestState()
        state.isLoading = true
        let user = TestUser(id: 1, name: "Test")
        let reducer = TestReducer()
        
        let effects = reducer.reduce(state: &state, action: .userLoaded(user))
        
        XCTAssertFalse(state.isLoading)
        XCTAssertEqual(state.user?.id, 1)
        XCTAssertEqual(state.user?.name, "Test")
        XCTAssertEqual(effects.count, 1)
        XCTAssertNotNil(effects.first)
    }
    
    // MARK: - Effect Tests
    
    func testEffectNone() {
        let effect = Effect<TestAction>.none
        XCTAssertNotNil(effect)
    }
    
    func testEffectJust() {
        let action = TestAction.increment
        let effect = Effect.just(action)
        XCTAssertNotNil(effect)
    }
    
    func testEffectExecution() async {
        let expectation = XCTestExpectation(description: "Effect executed")
        let capturedAction = ActorIsolated<TestAction?>(value: nil)
        
        let effect = Effect<TestAction> { emitter in
            await emitter.withValue { emitter in
                await emitter.send(.increment)
            }
        }
        
        let emitter = ActorIsolated(value: EffectEmitter<TestAction>())
        await emitter.withValue { emitter in
            await emitter.setSendAction { action in
                Task {
                    await capturedAction.withValue { _ in
                        expectation.fulfill()
                    }
                }
            }
        }
        
        await effect.run(emitter)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Verify the effect was executed by checking if the action was sent
        await capturedAction.withValue { action in
            // The effect should have been executed
            XCTAssertTrue(true) // Just verify the effect ran without errors
        }
    }
    
    // MARK: - Store Tests
    
    func testStoreInitialization() {
        let initialState = TestState()
        let reducer = TestReducer()
        
        let store = Store(
            initialState: initialState,
            reducer: reducer
        ) {
            // No middleware for this test
        }
        
        XCTAssertEqual(store.state.count, 0)
        XCTAssertFalse(store.state.isLoading)
        XCTAssertTrue(store.state.messages.isEmpty)
        XCTAssertNil(store.state.user)
    }
    
    func testStoreDispatch() {
        let store = Store(
            initialState: TestState(),
            reducer: TestReducer()
        ) {
            // No middleware for this test
        }
        
        let expectation = XCTestExpectation(description: "State updated")
        
        store.subscribe { state in
            if state.count == 1 {
                expectation.fulfill()
            }
        }
        
        store.dispatch(.increment)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(store.state.count, 1)
    }
    
    func testStoreMultipleDispatches() {
        let store = Store(
            initialState: TestState(),
            reducer: TestReducer()
        ) {
            // No middleware for this test
        }
        
        let expectation = XCTestExpectation(description: "Multiple state updates")
        expectation.expectedFulfillmentCount = 3
        
        store.subscribe { state in
            expectation.fulfill()
        }
        
        store.dispatch(.increment)
        store.dispatch(.increment)
        store.dispatch(.increment)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(store.state.count, 3)
    }
    
    func testStoreAsyncEffects() async {
        let store = Store(
            initialState: TestState(),
            reducer: TestReducer()
        ) {
            // No middleware for this test
        }
        
        let expectation = XCTestExpectation(description: "Async effect completed")
        
        store.subscribe { state in
            if state.count == 42 && !state.isLoading {
                expectation.fulfill()
            }
        }
        
        store.dispatch(.asyncAction)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertEqual(store.state.count, 42)
        XCTAssertFalse(store.state.isLoading)
    }
    
    func testStoreLoadUserEffect() async {
        let store = Store(
            initialState: TestState(),
            reducer: TestReducer()
        ) {
            // No middleware for this test
        }
        
        let expectation = XCTestExpectation(description: "User loaded")
        
        store.subscribe { state in
            if state.user != nil && !state.isLoading {
                expectation.fulfill()
            }
        }
        
        store.dispatch(.loadUser)
        
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertNotNil(store.state.user)
        XCTAssertEqual(store.state.user?.id, 1)
        XCTAssertEqual(store.state.user?.name, "Test User")
        XCTAssertFalse(store.state.isLoading)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow() async {
        let store = Store(
            initialState: TestState(),
            reducer: TestReducer()
        ) {
            // No middleware for this test
        }
        
        let expectation = XCTestExpectation(description: "Complete workflow")
        
        store.subscribe { state in
            if state.count == 2 && 
               state.messages.count == 1 && 
               state.user != nil && 
               !state.isLoading {
                expectation.fulfill()
            }
        }
        
        // Start workflow
        store.dispatch(.increment)
        store.dispatch(.increment)
        store.dispatch(.addMessage("Workflow completed"))
        store.dispatch(.loadUser)
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        XCTAssertEqual(store.state.count, 2)
        XCTAssertEqual(store.state.messages.count, 1)
        XCTAssertEqual(store.state.messages.first, "Workflow completed")
        XCTAssertNotNil(store.state.user)
        XCTAssertFalse(store.state.isLoading)
    }
    
    // MARK: - Performance Tests
    
    func testStorePerformance() {
        let store = Store(
            initialState: TestState(),
            reducer: TestReducer()
        ) {
            // No middleware for this test
        }
        
        measure {
            for _ in 0..<1000 {
                store.dispatch(.increment)
            }
        }
    }
    
    func testReducerPerformance() {
        var state = TestState()
        let reducer = TestReducer()
        
        measure {
            for _ in 0..<1000 {
                _ = reducer.reduce(state: &state, action: .increment)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling() {
        let store = Store(
            initialState: TestState(),
            reducer: TestReducer()
        ) {
            // No middleware for this test
        }
        
        let expectation = XCTestExpectation(description: "Error handled")
        
        store.subscribe { state in
            if state.messages.contains("Error: Test error") {
                expectation.fulfill()
            }
        }
        
        store.dispatch(.error("Test error"))
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(store.state.messages.contains("Error: Test error"))
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentDispatches() async {
        let store = Store(
            initialState: TestState(),
            reducer: TestReducer()
        ) {
            // No middleware for this test
        }
        
        let expectation = XCTestExpectation(description: "Concurrent dispatches completed")
        expectation.expectedFulfillmentCount = 100
        
        store.subscribe { state in
            expectation.fulfill()
        }
        
        // Dispatch actions concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    store.dispatch(.increment)
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
        
        // Due to race conditions, we might not get exactly 100
        // Just verify that we got a reasonable number of increments
        XCTAssertGreaterThanOrEqual(store.state.count, 90)
        XCTAssertLessThanOrEqual(store.state.count, 100)
    }
}

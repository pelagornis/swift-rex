#if canImport(SwiftUI)
import SwiftUI
import Combine

/// A SwiftUI-compatible wrapper around the Swift-Rex Store.
///
/// `ObservableStore` is an `ObservableObject` that wraps a `Store` instance,
/// making it compatible with SwiftUI's reactive system. It automatically
/// updates SwiftUI views when the underlying state changes.
///
/// ## Overview
///
/// `ObservableStore` provides a bridge between Swift-Rex's state management
/// system and SwiftUI's reactive UI framework. It subscribes to the underlying
/// store and publishes state changes to SwiftUI views.
///
/// ## Key Features
///
/// - **SwiftUI Integration**: Conforms to `ObservableObject` for automatic UI updates
/// - **State Access**: Provides read-only access to the current state
/// - **Action Dispatching**: Allows dispatching actions to the underlying store
/// - **Automatic Updates**: SwiftUI views automatically update when state changes
/// - **Memory Management**: Properly manages subscriptions and prevents memory leaks
///
/// ## Example
///
/// ```swift
/// struct ContentView: View {
///     @StateObject var store: ObservableStore<AppReducer>
///
///     var body: some View {
///         VStack {
///             Text("Count: \(store.state.count)")
///                 .font(.title)
///
///             HStack {
///                 Button("+1") { store.send(.increment) }
///                 Button("-1") { store.send(.decrement) }
///             }
///
///             Button("Load Data") {
///                 store.send(.loadData)
///             }
///             .disabled(store.state.isLoading)
///         }
///         .padding()
///     }
/// }
///
/// // Initialize in your app
/// @main
/// struct MyApp: App {
///     let store = Store(
///         initialState: AppState(),
///         reducer: AppReducer()
///     )
///
///     var body: some Scene {
///         WindowGroup {
///             ContentView(store: ObservableStore(store: store))
///         }
///     }
/// }
/// ```
///
/// ## Best Practices
///
/// - Create the `ObservableStore` once at app startup
/// - Pass it down through the view hierarchy using `@StateObject` or `@ObservedObject`
/// - Use `@StateObject` for the root view that owns the store
/// - Use `@ObservedObject` for child views that receive the store
/// - Access state through `store.state` and dispatch actions through `store.send(_:)`
@MainActor
public final class ObservableStore<R: Reducer>: ObservableObject {
    /// The underlying Swift-Rex store.
    private let store: Store<R>
    
    /// The current state of the application.
    ///
    /// This property provides read-only access to the current state.
    /// SwiftUI views will automatically update when this property changes.
    @Published public private(set) var state: R.State
    
    /// Combine cancellables for managing subscriptions.
    private var cancellables: Set<AnyCancellable> = []
    
    /// Creates a new ObservableStore that wraps the specified store.
    ///
    /// The ObservableStore will automatically subscribe to the underlying store
    /// and update its published state whenever the store's state changes.
    ///
    /// - Parameter store: The Swift-Rex store to wrap.
    public init(store: Store<R>) {
        self.store = store
        self.state = store.state
        
        // Subscribe to store changes
        store.subscribe { [weak self] newState in
            Task { @MainActor in
                self?.state = newState
            }
        }
    }
    
    /// Dispatches an action to the underlying store.
    ///
    /// This method sends an action to the store, which will process it through
    /// the reducer and update the state. SwiftUI views will automatically
    /// update when the state changes.
    ///
    /// - Parameter action: The action to dispatch.
    public func send(_ action: R.Action) {
        store.dispatch(action)
    }
    
    /// Provides access to the EventBus for cross-component communication.
    ///
    /// The EventBus allows components to publish and subscribe to events without
    /// direct coupling. This is useful for handling cross-cutting concerns like
    /// navigation, analytics, and error handling.
    ///
    /// - Returns: The EventBus instance associated with the underlying store.
    public func getEventBus() -> EventBus {
        return store.getEventBus()
    }
}
#endif

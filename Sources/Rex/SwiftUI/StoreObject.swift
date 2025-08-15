#if canImport(SwiftUI)
import SwiftUI
import Combine

/// A property wrapper that provides access to a Swift-Rex store in SwiftUI views.
///
/// `@StoreObject` is a property wrapper that allows SwiftUI views to access
/// a Swift-Rex store through the environment. It provides a convenient way
/// to inject stores into the view hierarchy without prop drilling.
///
/// ## Overview
///
/// `@StoreObject` works similarly to `@EnvironmentObject` but is specifically
/// designed for Swift-Rex stores. It allows views to access the store from
/// anywhere in the view hierarchy without explicitly passing it down.
///
/// ## Key Features
///
/// - **Environment Integration**: Access stores through SwiftUI's environment system
/// - **Type Safety**: Provides compile-time type checking for store access
/// - **Automatic Updates**: Views automatically update when store state changes
/// - **Convenient Access**: No need to pass stores explicitly through view parameters
/// - **Memory Management**: Properly manages store lifecycle and subscriptions
///
/// ## Example
///
/// ```swift
/// struct ContentView: View {
///     @StoreObject var store: ObservableStore<AppReducer>
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
///         }
///         .padding()
///     }
/// }
///
/// struct ChildView: View {
///     @StoreObject var store: ObservableStore<AppReducer>
///
///     var body: some View {
///         Button("Reset") {
///             store.send(.reset)
///         }
///     }
/// }
///
/// // Set up the environment
/// @main
/// struct MyApp: App {
///     let store = Store(
///         initialState: AppState(),
///         reducer: AppReducer()
///     )
///
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .storeObject(ObservableStore(store: store))
///         }
///     }
/// }
/// ```
///
/// ## Best Practices
///
/// - Use `@StoreObject` when you need to access the store in multiple views
/// - Set up the store in the environment at the root of your app
/// - Use `@StateObject` for the view that owns the store
/// - Use `@StoreObject` for child views that need store access
/// - Consider using explicit store injection for better testability
@propertyWrapper
public struct StoreObject<R: Reducer>: DynamicProperty {
    /// The environment value that provides access to the store.
    @Environment(StoreEnvironmentKey<R>.self) private var store: ObservableStore<R>
    
    /// Creates a new StoreObject property wrapper.
    public init() {}
    
    /// The wrapped value that provides access to the store.
    public var wrappedValue: ObservableStore<R> {
        store
    }
}

/// A view modifier that injects a store into the SwiftUI environment.
///
/// This modifier allows you to inject a Swift-Rex store into the SwiftUI
/// environment, making it available to all child views through `@StoreObject`.
///
/// ## Example
///
/// ```swift
/// ContentView()
///     .storeObject(ObservableStore(store: myStore))
/// ```
public extension View {
    /// Injects a store into the SwiftUI environment.
    ///
    /// This modifier makes the specified store available to all child views
    /// through the `@StoreObject` property wrapper.
    ///
    /// - Parameter store: The ObservableStore to inject into the environment.
    /// - Returns: A view with the store injected into its environment.
    func storeObject<R: Reducer>(_ store: ObservableStore<R>) -> some View {
        environment(StoreEnvironmentKey<R>.self, store)
    }
}

/// An environment key for storing Swift-Rex stores in the SwiftUI environment.
///
/// This type provides the infrastructure for storing and retrieving Swift-Rex
/// stores from the SwiftUI environment system.
private struct StoreEnvironmentKey<R: Reducer>: EnvironmentKey {
    /// The default value for this environment key.
    ///
    /// This will be used if no store is explicitly provided in the environment.
    static let defaultValue: ObservableStore<R> = ObservableStore(
        store: Store(
            initialState: R.State(),
            reducer: R()
        )
    )
}
#endif

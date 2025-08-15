import Foundation

/// A protocol that defines the requirements for application state.
///
/// The `StateType` protocol is the foundation of Swift-Rex's state management system.
/// It provides default implementations for common state properties like loading states,
/// error handling, and timestamps.
///
/// ## Overview
///
/// All application state should conform to `StateType`. This protocol ensures
/// consistency across your app's state management and provides useful default
/// implementations for common patterns.
///
/// ## Default Properties
///
/// The protocol provides default implementations for:
/// - `isLoading`: Boolean flag for loading states
/// - `errorMessage`: Optional string for error messages
/// - `lastUpdated`: Timestamp of the last state update
///
/// ## Example
///
/// ```swift
/// struct AppState: StateType {
///     var count: Int = 0
///     var user: User?
///     var theme: Theme = .light
///     
///     // Default properties are automatically available:
///     // - isLoading: Bool
///     // - errorMessage: String?
///     // - lastUpdated: Date
/// }
/// ```
///
/// ## Conformance Requirements
///
/// Your state type must be a struct that can be mutated. The protocol
/// automatically provides the required properties with sensible defaults.
public protocol StateType {
    /// A boolean flag indicating whether the state is currently in a loading state.
    ///
    /// This property is useful for showing loading indicators, disabling UI elements,
    /// or preventing user interactions during async operations.
    var isLoading: Bool { get set }
    
    /// An optional string containing the current error message.
    ///
    /// Use this property to display error messages to users or handle error states
    /// in your UI. Set to `nil` when there are no errors.
    var errorMessage: String? { get set }
    
    /// A timestamp indicating when the state was last updated.
    ///
    /// This property is automatically updated whenever the state changes through
    /// the reducer. Useful for debugging, caching, or displaying "last updated"
    /// information to users.
    var lastUpdated: Date { get set }
}

/// Default implementation of `StateType` properties.
///
/// This extension provides sensible default values for the required properties
/// of the `StateType` protocol. You can override these defaults in your own
/// state implementations if needed.
public extension StateType {
    /// Default value for `isLoading` is `false`.
    var isLoading: Bool {
        get { false }
        set { }
    }
    
    /// Default value for `errorMessage` is `nil`.
    var errorMessage: String? {
        get { nil }
        set { }
    }
    
    /// Default value for `lastUpdated` is the current date.
    var lastUpdated: Date {
        get { Date() }
        set { }
    }
}

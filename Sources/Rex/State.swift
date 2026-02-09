import Foundation

/// A protocol that defines the common properties for application state.
///
/// Conforming types should include standard state properties like loading status,
/// error messages, and last updated timestamp. This protocol ensures consistency
/// across different state types in your application.
///
/// ## Example
/// ```swift
/// struct AppState: State {
///     var count: Int = 0
///     var isLoading: Bool = false
///     var errorMessage: String? = nil
///     var lastUpdated: Date = Date()
/// }
/// ```
public protocol StateProtocol: Sendable, Equatable, Codable {}
/// Public typealias so app types conform to ``State`` (e.g. `struct AppState: State`).
public typealias State = StateProtocol

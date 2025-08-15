import Foundation

public protocol StateType: Sendable, Equatable, Codable {
    init()
}

public extension StateType {
    init() {
        self = Self()
    }
}

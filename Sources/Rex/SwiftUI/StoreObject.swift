#if canImport(SwiftUI)
import SwiftUI
import Combine

@propertyWrapper
@MainActor
public struct StoreObject<ObjectType>: DynamicProperty where ObjectType: ObservableObject {
    @StateObject private var observedObject: ObjectType

    public var wrappedValue: ObjectType {
        observedObject
    }

    public var projectedValue: ObservedObject<ObjectType>.Wrapper {
        ObservedObject<ObjectType>(wrappedValue: observedObject).projectedValue
    }

    public init(wrappedValue: @autoclosure @escaping () -> ObjectType) {
        _observedObject = StateObject(wrappedValue: wrappedValue())
    }
}
#endif
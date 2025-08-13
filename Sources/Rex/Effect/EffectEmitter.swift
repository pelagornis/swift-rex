import Foundation

public actor EffectEmitter<A: Action> {
    private var sendAction: ((A) -> Void)?

    public init() {}

    public func send(_ action: A) {
        sendAction?(action)
    }

    public func setSendAction(_ sendAction: @escaping (A) -> Void) {
        self.sendAction = sendAction
    }
}

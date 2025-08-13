import Foundation

public actor EffectEmitter<Action: ActionType> {
    private var sendAction: ((Action) -> Void)?

    public init() {}

    public func send(_ action: Action) {
        sendAction?(action)
    }

    public func setSendAction(_ sendAction: @escaping (Action) -> Void) {
        self.sendAction = sendAction
    }
}

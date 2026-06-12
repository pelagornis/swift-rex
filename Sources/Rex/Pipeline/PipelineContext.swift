import Foundation

/// Mutable context shared across pipeline hooks for a single action dispatch.
public struct PipelineContext<Action: Actionable, State: Statable>: @unchecked Sendable {
  public var action: Action
  public let stateBefore: State
  public var stateAfter: State?
  public var effects: [Effect<Action>]
  public let dispatch: (@Sendable (Action) -> Void)?

  public init(
    action: Action,
    stateBefore: State,
    stateAfter: State? = nil,
    effects: [Effect<Action>] = [],
    dispatch: (@Sendable (Action) -> Void)? = nil
  ) {
    self.action = action
    self.stateBefore = stateBefore
    self.stateAfter = stateAfter
    self.effects = effects
    self.dispatch = dispatch
  }
}

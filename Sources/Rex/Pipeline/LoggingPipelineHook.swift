import Foundation

/// Logs every pipeline phase for debugging and analytics.
public struct LoggingPipelineHook<State: Statable, Action: Actionable>: PipelineHook {
  private let label: String
  private let log: @Sendable (String) -> Void

  public init(
    label: String = "Rex",
    log: @escaping @Sendable (String) -> Void = { print($0) }
  ) {
    self.label = label
    self.log = log
  }

  public func handle(
    phase: PipelinePhase<Action, State>,
    context: PipelineContext<Action, State>
  ) async -> HookResult<Action> {
    switch phase {
    case .willReceive(let action):
      log("[\(label)] willReceive: \(action)")

    case .willReduce(let action, _):
      log("[\(label)] willReduce: \(action)")

    case .didReduce(let action, let before, let after):
      log("[\(label)] didReduce: \(action)")
      log("[\(label)]   before: \(before)")
      log("[\(label)]   after:  \(after)")

    case .willRunEffects(let action, let count):
      log("[\(label)] willRunEffects: \(action) (\(count) effects)")

    case .didRunEffects(let action):
      log("[\(label)] didRunEffects: \(action)")

    case .didComplete(let action):
      log("[\(label)] didComplete: \(action)")
    }

    return .continue
  }
}

import Foundation

/// Phases emitted while an action travels through the store pipeline.
public enum PipelinePhase<Action: Actionable, State: Statable>: Sendable {
  case willReceive(Action)
  case willReduce(Action, State)
  case didReduce(Action, before: State, after: State)
  case willRunEffects(Action, effectCount: Int)
  case didRunEffects(Action)
  case didComplete(Action)
}

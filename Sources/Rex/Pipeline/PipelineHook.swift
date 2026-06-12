import Foundation

/// Observes and optionally transforms actions as they move through the pipeline.
public protocol PipelineHook: Sendable {
  associatedtype State: Statable
  associatedtype Action: Actionable

  func handle(
    phase: PipelinePhase<Action, State>,
    context: PipelineContext<Action, State>
  ) async -> HookResult<Action>
}

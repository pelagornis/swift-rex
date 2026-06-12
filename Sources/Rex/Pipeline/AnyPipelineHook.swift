import Foundation

public struct AnyPipelineHook<State: Statable, Action: Actionable>: PipelineHook, Sendable {
  private let _handle: @Sendable (
    PipelinePhase<Action, State>,
    PipelineContext<Action, State>
  ) async -> HookResult<Action>

  public init<H: PipelineHook>(_ hook: H) where H.State == State, H.Action == Action {
    _handle = { phase, context in
      await hook.handle(phase: phase, context: context)
    }
  }

  public func handle(
    phase: PipelinePhase<Action, State>,
    context: PipelineContext<Action, State>
  ) async -> HookResult<Action> {
    await _handle(phase, context)
  }
}

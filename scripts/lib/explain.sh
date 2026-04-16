#!/bin/bash
# scripts/lib/explain.sh — side-effect-free explanation path for `cheer --why`
#
# Requires: config.sh, state.sh, context.sh, policy.sh, render.sh, catalog.sh
# sourced before calling explain_run.
#
# explain_run <payload>
#   Accepts a JSON hook payload string (or empty for the default probe).
#   Prints a human-readable explanation of what cheerer would do and why.
#   NO mutations: does not write cooldown, history, stats, or any file.

# Default probe used when payload is empty — a short TaskCompleted
_EXPLAIN_DEFAULT_HOOK_EVENT="TaskCompleted"
_EXPLAIN_DEFAULT_DURATION=12

explain_reset() {
  EXPLAIN_ENABLED=true
  EXPLAIN_REASONING=""
}

explain_run() {
  local payload="${1:-}"

  explain_reset

  local _hook_event _duration
  if [[ -z "$payload" ]]; then
    _hook_event="$_EXPLAIN_DEFAULT_HOOK_EVENT"
    _duration="$_EXPLAIN_DEFAULT_DURATION"
  else
    context_reset
    context_parse_hook_payload "$payload"
    _hook_event="$CTX_HOOK_EVENT"
    _duration="$CTX_TASK_DURATION"
  fi

  export HOOK_EVENT="$_hook_event"
  export TASK_DURATION="$_duration"
  RECENT_TASKCOMPLETED_COUNT=0
  SESSION_STREAK=0
  RECENT_ANIMATIONS=""
  RECENT_MESSAGE_IDS=""
  STATE_MILESTONE_MSG=""

  policy_select_celebration
  render_select_message

  printf '\n  cheerer — Why\n\n'
  printf '  Hook event: %s\n' "${HOOK_EVENT:-unknown}"
  printf '  Duration: %s\n' "${TASK_DURATION:-0}"
  printf '\n  Decision:\n'
  printf '  - tier: %s\n' "${POLICY_TIER:-}"
  printf '  - mood: %s\n' "${POLICY_MOOD:-}"
  printf '  - animation: %s\n' "${POLICY_ANIMATION:-}"
  printf '  - message_id: %s\n' "${RENDER_MESSAGE_ID:-}"
  printf '  - message: %s\n' "${RENDER_MESSAGE_TEXT:-}"
  printf '\n  Reasoning:\n'

  local _printed_reason=0
  local _reason
  while IFS= read -r _reason; do
    [[ -n "$_reason" ]] || continue
    printf '  - %s\n' "$_reason"
    _printed_reason=1
  done <<< "$EXPLAIN_REASONING"

  if [[ "$_printed_reason" -eq 0 ]]; then
    printf '  - hook event %s with duration %ss\n' "${HOOK_EVENT:-unknown}" "${TASK_DURATION:-0}"
  fi

  printf '\n'
}

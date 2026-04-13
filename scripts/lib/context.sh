#!/bin/bash

# context.sh — runtime context module for cheerer
# Parses the hook payload, builds runtime context from history, and
# publishes backwards-compatible globals consumed by policy/render.

# Internal CTX_* vars — reset before each parse/build cycle.
context_reset() {
  CTX_HOOK_EVENT=""
  CTX_TASK_DURATION=0
  CTX_CURRENT_TS=$(date +%s 2>/dev/null || echo 0)
  CTX_CURRENT_ISO=$(date -Iseconds 2>/dev/null || date)
  CTX_HOUR="${CHEERER_HOUR:-$(date +%H 2>/dev/null || echo 12)}"
  CTX_RECENT_TASKCOMPLETED_COUNT=0
  CTX_SESSION_STREAK=0
  CTX_RECENT_ANIMATIONS=""
  CTX_RECENT_MESSAGE_IDS=""
}

# context_parse_hook_payload <json_string>
# Extracts hook_event_name and duration_seconds from a single-line JSON payload.
# Non-numeric or missing duration defaults to 0.
context_parse_hook_payload() {
  local payload="$1"

  CTX_HOOK_EVENT=$(printf '%s' "$payload" | \
    grep -o '"hook_event_name"[[:space:]]*:[[:space:]]*"[^"]*"' | \
    cut -d'"' -f4)

  local raw_dur
  raw_dur=$(printf '%s' "$payload" | \
    grep -o '"duration_seconds"[[:space:]]*:[[:space:]]*[0-9]*' | \
    grep -o '[0-9]*$')

  if [[ "$raw_dur" =~ ^[0-9]+$ ]]; then
    CTX_TASK_DURATION="$raw_dur"
  else
    CTX_TASK_DURATION=0
  fi
}

# context_build_runtime <json_payload>
# Parses the payload, takes a timestamp, and reads recent history
# via state.sh APIs to populate all CTX_* vars.
context_build_runtime() {
  local payload="${1:-}"

  context_reset
  context_parse_hook_payload "$payload"
  CTX_RECENT_TASKCOMPLETED_COUNT=$(state_recent_count $((CTX_CURRENT_TS - 300)) "TaskCompleted")
  CTX_SESSION_STREAK=$(state_recent_count $((CTX_CURRENT_TS - 1800)) "TaskCompleted")
  CTX_RECENT_ANIMATIONS="$(state_recent_values_csv 6 3)"
  CTX_RECENT_MESSAGE_IDS="$(state_recent_values_csv 7 3)"
}

# context_publish
# Exports all backwards-compatible globals consumed by policy, render,
# and state_append_history. Must be called after context_build_runtime.
context_publish() {
  export HOOK_EVENT="$CTX_HOOK_EVENT"
  export TASK_DURATION="$CTX_TASK_DURATION"
  export CURRENT_TS="$CTX_CURRENT_TS"
  export CURRENT_ISO="$CTX_CURRENT_ISO"
  export CHEERER_HOUR="$CTX_HOUR"
  export RECENT_TASKCOMPLETED_COUNT="$CTX_RECENT_TASKCOMPLETED_COUNT"
  export SESSION_STREAK="$CTX_SESSION_STREAK"
  export RECENT_ANIMATIONS="$CTX_RECENT_ANIMATIONS"
  export RECENT_MESSAGE_IDS="$CTX_RECENT_MESSAGE_IDS"
}

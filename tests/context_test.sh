#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT_DIR/tests/test_lib.sh"
. "$ROOT_DIR/scripts/lib/state.sh"
. "$ROOT_DIR/scripts/lib/context.sh"

make_history() {
  local dir="$1"
  CHEERER_DATA_DIR="$dir/data"
  mkdir -p "$CHEERER_DATA_DIR"
  STATS_FILE="$CHEERER_DATA_DIR/stats.json"
  HISTORY_FILE="$CHEERER_DATA_DIR/history.log"
  state_init
}

test_context_parse_hook_payload_extracts_event_and_duration() {
  context_reset
  context_parse_hook_payload '{"hook_event_name":"TaskCompleted","duration_seconds":95}'

  assert_eq "TaskCompleted" "$CTX_HOOK_EVENT" || return 1
  assert_eq "95" "$CTX_TASK_DURATION" || return 1
}

test_context_parse_hook_payload_defaults_bad_duration_to_zero() {
  context_reset
  context_parse_hook_payload '{"hook_event_name":"Stop","duration_seconds":"fast"}'

  assert_eq "Stop" "$CTX_HOOK_EVENT" || return 1
  assert_eq "0" "$CTX_TASK_DURATION" || return 1
}

test_context_build_runtime_reads_recent_history() {
  local tmp_dir now
  tmp_dir="$(make_tmp_dir)"
  make_history "$tmp_dir"

  now="$(date +%s)"
  state_append_history "$((now - 60))" "TaskCompleted" "12" "solid" "steady" "dance" "en_solid_steady_1"
  state_append_history "$((now - 30))" "TaskCompleted" "12" "solid" "steady" "rocket" "en_solid_steady_2"
  state_append_history "$((now - 10))" "Stop" "1" "quick" "gentle" "" "en_quick_gentle_1"

  context_build_runtime '{"hook_event_name":"TaskCompleted","duration_seconds":12}'

  assert_eq "2" "$CTX_RECENT_TASKCOMPLETED_COUNT" || return 1
  assert_eq "dance,rocket," "$CTX_RECENT_ANIMATIONS" || return 1
  assert_eq "en_solid_steady_1,en_solid_steady_2,en_quick_gentle_1" "$CTX_RECENT_MESSAGE_IDS" || return 1
}

test_context_publish_exposes_backwards_compatible_globals() {
  CTX_HOOK_EVENT="TaskCompleted"
  CTX_TASK_DURATION="33"
  CTX_CURRENT_TS="123"
  CTX_CURRENT_ISO="2026-04-13T10:00:00+00:00"
  CTX_HOUR="10"
  CTX_RECENT_TASKCOMPLETED_COUNT="4"
  CTX_SESSION_STREAK="4"
  CTX_RECENT_ANIMATIONS="dance,rocket"
  CTX_RECENT_MESSAGE_IDS="m1,m2"

  context_publish

  assert_eq "TaskCompleted" "$HOOK_EVENT" || return 1
  assert_eq "33" "$TASK_DURATION" || return 1
  assert_eq "123" "$CURRENT_TS" || return 1
  assert_eq "2026-04-13T10:00:00+00:00" "$CURRENT_ISO" || return 1
  assert_eq "10" "$CHEERER_HOUR" || return 1
  assert_eq "4" "$RECENT_TASKCOMPLETED_COUNT" || return 1
  assert_eq "4" "$SESSION_STREAK" || return 1
  assert_eq "dance,rocket" "$RECENT_ANIMATIONS" || return 1
  assert_eq "m1,m2" "$RECENT_MESSAGE_IDS" || return 1
}

run_test "context_parse_hook_payload_extracts_event_and_duration" test_context_parse_hook_payload_extracts_event_and_duration
run_test "context_parse_hook_payload_defaults_bad_duration_to_zero" test_context_parse_hook_payload_defaults_bad_duration_to_zero
run_test "context_build_runtime_reads_recent_history" test_context_build_runtime_reads_recent_history
run_test "context_publish_exposes_backwards_compatible_globals" test_context_publish_exposes_backwards_compatible_globals
finish_tests

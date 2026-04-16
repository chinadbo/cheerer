#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

. tests/test_lib.sh
. scripts/lib/config.sh
. scripts/lib/state.sh
. scripts/lib/context.sh
. scripts/lib/policy.sh
. scripts/lib/render.sh
. scripts/lib/catalog.sh
. scripts/lib/explain.sh

# Seed a temp data dir for state_init
_explain_tmp="$(make_tmp_dir)"
export CHEERER_DATA_DIR="$_explain_tmp"
export CHEERER_ROOT="$ROOT_DIR"
export CHEERER_LANG="en"
export CHEERER_STYLE="adaptive"
export CHEERER_HOUR=15
export RECENT_ANIMATIONS=""
export RECENT_MESSAGE_IDS=""
export STATE_MILESTONE_MSG=""
export ANIM_DIR="$ROOT_DIR/scripts/animations"
HISTORY_FILE="$_explain_tmp/history.log"
STATS_FILE="$_explain_tmp/stats.json"
state_init

# -----------------------------------------------------------------------
# Test 1: default probe (empty payload)
# -----------------------------------------------------------------------
test_explain_default_probe() {
  CHEERER_STYLE="adaptive"
  CHEERER_HOUR=15
  local out
  out="$(explain_run '')"

  assert_contains "$out" "cheerer — Why"
  assert_contains "$out" "Hook event: TaskCompleted"
  assert_contains "$out" "Duration: 12"
  assert_contains "$out" "- tier: solid"
  assert_contains "$out" "- mood: steady"
  assert_contains "$out" "- default TaskCompleted starts at solid/steady"
}

# -----------------------------------------------------------------------
# Test 2: long-task payload triggers big/triumphant
# -----------------------------------------------------------------------
test_explain_long_task_big_triumphant() {
  CHEERER_STYLE="adaptive"
  CHEERER_HOUR=15
  local payload='{"hook_event_name":"TaskCompleted","duration_seconds":95}'
  local out
  out="$(explain_run "$payload")"

  assert_contains "$out" "- tier: big"
  assert_contains "$out" "- mood: triumphant"
  assert_contains "$out" "- long-task threshold met"
}

# -----------------------------------------------------------------------
# Test 3: hype style forces hype mood
# -----------------------------------------------------------------------
test_explain_hype_style_forces_hype_mood() {
  CHEERER_STYLE="hype"
  CHEERER_HOUR=15
  local payload='{"hook_event_name":"TaskCompleted","duration_seconds":10}'
  local out
  out="$(explain_run "$payload")"

  assert_contains "$out" "- mood: hype"
  assert_contains "$out" "- hype style forced hype mood"
}

test_explain_uses_context_parser_for_payload() {
  CHEERER_STYLE="adaptive"
  CHEERER_HOUR=15
  local original_context_parse_hook_payload payload out

  original_context_parse_hook_payload="$(declare -f context_parse_hook_payload)"
  context_parse_hook_payload() {
    CTX_HOOK_EVENT="Stop"
    CTX_TASK_DURATION=0
  }

  payload='{"hook_event_name":"TaskCompleted","duration_seconds":95}'
  out="$(explain_run "$payload")"

  eval "$original_context_parse_hook_payload"

  assert_contains "$out" "Hook event: Stop"
  assert_contains "$out" "- tier: quick"
  assert_contains "$out" "- mood: gentle"
  assert_contains "$out" "- Stop starts at quick/gentle"
}

test_explain_does_not_mutate_stats_history_or_cooldown() {
  CHEERER_STYLE="adaptive"
  CHEERER_HOUR=15
  local payload='{"hook_event_name":"TaskCompleted","duration_seconds":12}'
  local cooldown_dir cooldown_file before_stats after_stats before_history after_history out

  export CLAUDE_SESSION_ID="explain-test"
  export CURRENT_TS="123"
  cooldown_dir="${TMPDIR:-/tmp}/cheerer_${UID}"
  cooldown_file="$cooldown_dir/last_trigger_explain-test"
  mkdir -p "$cooldown_dir"
  printf '111\n' > "$cooldown_file"

  before_stats="$(cat "$STATS_FILE")"
  before_history="$(cat "$HISTORY_FILE")"
  out="$(explain_run "$payload")"
  after_stats="$(cat "$STATS_FILE")"
  after_history="$(cat "$HISTORY_FILE")"

  assert_eq "$before_stats" "$after_stats"
  assert_eq "$before_history" "$after_history"
  assert_eq "111" "$(cat "$cooldown_file")"
  assert_contains "$out" "Reasoning:"
}

run_test "explain_default_probe" test_explain_default_probe
run_test "explain_long_task_big_triumphant" test_explain_long_task_big_triumphant
run_test "explain_hype_style_forces_hype_mood" test_explain_hype_style_forces_hype_mood
run_test "explain_uses_context_parser_for_payload" test_explain_uses_context_parser_for_payload
run_test "explain_does_not_mutate_stats_history_or_cooldown" test_explain_does_not_mutate_stats_history_or_cooldown

finish_tests

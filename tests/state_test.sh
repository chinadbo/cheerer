#!/bin/bash
set -euo pipefail

. tests/test_lib.sh
. scripts/lib/state.sh

test_state_init_creates_defaults() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  CHEERER_DATA_DIR="$tmp_dir/data"
  STATS_FILE="$CHEERER_DATA_DIR/stats.json"
  HISTORY_FILE="$CHEERER_DATA_DIR/history.log"

  state_init

  [[ -f "$STATS_FILE" ]] || return 1
  [[ -f "$HISTORY_FILE" ]] || return 1
  state_read_stats
  assert_eq "0" "$STATS_TOTAL_TRIGGERS"
  assert_eq "[]" "$STATS_MILESTONES"
}

test_state_heals_corrupt_stats() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  CHEERER_DATA_DIR="$tmp_dir/data"
  STATS_FILE="$CHEERER_DATA_DIR/stats.json"
  HISTORY_FILE="$CHEERER_DATA_DIR/history.log"

  mkdir -p "$CHEERER_DATA_DIR"
  printf 'not-json\n' > "$STATS_FILE"

  state_init
  state_read_stats

  assert_eq "0" "$STATS_TOTAL_TRIGGERS"
  assert_eq "" "$STATS_LAST_TRIGGER"
}

test_state_append_history_trims_to_fifty_rows() {
  local tmp_dir
  local i
  tmp_dir="$(make_tmp_dir)"
  CHEERER_DATA_DIR="$tmp_dir/data"
  STATS_FILE="$CHEERER_DATA_DIR/stats.json"
  HISTORY_FILE="$CHEERER_DATA_DIR/history.log"

  state_init

  for i in $(seq 1 55); do
    state_append_history "$i" "TaskCompleted" "12" "solid" "steady" "dance" "en_solid_steady_1"
  done

  assert_eq "50" "$(wc -l < "$HISTORY_FILE" | tr -d ' ')"
}

run_test "state_init_creates_defaults" test_state_init_creates_defaults
run_test "state_heals_corrupt_stats" test_state_heals_corrupt_stats
run_test "state_append_history_trims_to_fifty_rows" test_state_append_history_trims_to_fifty_rows

test_state_compute_streak() {
  local tmp_dir i
  tmp_dir="$(make_tmp_dir)"
  CHEERER_DATA_DIR="$tmp_dir/data"
  STATS_FILE="$CHEERER_DATA_DIR/stats.json"
  HISTORY_FILE="$CHEERER_DATA_DIR/history.log"

  state_init

  local now
  now=$(date +%s)
  for i in 1 2 3; do
    state_append_history "$((now - 100 + i * 10))" "TaskCompleted" "12" "solid" "steady" "dance" "msg$i"
  done

  local streak
  streak="$(state_compute_streak)"

  [[ "$streak" -ge 3 ]] || return 1
}

run_test "state_compute_streak" test_state_compute_streak

test_state_read_stats_with_extra_fields() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  CHEERER_DATA_DIR="$tmp_dir/data"
  mkdir -p "$CHEERER_DATA_DIR"
  STATS_FILE="$CHEERER_DATA_DIR/stats.json"
  HISTORY_FILE="$CHEERER_DATA_DIR/history.log"

  # Include a field whose name contains "total_triggers" as a substring
  printf '{"total_triggers_since_reset":99,"total_triggers":42,"last_trigger":"2026-04-11","milestones":[10,25]}\n' > "$STATS_FILE"

  state_read_stats

  assert_eq "42" "$STATS_TOTAL_TRIGGERS"
  assert_eq "2026-04-11" "$STATS_LAST_TRIGGER"
  assert_eq "[10,25]" "$STATS_MILESTONES"
}

run_test "state_read_stats_with_extra_fields" test_state_read_stats_with_extra_fields

test_state_read_stats_with_timezone_timestamp() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  CHEERER_DATA_DIR="$tmp_dir/data"
  mkdir -p "$CHEERER_DATA_DIR"
  STATS_FILE="$CHEERER_DATA_DIR/stats.json"
  HISTORY_FILE="$CHEERER_DATA_DIR/history.log"

  printf '{"total_triggers":7,"last_trigger":"2026-04-11T12:00:00+08:00","milestones":[]}\n' > "$STATS_FILE"

  state_read_stats

  assert_eq "7" "$STATS_TOTAL_TRIGGERS"
  assert_eq "2026-04-11T12:00:00+08:00" "$STATS_LAST_TRIGGER"
  assert_eq "[]" "$STATS_MILESTONES"
}

run_test "state_read_stats_with_timezone_timestamp" test_state_read_stats_with_timezone_timestamp
finish_tests

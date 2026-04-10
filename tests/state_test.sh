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
finish_tests

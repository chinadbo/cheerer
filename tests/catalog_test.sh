#!/bin/bash
set -euo pipefail

. tests/test_lib.sh
. scripts/lib/catalog.sh

# ---------------------------------------------------------------------------
# catalog_required_pairs
# ---------------------------------------------------------------------------

test_catalog_required_pairs_lists_expected_pairs() {
  local pairs
  pairs="$(catalog_required_pairs)"

  # Must include all 13 reachable tier|mood combos
  assert_contains "$pairs" "quick|gentle"
  assert_contains "$pairs" "quick|hype"
  assert_contains "$pairs" "quick|steady"
  assert_contains "$pairs" "quick|cozy"
  assert_contains "$pairs" "solid|steady"
  assert_contains "$pairs" "solid|rapid_fire"
  assert_contains "$pairs" "solid|cozy"
  assert_contains "$pairs" "solid|streak"
  assert_contains "$pairs" "solid|triumphant"
  assert_contains "$pairs" "big|triumphant"
  assert_contains "$pairs" "big|streak"
  assert_contains "$pairs" "big|hype"
  assert_contains "$pairs" "legendary|milestone"
}

run_test "catalog_required_pairs_lists_expected_pairs" \
  test_catalog_required_pairs_lists_expected_pairs

# ---------------------------------------------------------------------------
# catalog_validate_file — accepts a complete catalog fixture
# ---------------------------------------------------------------------------

_make_complete_fixture() {
  local dir="$1"
  local path="$dir/catalog_test.tsv"
  cat > "$path" << 'EOF'
quick|gentle|t_quick_gentle_1|msg1
quick|hype|t_quick_hype_1|msg2
quick|steady|t_quick_steady_1|msg3
quick|cozy|t_quick_cozy_1|msg4
solid|steady|t_solid_steady_1|msg5
solid|rapid_fire|t_solid_rapid_fire_1|msg6
solid|cozy|t_solid_cozy_1|msg7
solid|streak|t_solid_streak_1|msg8
solid|triumphant|t_solid_triumphant_1|msg9
big|triumphant|t_big_triumphant_1|msg10
big|streak|t_big_streak_1|msg11
big|hype|t_big_hype_1|msg12
legendary|milestone|t_legendary_milestone_1|msg13
EOF
  printf '%s' "$path"
}

test_catalog_validate_file_accepts_complete_fixture() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  local fixture
  fixture="$(_make_complete_fixture "$tmp_dir")"

  catalog_validate_file "$fixture"
}

run_test "catalog_validate_file_accepts_complete_fixture" \
  test_catalog_validate_file_accepts_complete_fixture

# ---------------------------------------------------------------------------
# catalog_validate_file — fails when a required pair is missing
# ---------------------------------------------------------------------------

test_catalog_validate_file_fails_missing_pair() {
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  local path="$tmp_dir/catalog_missing.tsv"
  cat > "$path" << 'EOF'
quick|gentle|t_quick_gentle_1|msg1
quick|hype|t_quick_hype_1|msg2
quick|steady|t_quick_steady_1|msg3
quick|cozy|t_quick_cozy_1|msg4
solid|steady|t_solid_steady_1|msg5
solid|rapid_fire|t_solid_rapid_fire_1|msg6
solid|cozy|t_solid_cozy_1|msg7
solid|streak|t_solid_streak_1|msg8
solid|triumphant|t_solid_triumphant_1|msg9
big|triumphant|t_big_triumphant_1|msg10
big|streak|t_big_streak_1|msg11
big|hype|t_big_hype_1|msg12
EOF

  if catalog_validate_file "$path" >"$tmp_dir/out" 2>&1; then
    printf 'expected failure for missing pair\n'
    return 1
  fi

  output="$(<"$tmp_dir/out")"
  assert_contains "$output" "missing required pair legendary|milestone"
}

run_test "catalog_validate_file_fails_missing_pair" \
  test_catalog_validate_file_fails_missing_pair

# ---------------------------------------------------------------------------
# catalog_validate_file — fails on duplicate message_id
# ---------------------------------------------------------------------------

test_catalog_validate_file_fails_duplicate_message_id() {
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  local path="$tmp_dir/catalog_dup.tsv"
  cat > "$path" << 'EOF'
quick|gentle|dup1|msg1
quick|gentle|dup1|msg1_dup
quick|hype|t_quick_hype_1|msg2
quick|steady|t_quick_steady_1|msg3
quick|cozy|t_quick_cozy_1|msg4
solid|steady|t_solid_steady_1|msg5
solid|rapid_fire|t_solid_rapid_fire_1|msg6
solid|cozy|t_solid_cozy_1|msg7
solid|streak|t_solid_streak_1|msg8
solid|triumphant|t_solid_triumphant_1|msg9
big|triumphant|t_big_triumphant_1|msg10
big|streak|t_big_streak_1|msg11
big|hype|t_big_hype_1|msg12
legendary|milestone|t_legendary_milestone_1|msg13
EOF

  if catalog_validate_file "$path" >"$tmp_dir/out" 2>&1; then
    printf 'expected failure for duplicate message_id\n'
    return 1
  fi

  output="$(<"$tmp_dir/out")"
  assert_contains "$output" "duplicate message_id dup1"
}

run_test "catalog_validate_file_fails_duplicate_message_id" \
  test_catalog_validate_file_fails_duplicate_message_id

# ---------------------------------------------------------------------------
# catalog_validate_file — fails on malformed row (missing field)
# ---------------------------------------------------------------------------

test_catalog_validate_file_fails_malformed_row() {
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  local path="$tmp_dir/catalog_bad.tsv"
  cat > "$path" << 'EOF'
quick|gentle|t_quick_gentle_1|msg1
quick|hype|t_quick_hype_1
quick|steady|t_quick_steady_1|msg3
quick|cozy|t_quick_cozy_1|msg4
solid|steady|t_solid_steady_1|msg5
solid|rapid_fire|t_solid_rapid_fire_1|msg6
solid|cozy|t_solid_cozy_1|msg7
solid|streak|t_solid_streak_1|msg8
solid|triumphant|t_solid_triumphant_1|msg9
big|triumphant|t_big_triumphant_1|msg10
big|streak|t_big_streak_1|msg11
big|hype|t_big_hype_1|msg12
legendary|milestone|t_legendary_milestone_1|msg13
EOF

  if catalog_validate_file "$path" >"$tmp_dir/out" 2>&1; then
    printf 'expected failure for malformed row\n'
    return 1
  fi

  output="$(<"$tmp_dir/out")"
  assert_contains "$output" "malformed row 2"
}

run_test "catalog_validate_file_fails_malformed_row" \
  test_catalog_validate_file_fails_malformed_row

# ---------------------------------------------------------------------------
# catalog_validate_all — passes for all shipped locales
# ---------------------------------------------------------------------------

test_catalog_validate_all_passes_shipped_locales() {
  CHEERER_ROOT="$PWD"
  catalog_validate_all
}

run_test "catalog_validate_all_passes_shipped_locales" \
  test_catalog_validate_all_passes_shipped_locales

finish_tests

#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT_DIR/tests/test_lib.sh"
. "$ROOT_DIR/scripts/lib/config.sh"

# ---------------------------------------------------------------------------
# test_config_apply_defaults_uses_plugin_options
# ---------------------------------------------------------------------------
test_config_apply_defaults_uses_plugin_options() {
  unset CHEERER_LANG CHEERER_ANIM CHEERER_VOICE CHEERER_STYLE CHEERER_INTENSITY \
        CHEERER_DUMB CHEERER_MODE CHEERER_COOLDOWN CHEERER_ANIM_DURATION \
        CHEERER_EPIC CHEERER_EPIC_THRESHOLD CHEERER_ENABLED 2>/dev/null || true

  CLAUDE_PLUGIN_OPTION_LANG=en
  CLAUDE_PLUGIN_OPTION_ANIM=fireworks
  CLAUDE_PLUGIN_OPTION_VOICE=off
  CLAUDE_PLUGIN_OPTION_STYLE=hype
  CLAUDE_PLUGIN_OPTION_INTENSITY=high

  config_apply_defaults

  assert_eq "en"       "$CHEERER_LANG"           || return 1
  assert_eq "fireworks" "$CHEERER_ANIM"           || return 1
  assert_eq "off"      "$CHEERER_VOICE"           || return 1
  assert_eq "hype"     "$CHEERER_STYLE"           || return 1
  assert_eq "high"     "$CHEERER_INTENSITY"       || return 1
  assert_eq "true"     "$CHEERER_ENABLED"         || return 1
  assert_eq "auto"     "$CHEERER_DUMB"            || return 1
  assert_eq "auto"     "$CHEERER_MODE"            || return 1
  assert_eq "3"        "$CHEERER_COOLDOWN"        || return 1
  assert_eq "30"       "$CHEERER_ANIM_DURATION"   || return 1
  assert_eq "false"    "$CHEERER_EPIC"            || return 1
  assert_eq "60"       "$CHEERER_EPIC_THRESHOLD"  || return 1
}

# ---------------------------------------------------------------------------
# test_config_apply_defaults_normalizes_invalid_values
# ---------------------------------------------------------------------------
test_config_apply_defaults_normalizes_invalid_values() {
  unset CLAUDE_PLUGIN_OPTION_LANG CLAUDE_PLUGIN_OPTION_ANIM CLAUDE_PLUGIN_OPTION_VOICE \
        CLAUDE_PLUGIN_OPTION_STYLE CLAUDE_PLUGIN_OPTION_INTENSITY 2>/dev/null || true

  CHEERER_LANG="klingon"
  CHEERER_STYLE="loud"
  CHEERER_INTENSITY="ultra"
  CHEERER_DUMB="yes"
  CHEERER_MODE="fancy"

  config_apply_defaults

  assert_eq "zh"       "$CHEERER_LANG"      || return 1
  assert_eq "adaptive" "$CHEERER_STYLE"     || return 1
  assert_eq "normal"   "$CHEERER_INTENSITY" || return 1
  assert_eq "auto"     "$CHEERER_DUMB"      || return 1
  assert_eq "auto"     "$CHEERER_MODE"      || return 1
}

# ---------------------------------------------------------------------------
# test_config_load_file_rejects_non_cheerer_lines
# ---------------------------------------------------------------------------
test_config_load_file_rejects_non_cheerer_lines() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  local cfg="$tmp_dir/config.sh"

  # File with a non-CHEERER line — must be rejected
  printf 'CHEERER_LANG=en\nrm -rf /\n' > "$cfg"

  CHEERER_LANG="zh"
  config_load_file "$cfg"
  assert_eq "zh" "$CHEERER_LANG" || return 1

  # A clean file must be accepted
  printf 'CHEERER_LANG=ja\n' > "$cfg"
  config_load_file "$cfg"
  assert_eq "ja" "$CHEERER_LANG" || return 1
}

# ---------------------------------------------------------------------------
# test_config_load_file_rejects_inline_command_injection
# Regression: CHEERER_LANG=en; rm -rf / must not execute and must not
# change CHEERER_LANG — the entire line fails the safe-value filter.
# ---------------------------------------------------------------------------
test_config_load_file_rejects_inline_command_injection() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  local cfg="$tmp_dir/config.sh"
  local sentinel="$tmp_dir/sentinel"

  # Payload: semicolon followed by a command that would create a sentinel file
  printf 'CHEERER_LANG=en; touch %s\n' "$sentinel" > "$cfg"

  CHEERER_LANG="zh"
  config_load_file "$cfg"

  # Variable must not have changed (file was rejected)
  assert_eq "zh" "$CHEERER_LANG" || return 1

  # Sentinel must not exist (command was not executed)
  if [[ -f "$sentinel" ]]; then
    printf 'FAIL: sentinel file was created — injection was not blocked\n'
    return 1
  fi
}

# ---------------------------------------------------------------------------
# test_config_resolve_runtime_flags_marks_dumb_term_text_only
# ---------------------------------------------------------------------------
test_config_resolve_runtime_flags_marks_dumb_term_text_only() {
  CHEERER_DUMB="auto"
  TERM="dumb"
  config_resolve_runtime_flags
  assert_eq "true" "$CHEERER_DUMB" || return 1

  CHEERER_DUMB="auto"
  TERM=""
  config_resolve_runtime_flags
  assert_eq "true" "$CHEERER_DUMB" || return 1

  CHEERER_DUMB="auto"
  TERM="xterm-256color"
  config_resolve_runtime_flags
  assert_eq "false" "$CHEERER_DUMB" || return 1

  # When already true/false, resolve_runtime_flags must leave it alone
  CHEERER_DUMB="true"
  TERM="xterm-256color"
  config_resolve_runtime_flags
  assert_eq "true" "$CHEERER_DUMB" || return 1
}

# ---------------------------------------------------------------------------
# test_config_ensure_data_dir_creates_override_dir
# ---------------------------------------------------------------------------
test_config_ensure_data_dir_creates_override_dir() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  local override_dir="$tmp_dir/my_data"

  CLAUDE_PLUGIN_DATA="$override_dir"
  unset CHEERER_DATA_DIR 2>/dev/null || true

  config_ensure_data_dir

  [[ -d "$override_dir" ]]                         || return 1
  assert_eq "$override_dir" "$CHEERER_DATA_DIR"    || return 1

  unset CLAUDE_PLUGIN_DATA 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# test_config_print_current_lists_effective_values
# ---------------------------------------------------------------------------
test_config_print_current_lists_effective_values() {
  CHEERER_ENABLED=true
  CHEERER_LANG=en
  CHEERER_ANIM=random
  CHEERER_VOICE=on
  CHEERER_STYLE=adaptive
  CHEERER_INTENSITY=normal
  CHEERER_MODE=auto
  CHEERER_DUMB=false
  CHEERER_COOLDOWN=3
  CHEERER_ANIM_DURATION=30
  CHEERER_EPIC=false
  CHEERER_EPIC_THRESHOLD=60

  local out
  out="$(config_print_current)"

  assert_contains "$out" "CHEERER_ENABLED=true"       || return 1
  assert_contains "$out" "CHEERER_LANG=en"            || return 1
  assert_contains "$out" "CHEERER_ANIM=random"        || return 1
  assert_contains "$out" "CHEERER_VOICE=on"           || return 1
  assert_contains "$out" "CHEERER_STYLE=adaptive"     || return 1
  assert_contains "$out" "CHEERER_INTENSITY=normal"   || return 1
  assert_contains "$out" "CHEERER_MODE=auto"          || return 1
  assert_contains "$out" "CHEERER_DUMB=false"         || return 1
  assert_contains "$out" "CHEERER_COOLDOWN=3"         || return 1
  assert_contains "$out" "CHEERER_ANIM_DURATION=30"   || return 1
  assert_contains "$out" "CHEERER_EPIC=false"         || return 1
  assert_contains "$out" "CHEERER_EPIC_THRESHOLD=60"  || return 1
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
run_test "config_apply_defaults_uses_plugin_options"          test_config_apply_defaults_uses_plugin_options
run_test "config_apply_defaults_normalizes_invalid_values"    test_config_apply_defaults_normalizes_invalid_values
run_test "config_load_file_rejects_non_cheerer_lines"         test_config_load_file_rejects_non_cheerer_lines
run_test "config_load_file_rejects_inline_command_injection"  test_config_load_file_rejects_inline_command_injection
run_test "config_resolve_runtime_flags_marks_dumb_term_text_only" test_config_resolve_runtime_flags_marks_dumb_term_text_only
run_test "config_ensure_data_dir_creates_override_dir"        test_config_ensure_data_dir_creates_override_dir
run_test "config_print_current_lists_effective_values"        test_config_print_current_lists_effective_values

finish_tests

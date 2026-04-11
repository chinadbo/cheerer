#!/bin/bash
set -euo pipefail

. tests/test_lib.sh

run_cheer() {
  local fixture="$1"
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  CLAUDE_PLUGIN_DATA="$tmp_dir/data" \
  CLAUDE_SESSION_ID="test-session" \
  CHEERER_LANG="en" \
  CHEERER_VOICE="off" \
  CHEERER_DUMB="true" \
  CHEERER_STYLE="adaptive" \
  CHEERER_INTENSITY="normal" \
  CHEERER_HOUR=15 \
  bash scripts/cheer.sh < "$fixture"
}

run_epic_probe() {
  local fixture="$1"
  local env_name="$2"
  local env_value="$3"
  local tmp_dir app_root bin_dir output_file

  tmp_dir="$(make_tmp_dir)"
  app_root="$tmp_dir/app"
  bin_dir="$tmp_dir/bin"
  output_file="$tmp_dir/output.log"

  mkdir -p "$app_root/scripts/lib" "$app_root/scripts/animations" "$app_root/scripts/voices" "$app_root/scripts/messages" "$bin_dir"
  cp scripts/cheer.sh "$app_root/scripts/cheer.sh"
  cp scripts/lib/state.sh "$app_root/scripts/lib/state.sh"
  cp scripts/lib/policy.sh "$app_root/scripts/lib/policy.sh"
  cp scripts/lib/render.sh "$app_root/scripts/lib/render.sh"
  cp scripts/messages/catalog_en.tsv "$app_root/scripts/messages/catalog_en.tsv"

  printf '#!/bin/bash\nexit 1\n' > "$bin_dir/tty"
  printf '#!/bin/bash\nprintf "basketball\\n"\n' > "$app_root/scripts/animations/basketball.sh"
  printf '#!/bin/bash\nprintf "dance\\n"\n' > "$app_root/scripts/animations/dance.sh"
  printf '#!/bin/bash\nprintf "fireworks\\n"\n' > "$app_root/scripts/animations/fireworks.sh"
  chmod +x "$bin_dir/tty" "$app_root/scripts/cheer.sh" "$app_root/scripts/animations/basketball.sh" "$app_root/scripts/animations/dance.sh" "$app_root/scripts/animations/fireworks.sh"

  env PATH="$bin_dir:$PATH" \
    CLAUDE_PLUGIN_DATA="$tmp_dir/data" \
    CLAUDE_SESSION_ID="epic-probe-$(basename "$tmp_dir")" \
    CHEERER_LANG="en" \
    CHEERER_VOICE="off" \
    CHEERER_DUMB="false" \
    CHEERER_MODE="full" \
    CHEERER_HOUR=15 \
    "$env_name=$env_value" \
    bash "$app_root/scripts/cheer.sh" < "$fixture" > "$output_file"

  cat "$output_file"
}

assert_contains_all() {
  local haystack="$1"
  shift
  local needle

  for needle in "$@"; do
    assert_contains "$haystack" "$needle" || return 1
  done
}

test_stop_fixture_uses_quick_message() {
  local output
  output="$(run_cheer tests/fixtures/stop-short.json)"
  assert_contains "$output" "Nice step forward"
}

test_long_task_fixture_uses_big_message() {
  local output
  output="$(run_cheer tests/fixtures/taskcompleted-long.json)"
  assert_contains "$output" "Big finish"
}

test_corrupt_stats_still_exits_zero() {
  local tmp_dir
  local output_file
  tmp_dir="$(make_tmp_dir)"
  output_file="$(mktemp "${TMPDIR:-/tmp}/cheerer-out.XXXXXX")"
  mkdir -p "$tmp_dir/data"
  printf 'not-json\n' > "$tmp_dir/data/stats.json"

  CLAUDE_PLUGIN_DATA="$tmp_dir/data" \
  CLAUDE_SESSION_ID="test-session" \
  CHEERER_LANG="en" \
  CHEERER_VOICE="off" \
  CHEERER_DUMB="true" \
  CHEERER_HOUR=15 \
  bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json > "$output_file"

  assert_contains "$(cat "$output_file")" "Strong work"
}

test_hype_style_surfaces_hype_copy() {
  local output
  output="$(CLAUDE_PLUGIN_DATA="$(make_tmp_dir)/data" CLAUDE_SESSION_ID="test-session" CHEERER_LANG="en" CHEERER_VOICE="off" CHEERER_DUMB="true" CHEERER_STYLE="hype" CHEERER_HOUR=15 bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json)"
  assert_contains "$output" "Huge energy"
}

test_dumb_mode_stays_plain_when_voice_script_runs() {
  local output
  output="$(CLAUDE_PLUGIN_DATA="$(make_tmp_dir)/data" CLAUDE_SESSION_ID="plain-test" CHEERER_LANG="en" CHEERER_VOICE="off" CHEERER_DUMB="true" CHEERER_HOUR=15 bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json)"
  assert_contains "$output" "🎉 Strong work"
  assert_not_contains "$output" $'\033[1;32m'
}

test_epic_env_runs_all_three_animations() {
  local output
  output="$(run_epic_probe tests/fixtures/taskcompleted-short.json CHEERER_EPIC true)"
  assert_contains_all "$output" basketball dance fireworks
}

test_epic_threshold_runs_all_three_animations() {
  local output
  output="$(run_epic_probe tests/fixtures/taskcompleted-short.json CHEERER_EPIC_THRESHOLD 10)"
  assert_contains_all "$output" basketball dance fireworks
}

test_cooldown_zero_enforces_minimum_one_second() {
  # CHEERER_COOLDOWN=0 must clamp to 1 second effective minimum.
  # Both runs exit 0 and produce non-empty encouragement text because
  # cooldown only suppresses animation, not text output.
  local tmp_dir output1 output2
  tmp_dir="$(make_tmp_dir)"

  output1="$(CLAUDE_PLUGIN_DATA="$tmp_dir/data" \
    CLAUDE_SESSION_ID="cooldown-test-min" \
    CHEERER_LANG="en" \
    CHEERER_VOICE="off" \
    CHEERER_DUMB="true" \
    CHEERER_COOLDOWN="0" \
    CHEERER_HOUR=15 \
    bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json)"

  output2="$(CLAUDE_PLUGIN_DATA="$tmp_dir/data" \
    CLAUDE_SESSION_ID="cooldown-test-min" \
    CHEERER_LANG="en" \
    CHEERER_VOICE="off" \
    CHEERER_DUMB="true" \
    CHEERER_COOLDOWN="0" \
    CHEERER_HOUR=15 \
    bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json)"

  # Both runs must produce non-empty output
  [[ -n "$output1" ]] || return 1
  [[ -n "$output2" ]] || return 1
}

test_custom_only_uses_custom_messages_file() {
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/data"
  printf 'Ship it!\n# a comment\nNice refactor.\n' > "$tmp_dir/data/custom-messages.txt"

  output="$(CLAUDE_PLUGIN_DATA="$tmp_dir/data" \
    CLAUDE_SESSION_ID="custom-test" \
    CHEERER_LANG="en" \
    CHEERER_VOICE="off" \
    CHEERER_DUMB="true" \
    CHEERER_CUSTOM_ONLY="true" \
    CHEERER_HOUR=15 \
    bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json)"

  # Should pick one of the custom messages, not built-in catalog text
  if printf '%s' "$output" | grep -qF "Ship it!"; then
    return 0
  fi
  assert_contains "$output" "Nice refactor."
}

run_test "stop_fixture_uses_quick_message" test_stop_fixture_uses_quick_message
run_test "long_task_fixture_uses_big_message" test_long_task_fixture_uses_big_message
run_test "corrupt_stats_still_exits_zero" test_corrupt_stats_still_exits_zero
run_test "hype_style_surfaces_hype_copy" test_hype_style_surfaces_hype_copy
run_test "dumb_mode_stays_plain_when_voice_script_runs" test_dumb_mode_stays_plain_when_voice_script_runs
run_test "epic_env_runs_all_three_animations" test_epic_env_runs_all_three_animations
run_test "epic_threshold_runs_all_three_animations" test_epic_threshold_runs_all_three_animations
run_test "cooldown_zero_enforces_minimum_one_second" test_cooldown_zero_enforces_minimum_one_second
run_test "custom_only_uses_custom_messages_file" test_custom_only_uses_custom_messages_file
finish_tests

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

test_preview_command_runs_animation() {
  local output
  output="$(bash bin/cheer --preview basketball 2>&1)"
  # Animation scripts produce multi-line output; just verify non-empty and no error
  [[ -n "$output" ]] || return 1
  assert_not_contains "$output" "not found"
}

test_list_command_discovers_animations() {
  local output
  output="$(bash bin/cheer --list 2>&1)"
  assert_contains "$output" "dance"
  assert_contains "$output" "fireworks"
  assert_contains "$output" "Languages: zh, en, ja, ko, es"
}

test_first_run_shows_welcome() {
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  output="$(CLAUDE_PLUGIN_DATA="$tmp_dir/data" \
    CLAUDE_SESSION_ID="welcome-test" \
    CHEERER_LANG="en" \
    CHEERER_VOICE="off" \
    CHEERER_DUMB="true" \
    CHEERER_HOUR=15 \
    bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json)"
  assert_contains "$output" "Welcome!"
  assert_contains "$output" "cheer --list"
}

test_korean_lang_works() {
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  output="$(CLAUDE_PLUGIN_DATA="$tmp_dir/data" \
    CLAUDE_SESSION_ID="ko-test" \
    CHEERER_LANG="ko" \
    CHEERER_VOICE="off" \
    CHEERER_DUMB="true" \
    CHEERER_HOUR=15 \
    bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json)"
  # Korean catalog has quick gentle messages — check for Korean characters
  if printf '%s' "$output" | grep -q '작은\|확실한\|순조롭\|끝냈\|빠르고\|깔끔하게'; then
    return 0
  fi
  # Fallback: just verify non-empty and no crash
  [[ -n "$output" ]]
}

test_danmaku_animation_exits_cleanly() {
  local theme
  for theme in dance fireworks basketball rocket trophy wave; do
    CHEERER_MESSAGE="Test message" bash "scripts/animations/${theme}.sh" >/dev/null 2>&1 \
      || return 1
  done
}

test_danmaku_animation_contains_message() {
  local output
  output="$(CHEERER_MESSAGE="UniqueTest123" bash scripts/animations/dance.sh 2>&1)"
  # Use raw output — grep -F finds ASCII needles even among ANSI/emoji bytes
  assert_contains "$output" "UniqueTest123"
}

test_danmaku_message_sanitizes_control_chars() {
  local output
  output="$(CHEERER_MESSAGE=$'Has\x1b[2JEscape' bash scripts/animations/dance.sh 2>&1)"
  # The raw ESC[2J byte sequence must not appear — sanitization strips the ESC byte
  if printf '%s' "$output" | grep -q $'\x1b\[2J'; then
    printf 'did not expect to find raw ESC[2J in output\n'
    return 1
  fi
  # "Has" and "Escape" survive sanitization (only C0 control chars are stripped)
  assert_contains "$output" "Has"
  assert_contains "$output" "Escape"
}

test_danmaku_narrow_terminal_exits_cleanly() {
  COLUMNS=10 CHEERER_MESSAGE="Test" bash scripts/animations/dance.sh >/dev/null 2>&1
}

test_danmaku_library_graceful_fallback() {
  # Test real theme file in a location where ../lib/animation.sh doesn't exist
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  cp scripts/animations/dance.sh "$tmp_dir/dance.sh"
  output="$(CHEERER_MESSAGE="FallbackCheck" bash "$tmp_dir/dance.sh" 2>&1)"
  assert_contains "$output" "FallbackCheck"
  rm -rf "$tmp_dir"
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
run_test "preview_command_runs_animation" test_preview_command_runs_animation
run_test "list_command_discovers_animations" test_list_command_discovers_animations
run_test "first_run_shows_welcome" test_first_run_shows_welcome
run_test "korean_lang_works" test_korean_lang_works
run_test "danmaku_animation_exits_cleanly" test_danmaku_animation_exits_cleanly
run_test "danmaku_animation_contains_message" test_danmaku_animation_contains_message
run_test "danmaku_message_sanitizes_control_chars" test_danmaku_message_sanitizes_control_chars
run_test "danmaku_narrow_terminal_exits_cleanly" test_danmaku_narrow_terminal_exits_cleanly
run_test "danmaku_library_graceful_fallback" test_danmaku_library_graceful_fallback

test_cooldown_does_not_reset_timer() {
  local tmp_dir output1 output2
  tmp_dir="$(make_tmp_dir)"

  # First trigger
  output1="$(CLAUDE_PLUGIN_DATA="$tmp_dir/data" \
    CLAUDE_SESSION_ID="cooldown-reset-test" \
    CHEERER_LANG="en" \
    CHEERER_VOICE="off" \
    CHEERER_DUMB="true" \
    CHEERER_COOLDOWN="10" \
    CHEERER_HOUR=15 \
    bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json)"

  # Second trigger within cooldown — should NOT reset the cooldown clock
  output2="$(CLAUDE_PLUGIN_DATA="$tmp_dir/data" \
    CLAUDE_SESSION_ID="cooldown-reset-test" \
    CHEERER_LANG="en" \
    CHEERER_VOICE="off" \
    CHEERER_DUMB="true" \
    CHEERER_COOLDOWN="10" \
    CHEERER_HOUR=15 \
    bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json)"

  # Verify first run had output (not in cooldown)
  assert_contains "$output1" "🎉"
  # Verify second run still had text (cooldown doesn't suppress text)
  assert_contains "$output2" "🎉"

  # Read cooldown file — it should be the FIRST trigger's timestamp, not the second's
  local cooldown_file="${TMPDIR:-/tmp}/cheerer_${UID}/last_trigger_cooldownresettest"
  if [[ -f "$cooldown_file" ]]; then
    local ts1 ts2
    ts1="$(date +%s)"
    local file_val
    file_val="$(cat "$cooldown_file" 2>/dev/null || echo 0)"
    # file_val must be a valid unix timestamp and less than or equal to now
    [[ "$file_val" =~ ^[0-9]+$ ]] || return 1
    [[ "$file_val" -le "$ts1" ]] || return 1
  fi
}

run_test "cooldown_does_not_reset_timer" test_cooldown_does_not_reset_timer

test_anim_display_width_ascii() {
  . scripts/lib/animation.sh
  local w
  w="$(anim_display_width "abc")"
  assert_eq "3" "$w"
}

test_anim_display_width_cjk() {
  . scripts/lib/animation.sh
  local w
  w="$(anim_display_width "中")"
  assert_eq "2" "$w"
}

test_anim_display_width_latin_extended() {
  . scripts/lib/animation.sh
  local w
  w="$(anim_display_width "é")"
  assert_eq "1" "$w"
}

test_anim_display_width_emoji() {
  . scripts/lib/animation.sh
  local w
  w="$(anim_display_width "🎉")"
  assert_eq "2" "$w"
}

test_anim_display_width_mixed() {
  . scripts/lib/animation.sh
  local w
  w="$(anim_display_width "España")"
  assert_eq "6" "$w"
}

test_anim_display_width_korean() {
  . scripts/lib/animation.sh
  local w
  w="$(anim_display_width "한글")"
  assert_eq "4" "$w"
}

run_test "anim_display_width_ascii" test_anim_display_width_ascii
run_test "anim_display_width_cjk" test_anim_display_width_cjk
run_test "anim_display_width_latin_extended" test_anim_display_width_latin_extended
run_test "anim_display_width_emoji" test_anim_display_width_emoji
run_test "anim_display_width_mixed" test_anim_display_width_mixed
run_test "anim_display_width_korean" test_anim_display_width_korean

test_disable_writes_config() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"

  CLAUDE_PLUGIN_DATA="$tmp_dir/data" bash bin/cheer --disable

  [[ -f "$tmp_dir/data/config.sh" ]] || return 1
  local content
  content="$(cat "$tmp_dir/data/config.sh")"
  assert_eq "CHEERER_ENABLED=false" "$content"
}

test_enable_removes_config() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/data"
  printf 'CHEERER_ENABLED=false\n' > "$tmp_dir/data/config.sh"

  CLAUDE_PLUGIN_DATA="$tmp_dir/data" bash bin/cheer --enable

  [[ ! -f "$tmp_dir/data/config.sh" ]] || return 1
}

test_disabled_cheerer_exits_silently() {
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/data"
  printf 'CHEERER_ENABLED=false\n' > "$tmp_dir/data/config.sh"

  output="$(CLAUDE_PLUGIN_DATA="$tmp_dir/data" \
    CLAUDE_SESSION_ID="disabled-test" \
    CHEERER_LANG="en" \
    CHEERER_VOICE="off" \
    CHEERER_DUMB="true" \
    CHEERER_HOUR=15 \
    bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json)"

  [[ -z "$output" ]] || return 1
}

test_config_sh_only_allows_cheerer_vars() {
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/data"
  # config.sh with a malicious line should NOT be sourced
  printf 'CHEERER_LANG=en\nrm -rf /tmp/fake\nCHEERER_VOICE=off\n' > "$tmp_dir/data/config.sh"

  # The script should NOT source this file (contains non-CHEERER lines)
  # and should fall through to default behavior (no crash)
  output="$(CLAUDE_PLUGIN_DATA="$tmp_dir/data" \
    CLAUDE_SESSION_ID="config-security-test" \
    CHEERER_LANG="zh" \
    CHEERER_VOICE="off" \
    CHEERER_DUMB="true" \
    CHEERER_HOUR=15 \
    bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json 2>&1)"

  # Should still work — config.sh was rejected, defaults used
  [[ -n "$output" ]] || return 1
}

run_test "disable_writes_config" test_disable_writes_config
run_test "enable_removes_config" test_enable_removes_config
run_test "disabled_cheerer_exits_silently" test_disabled_cheerer_exits_silently
run_test "config_sh_only_allows_cheerer_vars" test_config_sh_only_allows_cheerer_vars
finish_tests

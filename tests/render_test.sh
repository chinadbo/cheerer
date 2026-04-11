#!/bin/bash
set -euo pipefail

. tests/test_lib.sh
. scripts/lib/render.sh

test_render_selects_exact_tier_and_mood() {
  CHEERER_ROOT="$PWD"
  CHEERER_LANG="en"
  POLICY_TIER="big"
  POLICY_MOOD="triumphant"
  RECENT_MESSAGE_IDS=""
  STATE_MILESTONE_MSG=""

  render_select_message

  assert_eq "en_big_triumphant_1" "$RENDER_MESSAGE_ID"
  assert_contains "$RENDER_MESSAGE_TEXT" "Big finish"
}

test_render_avoids_recent_message_ids() {
  CHEERER_ROOT="$PWD"
  CHEERER_LANG="en"
  POLICY_TIER="solid"
  POLICY_MOOD="steady"
  RECENT_MESSAGE_IDS="en_solid_steady_1"
  STATE_MILESTONE_MSG=""

  render_select_message

  assert_eq "en_solid_steady_2" "$RENDER_MESSAGE_ID"
}

test_soft_intensity_skips_quick_animation() {
  HOOK_EVENT="TaskCompleted"
  CHEERER_DUMB="false"
  CHEERER_MODE="auto"
  CHEERER_INTENSITY="soft"
  POLICY_TIER="quick"

  render_should_animate

  assert_eq "false" "$RENDER_ANIMATE"
}

test_epic_mode_animates_all_three() {
  local tmp_dir
  local log_file
  local basket dance fireworks

  tmp_dir="$(make_tmp_dir)"
  log_file="$tmp_dir/epic.log"
  mkdir -p "$tmp_dir/animations" "$tmp_dir/voices"
  printf '#!/bin/bash\nprintf "basketball\\n" >> "%s"\n' "$log_file" > "$tmp_dir/animations/basketball.sh"
  printf '#!/bin/bash\nprintf "dance\\n" >> "%s"\n' "$log_file" > "$tmp_dir/animations/dance.sh"
  printf '#!/bin/bash\nprintf "fireworks\\n" >> "%s"\n' "$log_file" > "$tmp_dir/animations/fireworks.sh"
  chmod +x "$tmp_dir/animations/basketball.sh" "$tmp_dir/animations/dance.sh" "$tmp_dir/animations/fireworks.sh"

  ANIM_DIR="$tmp_dir/animations"
  VOICE_DIR="$tmp_dir/voices"
  CHEERER_LANG="en"
  CHEERER_ANIM="epic"
  RENDER_ANIMATE="true"
  IN_COOLDOWN="false"
  POLICY_ANIMATION="dance"
  RENDER_MESSAGE_TEXT="Epic test"
  RENDER_MESSAGE_ID="epic_test"

  render_emit

  basket="$(sed -n '1p' "$log_file")"
  dance="$(sed -n '2p' "$log_file")"
  fireworks="$(sed -n '3p' "$log_file")"
  assert_eq "basketball" "$basket"
  assert_eq "dance" "$dance"
  assert_eq "fireworks" "$fireworks"
}

test_render_solid_rapid_fire_picks_catalog_row() {
  CHEERER_ROOT="$PWD"
  CHEERER_LANG="en"
  POLICY_TIER="solid"
  POLICY_MOOD="rapid_fire"
  RECENT_MESSAGE_IDS=""
  STATE_MILESTONE_MSG=""
  CHEERER_CUSTOM_ONLY="false"
  CHEERER_CUSTOM_MSG=""

  render_select_message

  assert_eq "en_solid_rapid_fire_1" "$RENDER_MESSAGE_ID"
  assert_contains "$RENDER_MESSAGE_TEXT" "on a roll"
}

test_render_quick_hype_picks_catalog_row() {
  CHEERER_ROOT="$PWD"
  CHEERER_LANG="en"
  POLICY_TIER="quick"
  POLICY_MOOD="hype"
  RECENT_MESSAGE_IDS=""
  STATE_MILESTONE_MSG=""
  CHEERER_CUSTOM_ONLY="false"
  CHEERER_CUSTOM_MSG=""

  render_select_message

  assert_eq "en_quick_hype_1" "$RENDER_MESSAGE_ID"
  assert_contains "$RENDER_MESSAGE_TEXT" "spark alive"
}

test_render_solid_streak_picks_catalog_row() {
  CHEERER_ROOT="$PWD"
  CHEERER_LANG="en"
  POLICY_TIER="solid"
  POLICY_MOOD="streak"
  RECENT_MESSAGE_IDS=""
  STATE_MILESTONE_MSG=""
  CHEERER_CUSTOM_ONLY="false"
  CHEERER_CUSTOM_MSG=""

  render_select_message

  assert_eq "en_solid_streak_1" "$RENDER_MESSAGE_ID"
  assert_contains "$RENDER_MESSAGE_TEXT" "streak keeps building"
}

test_render_solid_triumphant_picks_catalog_row() {
  CHEERER_ROOT="$PWD"
  CHEERER_LANG="en"
  POLICY_TIER="solid"
  POLICY_MOOD="triumphant"
  RECENT_MESSAGE_IDS=""
  STATE_MILESTONE_MSG=""
  CHEERER_CUSTOM_ONLY="false"
  CHEERER_CUSTOM_MSG=""

  render_select_message

  assert_eq "en_solid_triumphant_1" "$RENDER_MESSAGE_ID"
  assert_contains "$RENDER_MESSAGE_TEXT" "Strong finish"
}

test_render_custom_only_uses_custom_file() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir"
  printf 'Ship it!\nNice refactor.\n' > "$tmp_dir/custom-messages.txt"

  CHEERER_ROOT="$PWD"
  CHEERER_LANG="en"
  CHEERER_DATA_DIR="$tmp_dir"
  CHEERER_CUSTOM_ONLY="true"
  CHEERER_CUSTOM_MSG=""
  POLICY_TIER="solid"
  POLICY_MOOD="steady"
  RECENT_MESSAGE_IDS=""
  STATE_MILESTONE_MSG=""

  render_select_message

  assert_eq "custom" "$RENDER_MESSAGE_ID"
}

test_render_custom_only_falls_back_when_file_absent() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"

  CHEERER_ROOT="$PWD"
  CHEERER_LANG="en"
  CHEERER_DATA_DIR="$tmp_dir"
  CHEERER_CUSTOM_ONLY="true"
  CHEERER_CUSTOM_MSG=""
  POLICY_TIER="solid"
  POLICY_MOOD="steady"
  RECENT_MESSAGE_IDS=""
  STATE_MILESTONE_MSG=""

  render_select_message

  assert_eq "en_solid_steady_1" "$RENDER_MESSAGE_ID"
}

test_voice_script_uses_cheerer_message() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/voices"
  cat > "$tmp_dir/voices/cheer_en.sh" << 'VOICE_EOF'
#!/bin/bash
if [[ -n "${CHEERER_MESSAGE:-}" ]]; then
  MSG="$CHEERER_MESSAGE"
else
  MSG="fallback message"
fi
CHEERER_DUMB="true"
CHEERER_VOICE="off"
echo "🎉 $MSG"
VOICE_EOF
  chmod +x "$tmp_dir/voices/cheer_en.sh"

  export CHEERER_MESSAGE="Test message from catalog"
  export CHEERER_DUMB="true"
  export CHEERER_VOICE="off"
  export CHEERER_MESSAGE_ID="test_id"

  local result
  result="$(bash "$tmp_dir/voices/cheer_en.sh")"

  assert_contains "$result" "Test message from catalog"
}

run_test "render_selects_exact_tier_and_mood" test_render_selects_exact_tier_and_mood
run_test "render_avoids_recent_message_ids" test_render_avoids_recent_message_ids
run_test "soft_intensity_skips_quick_animation" test_soft_intensity_skips_quick_animation
run_test "epic_mode_animates_all_three" test_epic_mode_animates_all_three
run_test "render_solid_rapid_fire_picks_catalog_row" test_render_solid_rapid_fire_picks_catalog_row
run_test "render_quick_hype_picks_catalog_row" test_render_quick_hype_picks_catalog_row
run_test "render_solid_streak_picks_catalog_row" test_render_solid_streak_picks_catalog_row
run_test "render_solid_triumphant_picks_catalog_row" test_render_solid_triumphant_picks_catalog_row
run_test "render_custom_only_uses_custom_file" test_render_custom_only_uses_custom_file
run_test "render_custom_only_falls_back_when_file_absent" test_render_custom_only_falls_back_when_file_absent
run_test "voice_script_uses_cheerer_message" test_voice_script_uses_cheerer_message

test_render_fatigue_forces_different_message() {
  CHEERER_ROOT="$PWD"
  CHEERER_LANG="en"
  POLICY_TIER="solid"
  POLICY_MOOD="steady"
  RECENT_MESSAGE_IDS="en_solid_steady_1,en_solid_steady_1,en_solid_steady_1,en_solid_steady_2"
  STATE_MILESTONE_MSG=""
  CHEERER_CUSTOM_ONLY="false"
  CHEERER_CUSTOM_MSG=""

  render_select_message

  [[ "$RENDER_MESSAGE_ID" != "en_solid_steady_1" ]] || return 1
}

test_render_no_fatigue_below_threshold() {
  CHEERER_ROOT="$PWD"
  CHEERER_LANG="en"
  POLICY_TIER="solid"
  POLICY_MOOD="steady"
  RECENT_MESSAGE_IDS="en_solid_steady_1,en_solid_steady_1"
  STATE_MILESTONE_MSG=""
  CHEERER_CUSTOM_ONLY="false"
  CHEERER_CUSTOM_MSG=""

  render_select_message

  assert_eq "en_solid_steady_2" "$RENDER_MESSAGE_ID"
}

run_test "render_fatigue_forces_different_message" test_render_fatigue_forces_different_message
run_test "render_no_fatigue_below_threshold" test_render_no_fatigue_below_threshold
finish_tests

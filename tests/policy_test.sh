#!/bin/bash
set -euo pipefail

. tests/test_lib.sh
. scripts/lib/policy.sh

test_stop_defaults_to_quick_gentle() {
  HOOK_EVENT="Stop"
  TASK_DURATION=5
  RECENT_TASKCOMPLETED_COUNT=0
  SESSION_STREAK=0
  STATE_MILESTONE_MSG=""
  CHEERER_STYLE="adaptive"
  CHEERER_INTENSITY="normal"
  RECENT_ANIMATIONS=""
  ANIM_DIR="$PWD/scripts/animations"
  CHEERER_HOUR=15

  policy_select_celebration

  assert_eq "quick" "$POLICY_TIER"
  assert_eq "gentle" "$POLICY_MOOD"
}

test_long_task_becomes_big_triumphant() {
  HOOK_EVENT="TaskCompleted"
  TASK_DURATION=95
  RECENT_TASKCOMPLETED_COUNT=1
  SESSION_STREAK=1
  STATE_MILESTONE_MSG=""
  CHEERER_STYLE="adaptive"
  CHEERER_INTENSITY="normal"
  RECENT_ANIMATIONS="basketball"

  policy_select_celebration

  assert_eq "big" "$POLICY_TIER"
  assert_eq "triumphant" "$POLICY_MOOD"
}

test_milestone_forces_legendary_fireworks() {
  HOOK_EVENT="TaskCompleted"
  TASK_DURATION=20
  RECENT_TASKCOMPLETED_COUNT=2
  SESSION_STREAK=2
  STATE_MILESTONE_MSG="🏆 Trigger #10!"
  CHEERER_STYLE="adaptive"
  CHEERER_INTENSITY="normal"
  RECENT_ANIMATIONS="dance"

  policy_select_celebration

  assert_eq "legendary" "$POLICY_TIER"
  assert_eq "milestone" "$POLICY_MOOD"
  assert_eq "fireworks" "$POLICY_ANIMATION"
}

test_hype_style_upgrades_solid_runs() {
  HOOK_EVENT="TaskCompleted"
  TASK_DURATION=20
  RECENT_TASKCOMPLETED_COUNT=1
  SESSION_STREAK=1
  STATE_MILESTONE_MSG=""
  CHEERER_STYLE="hype"
  CHEERER_INTENSITY="normal"
  RECENT_ANIMATIONS="fireworks"

  policy_select_celebration

  assert_eq "big" "$POLICY_TIER"
  assert_eq "hype" "$POLICY_MOOD"
}

test_rapid_fire_count_sets_solid_rapid_fire_mood() {
  HOOK_EVENT="TaskCompleted"
  TASK_DURATION=10
  RECENT_TASKCOMPLETED_COUNT=4
  SESSION_STREAK=4
  STATE_MILESTONE_MSG=""
  CHEERER_STYLE="adaptive"
  CHEERER_INTENSITY="normal"
  RECENT_ANIMATIONS="basketball"

  policy_select_celebration

  assert_eq "solid" "$POLICY_TIER"
  assert_eq "rapid_fire" "$POLICY_MOOD"
}

test_animation_discovers_from_anim_dir() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/animations"
  printf '#!/bin/bash\n' > "$tmp_dir/animations/rocket.sh"
  printf '#!/bin/bash\n' > "$tmp_dir/animations/trophy.sh"
  ANIM_DIR="$tmp_dir/animations"
  RECENT_ANIMATIONS=""

  policy_pick_animation

  assert_eq "rocket" "$POLICY_ANIMATION"
}

test_animation_avoids_recent_picks() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/animations"
  printf '#!/bin/bash\n' > "$tmp_dir/animations/rocket.sh"
  printf '#!/bin/bash\n' > "$tmp_dir/animations/trophy.sh"
  printf '#!/bin/bash\n' > "$tmp_dir/animations/wave.sh"
  ANIM_DIR="$tmp_dir/animations"
  RECENT_ANIMATIONS="rocket,trophy"

  policy_pick_animation

  assert_eq "wave" "$POLICY_ANIMATION"
}

test_animation_falls_back_when_all_recent() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/animations"
  printf '#!/bin/bash\n' > "$tmp_dir/animations/rocket.sh"
  ANIM_DIR="$tmp_dir/animations"
  RECENT_ANIMATIONS="rocket"

  policy_pick_animation

  assert_eq "rocket" "$POLICY_ANIMATION"
}

run_test "stop_defaults_to_quick_gentle" test_stop_defaults_to_quick_gentle
run_test "long_task_becomes_big_triumphant" test_long_task_becomes_big_triumphant
run_test "milestone_forces_legendary_fireworks" test_milestone_forces_legendary_fireworks
run_test "hype_style_upgrades_solid_runs" test_hype_style_upgrades_solid_runs
run_test "rapid_fire_count_sets_solid_rapid_fire_mood" test_rapid_fire_count_sets_solid_rapid_fire_mood
run_test "animation_discovers_from_anim_dir" test_animation_discovers_from_anim_dir
run_test "animation_avoids_recent_picks" test_animation_avoids_recent_picks
run_test "animation_falls_back_when_all_recent" test_animation_falls_back_when_all_recent

test_morning_upgrades_gentle_to_steady() {
  HOOK_EVENT="Stop"
  TASK_DURATION=5
  RECENT_TASKCOMPLETED_COUNT=0
  SESSION_STREAK=0
  STATE_MILESTONE_MSG=""
  CHEERER_STYLE="adaptive"
  CHEERER_INTENSITY="normal"
  RECENT_ANIMATIONS=""
  ANIM_DIR="$PWD/scripts/animations"
  CHEERER_HOUR=9

  policy_select_celebration

  assert_eq "quick" "$POLICY_TIER"
  assert_eq "steady" "$POLICY_MOOD"
}

test_late_night_overrides_to_cozy() {
  HOOK_EVENT="TaskCompleted"
  TASK_DURATION=10
  RECENT_TASKCOMPLETED_COUNT=0
  SESSION_STREAK=0
  STATE_MILESTONE_MSG=""
  CHEERER_STYLE="adaptive"
  CHEERER_INTENSITY="normal"
  RECENT_ANIMATIONS=""
  ANIM_DIR="$PWD/scripts/animations"
  CHEERER_HOUR=23

  policy_select_celebration

  assert_eq "cozy" "$POLICY_MOOD"
}

run_test "morning_upgrades_gentle_to_steady" test_morning_upgrades_gentle_to_steady
run_test "late_night_overrides_to_cozy" test_late_night_overrides_to_cozy

test_midnight_hour_zero_no_crash() {
  HOOK_EVENT="Stop"
  TASK_DURATION=5
  RECENT_TASKCOMPLETED_COUNT=0
  SESSION_STREAK=0
  STATE_MILESTONE_MSG=""
  CHEERER_STYLE="adaptive"
  CHEERER_INTENSITY="normal"
  RECENT_ANIMATIONS=""
  ANIM_DIR="$PWD/scripts/animations"
  CHEERER_HOUR=0

  policy_select_celebration

  # Hour 0 is late night (22-6 range), so quick tier gets cozy override
  assert_eq "quick" "$POLICY_TIER"
  assert_eq "cozy" "$POLICY_MOOD"
}

run_test "midnight_hour_zero_no_crash" test_midnight_hour_zero_no_crash
finish_tests

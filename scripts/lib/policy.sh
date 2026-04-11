#!/bin/bash

_policy_apply_time_of_day() {
  local hour="${CHEERER_HOUR:-$(date +%H 2>/dev/null || echo 12)}"
  hour=$((10#$hour))

  # Morning (6-12): +1 mood energy
  if [[ "$hour" -ge 6 ]] && [[ "$hour" -lt 12 ]]; then
    if [[ "$POLICY_MOOD" == "gentle" ]]; then
      POLICY_MOOD="steady"
    elif [[ "$POLICY_MOOD" == "steady" ]]; then
      POLICY_MOOD="rapid_fire"
    fi
  fi

  # Late night (22-6): cozy override for quick/solid
  if [[ "$hour" -ge 22 ]] || [[ "$hour" -lt 6 ]]; then
    if [[ "$POLICY_TIER" == "quick" ]] || [[ "$POLICY_TIER" == "solid" ]]; then
      POLICY_MOOD="cozy"
    fi
  fi
}

policy_pick_animation() {
  local recent_csv=",${RECENT_ANIMATIONS:-},"
  local candidate candidates=()

  for f in "${ANIM_DIR:-$PWD/scripts/animations}"/*.sh; do
    [[ -f "$f" ]] || continue
    candidates+=("$(basename "$f" .sh)")
  done

  for candidate in "${candidates[@]}"; do
    if [[ "$recent_csv" != *",$candidate,"* ]]; then
      POLICY_ANIMATION="$candidate"
      return 0
    fi
  done

  POLICY_ANIMATION="${candidates[0]:-basketball}"
}

policy_select_celebration() {
  POLICY_TIER="solid"
  POLICY_MOOD="steady"
  POLICY_ANIMATION_MODE="single"
  POLICY_ANIMATION=""

  if [[ "$HOOK_EVENT" == "Stop" ]]; then
    POLICY_TIER="quick"
    POLICY_MOOD="gentle"
  fi

  if [[ "$HOOK_EVENT" == "TaskCompleted" ]] && [[ "${TASK_DURATION:-0}" =~ ^[0-9]+$ ]] && [[ "${TASK_DURATION:-0}" -ge 60 ]]; then
    POLICY_TIER="big"
    POLICY_MOOD="triumphant"
  fi

  if [[ "${RECENT_TASKCOMPLETED_COUNT:-0}" -ge 4 ]] && [[ "$POLICY_TIER" == "solid" ]]; then
    POLICY_MOOD="rapid_fire"
  fi

  if [[ "${SESSION_STREAK:-0}" -ge 5 ]] && [[ "$POLICY_TIER" != "legendary" ]]; then
    POLICY_TIER="big"
    POLICY_MOOD="streak"
  fi

  if [[ -n "${STATE_MILESTONE_MSG:-}" ]]; then
    POLICY_TIER="legendary"
    POLICY_MOOD="milestone"
    POLICY_ANIMATION="fireworks"
    return 0
  fi

  _policy_apply_time_of_day

  case "${CHEERER_STYLE:-adaptive}" in
    hype)
      if [[ "$POLICY_TIER" == "solid" ]]; then
        POLICY_TIER="big"
      fi
      POLICY_MOOD="hype"
      ;;
    cozy)
      if [[ "$POLICY_TIER" == "big" ]]; then
        POLICY_TIER="solid"
      fi
      if [[ "$POLICY_MOOD" == "steady" ]]; then
        POLICY_MOOD="cozy"
      fi
      ;;
    balanced|adaptive)
      ;;
    *)
      ;;
  esac

  policy_pick_animation
}

#!/bin/bash

render_catalog_path() {
  printf '%s/scripts/messages/catalog_%s.tsv' "${CHEERER_ROOT:-$PWD}" "$CHEERER_LANG"
}

render_load_custom_message() {
  local custom_file="${CHEERER_DATA_DIR:-${CLAUDE_PLUGIN_DATA:-$HOME/.config/cheerer}}/custom-messages.txt"
  local line picked=()

  [[ -f "$custom_file" ]] || return 1

  while IFS= read -r line; do
    [[ "$line" =~ ^# ]] && continue
    [[ -z "${line// }" ]] && continue
    picked+=("$line")
  done < "$custom_file"

  [[ "${#picked[@]}" -eq 0 ]] && return 1

  RENDER_MESSAGE_ID="custom"
  RENDER_MESSAGE_TEXT="${picked[RANDOM % ${#picked[@]}]}"
  return 0
}

render_select_message() {
  local catalog_path
  local fallback_line=""
  local line=""
  local tier mood message_id message_text
  local recent_csv=",${RECENT_MESSAGE_IDS:-},"

  if [[ -n "${CHEERER_CUSTOM_MSG:-}" ]]; then
    RENDER_MESSAGE_ID="custom"
    RENDER_MESSAGE_TEXT="$CHEERER_CUSTOM_MSG"
    return 0
  fi

  if [[ "${CHEERER_CUSTOM_ONLY:-false}" == "true" ]]; then
    if render_load_custom_message; then
      return 0
    fi
  fi

  catalog_path="$(render_catalog_path)"
  while IFS='|' read -r tier mood message_id message_text; do
    [[ "$tier" == "$POLICY_TIER" ]] || continue
    if [[ "$mood" == "$POLICY_MOOD" ]]; then
      if [[ "$recent_csv" != *",$message_id,"* ]]; then
        RENDER_MESSAGE_ID="$message_id"
        RENDER_MESSAGE_TEXT="$message_text"
        [[ -n "${STATE_MILESTONE_MSG:-}" ]] && RENDER_MESSAGE_TEXT="$RENDER_MESSAGE_TEXT ${STATE_MILESTONE_MSG}"
        return 0
      fi
      [[ -n "$fallback_line" ]] || fallback_line="$message_id|$message_text"
    fi
  done < "$catalog_path"

  if [[ -n "$fallback_line" ]]; then
    RENDER_MESSAGE_ID="${fallback_line%%|*}"
    RENDER_MESSAGE_TEXT="${fallback_line#*|}"
    [[ -n "${STATE_MILESTONE_MSG:-}" ]] && RENDER_MESSAGE_TEXT="$RENDER_MESSAGE_TEXT ${STATE_MILESTONE_MSG}"
    return 0
  fi

  RENDER_MESSAGE_ID="fallback"
  RENDER_MESSAGE_TEXT="Great work. Task complete."
}

render_should_animate() {
  RENDER_ANIMATE="true"

  if [[ "${CHEERER_DUMB:-false}" == "true" ]] || [[ "${CHEERER_MODE:-auto}" == "text" ]]; then
    RENDER_ANIMATE="false"
    return 0
  fi

  if [[ "${CHEERER_INTENSITY:-normal}" == "soft" ]] && [[ "$POLICY_TIER" == "quick" ]]; then
    RENDER_ANIMATE="false"
    return 0
  fi

  if [[ "$HOOK_EVENT" == "Stop" ]] && [[ "${CHEERER_MODE:-auto}" != "full" ]] && [[ "${CHEERER_INTENSITY:-normal}" != "high" ]]; then
    RENDER_ANIMATE="false"
  fi
}

render_emit() {
  local voice_script="$VOICE_DIR/cheer_${CHEERER_LANG}.sh"
  local anim_name

  if [[ "${CHEERER_FIRST_RUN:-false}" == "true" ]]; then
    if [[ "${CHEERER_DUMB:-false}" == "true" ]]; then
      echo ""
      echo "  cheerer — Welcome!"
      echo ""
      echo "  Your celebration plugin is active."
      echo "  Animations and encouragement will play when you complete tasks."
      echo ""
      echo "  Configure: cheer --list"
      echo "  Preview:   cheer --preview"
      echo "  Stats:     cheer --stats"
      echo ""
    else
      echo ""
      echo -e "\033[1;36m  cheerer — Welcome!\033[0m"
      echo ""
      echo "  Your celebration plugin is active."
      echo "  Animations and encouragement will play when you complete tasks."
      echo ""
      echo -e "  Configure: \033[1mcheer --list\033[0m"
      echo -e "  Preview:   \033[1mcheer --preview\033[0m"
      echo -e "  Stats:     \033[1mcheer --stats\033[0m"
      echo ""
    fi
  fi

  if [[ "$RENDER_ANIMATE" == "true" ]] && [[ "$IN_COOLDOWN" == "false" ]]; then
    if [[ "${CHEERER_ANIM:-random}" == "epic" ]]; then
      for anim_file in "$ANIM_DIR"/*.sh; do
        [[ -f "$anim_file" ]] || continue
        bash "$anim_file"
      done
    elif [[ -f "$ANIM_DIR/$POLICY_ANIMATION.sh" ]]; then
      bash "$ANIM_DIR/$POLICY_ANIMATION.sh"
    fi
  fi

  export CHEERER_MESSAGE="$RENDER_MESSAGE_TEXT"
  export CHEERER_MESSAGE_ID="$RENDER_MESSAGE_ID"
  export CHEERER_DUMB="${CHEERER_DUMB:-false}"
  export CHEERER_VOICE="${CHEERER_VOICE:-on}"

  if [[ -f "$voice_script" ]]; then
    bash "$voice_script"
  elif [[ "${CHEERER_DUMB:-false}" == "true" ]]; then
    printf '🎉 %s\n' "$RENDER_MESSAGE_TEXT"
  else
    printf '\033[1;32m🎉 %s\033[0m\n' "$RENDER_MESSAGE_TEXT"
  fi
}

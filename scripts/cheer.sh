#!/bin/bash
# cheer.sh — cheerer main entry script
# Triggered by Claude Code hooks on Stop / TaskCompleted events.
# Plays a random pixel animation and multilingual voice encouragement.
#
# ┌──────────────────────────────────────────────────────────────────┐
# │  Configuration: env vars or userConfig (set with /plugin enable) │
# │                                                                  │
# │  Source                      Variable               Default      │
# │  userConfig (plugin enable)  CLAUDE_PLUGIN_OPTION_LANG    zh     │
# │  manual env override         CHEERER_LANG               (same)   │
# │                                                                  │
# │  CHEERER_ENABLED   master switch  true|false      default: true  │
# │  CHEERER_LANG      language       zh|en|ja        default: zh    │
# │  CHEERER_ANIM      animation      basketball|                    │
# │                                   dance|                        │
# │                                   fireworks|                    │
# │                                   epic|          default: random│
# │                                   random                        │
# │  CHEERER_VOICE     voice toggle   on|off          default: on    │
# │  CHEERER_MODE      output mode    auto|full|text  default: auto  │
# │  CHEERER_COOLDOWN  cooldown (sec) positive int    default: 3     │
# │  CHEERER_EPIC_THRESHOLD threshold  positive int   default: 60    │
# │                                                                  │
# │  userConfig values (set during /plugin enable cheerer):          │
# │    CLAUDE_PLUGIN_OPTION_LANG  → mapped to CHEERER_LANG           │
# │    CLAUDE_PLUGIN_OPTION_ANIM  → mapped to CHEERER_ANIM           │
# │    CLAUDE_PLUGIN_OPTION_VOICE → mapped to CHEERER_VOICE          │
# │                                                                  │
# │  Cooldown: if two triggers fire within CHEERER_COOLDOWN seconds, │
# │  the second skips animation but still shows a text cheer.        │
# │  State tracked via /tmp/cheerer_last_trigger                     │
# └──────────────────────────────────────────────────────────────────┘
#
# Hook event JSON is available via stdin and used for mode selection.

# Always exit 0 — never let cheerer errors affect Claude Code
set +e

# ── 1. Master switch ──────────────────────────────────────
CHEERER_ENABLED="${CHEERER_ENABLED:-true}"
if [[ "$CHEERER_ENABLED" == "false" ]]; then
  exit 0
fi

# ── 2. Redirect stdout → terminal ────────────────────────
# Claude Code suppresses hook stdout. Force output to terminal.
if [[ ! -t 1 ]]; then
  _TTY=$(tty 2>/dev/null) || _TTY=/dev/tty
  if [[ -w "$_TTY" ]]; then
    exec 1>"$_TTY"
  fi
fi

# ── 3. Drain stdin (hook event JSON) ─────────────────────
# Claude Code passes event data as JSON on stdin.
if read -r -t 0.1 _HOOK_EVENT 2>/dev/null; then :; fi
HOOK_EVENT=$(printf '%s' "$_HOOK_EVENT" | grep -o '"hook_event_name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
TASK_DURATION=$(printf "%s" "$_HOOK_EVENT" | grep -o 'duration_seconds:[0-9]*' | cut -d: -f2)

# ── 4. Script paths ───────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANIM_DIR="$SCRIPT_DIR/animations"
VOICE_DIR="$SCRIPT_DIR/voices"
CHEERER_DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.config/cheerer}"
STATS_FILE="$CHEERER_DATA_DIR/stats.json"
CUSTOM_MESSAGES_FILE="$CHEERER_DATA_DIR/custom-messages.txt"

# ── 5. Resolve configuration ─────────────────────────────
# Priority: explicit CHEERER_* env > CLAUDE_PLUGIN_OPTION_* (userConfig) > defaults
CHEERER_LANG="${CHEERER_LANG:-${CLAUDE_PLUGIN_OPTION_LANG:-zh}}"
CHEERER_ANIM="${CHEERER_ANIM:-${CLAUDE_PLUGIN_OPTION_ANIM:-random}}"
CHEERER_VOICE="${CHEERER_VOICE:-${CLAUDE_PLUGIN_OPTION_VOICE:-on}}"
CHEERER_MODE="${CHEERER_MODE:-auto}"
CHEERER_CUSTOM_ONLY="${CHEERER_CUSTOM_ONLY:-false}"
CHEERER_COOLDOWN="${CHEERER_COOLDOWN:-3}"
CHEERER_EPIC_THRESHOLD="${CHEERER_EPIC_THRESHOLD:-60}"
# minimum 1s prevents dual-trigger from Stop+TaskCompleted firing simultaneously
EFFECTIVE_COOLDOWN=$(( CHEERER_COOLDOWN > 1 ? CHEERER_COOLDOWN : 1 ))

# Validate language
case "$CHEERER_LANG" in
  zh|en|ja) ;;
  *) CHEERER_LANG="zh" ;;
esac

case "$CHEERER_MODE" in
  auto|full|text) ;;
  *) CHEERER_MODE="auto" ;;
esac

# ── 6. Dumb terminal detection ────────────────────────────
CHEERER_DUMB=false
if [[ "${TERM:-}" == "dumb" ]] || [[ -z "${TERM:-}" ]]; then
  CHEERER_DUMB=true
else
  COLOR_COUNT=$(tput colors 2>/dev/null || echo 0)
  if [[ "$COLOR_COUNT" -lt 8 ]] 2>/dev/null; then
    CHEERER_DUMB=true
  fi
fi
export CHEERER_DUMB

# ── 7. Cooldown check ─────────────────────────────────────
COOLDOWN_FILE="/tmp/cheerer_last_trigger_${CLAUDE_SESSION_ID:-default}"
IN_COOLDOWN=false
CURRENT_TIME=$(date +%s 2>/dev/null || echo 0)

if [[ -f "$COOLDOWN_FILE" ]]; then
  LAST_RUN=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo 0)
  if [[ -n "$LAST_RUN" ]] && [[ "$LAST_RUN" =~ ^[0-9]+$ ]]; then
    DIFF=$(( CURRENT_TIME - LAST_RUN ))
    if [[ "$DIFF" -lt "$EFFECTIVE_COOLDOWN" ]] 2>/dev/null; then
      IN_COOLDOWN=true
    fi
  fi
fi
echo "$CURRENT_TIME" > "$COOLDOWN_FILE" 2>/dev/null || true

MILESTONE_MSG=""
{
  mkdir -p "$CHEERER_DATA_DIR"
  if [[ ! -f "$STATS_FILE" ]]; then
    printf '{"total_triggers":0,"last_trigger":"","milestones":[]}\n' > "$STATS_FILE"
  fi

  STATS_JSON=$(cat "$STATS_FILE" 2>/dev/null)
  TOTAL_TRIGGERS=$(printf '%s' "$STATS_JSON" | grep -o '"total_triggers":[0-9]*' | cut -d: -f2)
  [[ "$TOTAL_TRIGGERS" =~ ^[0-9]+$ ]] || TOTAL_TRIGGERS=0
  TOTAL_TRIGGERS=$((TOTAL_TRIGGERS + 1))

  LAST_TRIGGER=$(date -Iseconds 2>/dev/null || date)
  MILESTONES_JSON=$(printf '%s' "$STATS_JSON" | grep -o '"milestones":\[[^]]*\]' | cut -d: -f2-)
  [[ -n "$MILESTONES_JSON" ]] || MILESTONES_JSON='[]'

  for milestone in 10 25 50 100 250 500 1000; do
    if [[ "$TOTAL_TRIGGERS" -eq "$milestone" ]]; then
      MILESTONE_MSG="🏆 Trigger #$TOTAL_TRIGGERS!"
      if [[ "$MILESTONES_JSON" == "[]" ]]; then
        MILESTONES_JSON="[$TOTAL_TRIGGERS]"
      else
        MILESTONES_JSON="${MILESTONES_JSON%]},$TOTAL_TRIGGERS]"
      fi
      break
    fi
  done

  printf '{"total_triggers":%s,"last_trigger":"%s","milestones":%s}\n' \
    "$TOTAL_TRIGGERS" "$LAST_TRIGGER" "$MILESTONES_JSON" > "$STATS_FILE"
} 2>/dev/null || true

CUSTOM_MSGS=()
if [[ -f "$CUSTOM_MESSAGES_FILE" ]]; then
  while IFS= read -r custom_msg; do
    [[ -z "$custom_msg" ]] && continue
    [[ "$custom_msg" == \#* ]] && continue
    CUSTOM_MSGS+=("$custom_msg")
  done < "$CUSTOM_MESSAGES_FILE"
fi

CHEERER_CUSTOM_MSG=""
if (( ${#CUSTOM_MSGS[@]} > 0 )); then
  if [[ "$CHEERER_CUSTOM_ONLY" == "true" ]] || [[ $((RANDOM % 2)) -eq 0 ]]; then
    CHEERER_CUSTOM_MSG="${CUSTOM_MSGS[$((RANDOM % ${#CUSTOM_MSGS[@]}))]}"
  fi
fi

# ── 8. Select animation ───────────────────────────────────
ANIMS=(basketball dance fireworks)
RUN_EPIC=false
if [[ "$CHEERER_EPIC" == "true" ]] || [[ "$CHEERER_ANIM" == "epic" ]]; then
  RUN_EPIC=true
elif [[ "$TASK_DURATION" =~ ^[0-9]+$ ]] && [[ "$TASK_DURATION" -ge "$CHEERER_EPIC_THRESHOLD" ]]; then
  RUN_EPIC=true
fi

if [[ -n "$MILESTONE_MSG" ]]; then
  ANIM="fireworks"
elif [[ "$CHEERER_ANIM" == "random" ]] || [[ -z "$CHEERER_ANIM" ]]; then
  ANIM="${ANIMS[$((RANDOM % ${#ANIMS[@]}))]}"
else
  ANIM="$CHEERER_ANIM"
fi
ANIM_SCRIPT="$ANIM_DIR/$ANIM.sh"
PLAY_ANIMATION=true
if [[ "$CHEERER_MODE" == "text" ]]; then
  PLAY_ANIMATION=false
elif [[ "$HOOK_EVENT" == "Stop" ]] && [[ "$CHEERER_MODE" != "full" ]]; then
  PLAY_ANIMATION=false
fi

# ── 9. Play animation ─────────────────────────────────────
if [[ "$PLAY_ANIMATION" == "true" ]] && [[ "$IN_COOLDOWN" == "false" ]] && [[ "$CHEERER_DUMB" == "false" ]]; then
  if [[ "$RUN_EPIC" == "true" ]]; then
    for epic_anim in basketball dance fireworks; do
      if [[ -f "$ANIM_DIR/$epic_anim.sh" ]]; then
        bash "$ANIM_DIR/$epic_anim.sh"
      fi
    done
  elif [[ -f "$ANIM_SCRIPT" ]]; then
    bash "$ANIM_SCRIPT"
  fi
fi

# ── 10. Voice / text encouragement ────────────────────────
VOICE_SCRIPT="$VOICE_DIR/cheer_${CHEERER_LANG}.sh"
FALLBACK_MSG="Great work! Task complete!"
if [[ -n "$MILESTONE_MSG" ]]; then
  FALLBACK_MSG="$FALLBACK_MSG $MILESTONE_MSG"
fi

if [[ -f "$VOICE_SCRIPT" ]]; then
  CHEERER_VOICE="$CHEERER_VOICE" CHEERER_DUMB="$CHEERER_DUMB" CHEERER_MILESTONE_MSG="$MILESTONE_MSG" CHEERER_CUSTOM_MSG="$CHEERER_CUSTOM_MSG" bash "$VOICE_SCRIPT"
else
  # Fallback
  if [[ "$CHEERER_DUMB" == "true" ]]; then
    echo "$FALLBACK_MSG"
  else
    echo -e "\033[1;32m🎉 $FALLBACK_MSG\033[0m"
  fi
fi

exit 0

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
# │                                   dance|          default: random│
# │                                   fireworks|                     │
# │                                   random                         │
# │  CHEERER_VOICE     voice toggle   on|off          default: on    │
# │  CHEERER_COOLDOWN  cooldown (sec) positive int    default: 3     │
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
# Hook event JSON is available via stdin (currently read but unused;
# reserved for future use, e.g. showing session info in messages).

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
# We read it to prevent "broken pipe" but don't use it yet.
if read -r -t 0.1 _HOOK_EVENT 2>/dev/null; then :; fi

# ── 4. Script paths ───────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANIM_DIR="$SCRIPT_DIR/animations"
VOICE_DIR="$SCRIPT_DIR/voices"

# ── 5. Resolve configuration ─────────────────────────────
# Priority: explicit CHEERER_* env > CLAUDE_PLUGIN_OPTION_* (userConfig) > defaults
CHEERER_LANG="${CHEERER_LANG:-${CLAUDE_PLUGIN_OPTION_LANG:-zh}}"
CHEERER_ANIM="${CHEERER_ANIM:-${CLAUDE_PLUGIN_OPTION_ANIM:-random}}"
CHEERER_VOICE="${CHEERER_VOICE:-${CLAUDE_PLUGIN_OPTION_VOICE:-on}}"
CHEERER_COOLDOWN="${CHEERER_COOLDOWN:-3}"

# Validate language
case "$CHEERER_LANG" in
  zh|en|ja) ;;
  *) CHEERER_LANG="zh" ;;
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
COOLDOWN_FILE="/tmp/cheerer_last_trigger"
IN_COOLDOWN=false
CURRENT_TIME=$(date +%s 2>/dev/null || echo 0)

if [[ -f "$COOLDOWN_FILE" ]]; then
  LAST_RUN=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo 0)
  if [[ -n "$LAST_RUN" ]] && [[ "$LAST_RUN" =~ ^[0-9]+$ ]]; then
    DIFF=$(( CURRENT_TIME - LAST_RUN ))
    if [[ "$DIFF" -lt "$CHEERER_COOLDOWN" ]] 2>/dev/null; then
      IN_COOLDOWN=true
    fi
  fi
fi
echo "$CURRENT_TIME" > "$COOLDOWN_FILE" 2>/dev/null || true

# ── 8. Select animation ───────────────────────────────────
ANIMS=(basketball dance fireworks)
if [[ "$CHEERER_ANIM" == "random" ]] || [[ -z "$CHEERER_ANIM" ]]; then
  ANIM="${ANIMS[$((RANDOM % ${#ANIMS[@]}))]}"
else
  ANIM="$CHEERER_ANIM"
fi
ANIM_SCRIPT="$ANIM_DIR/$ANIM.sh"

# ── 9. Play animation ─────────────────────────────────────
if [[ "$IN_COOLDOWN" == "false" ]] && [[ "$CHEERER_DUMB" == "false" ]]; then
  if [[ -f "$ANIM_SCRIPT" ]]; then
    bash "$ANIM_SCRIPT"
  fi
fi

# ── 10. Voice / text encouragement ────────────────────────
VOICE_SCRIPT="$VOICE_DIR/cheer_${CHEERER_LANG}.sh"

if [[ -f "$VOICE_SCRIPT" ]]; then
  CHEERER_VOICE="$CHEERER_VOICE" CHEERER_DUMB="$CHEERER_DUMB" bash "$VOICE_SCRIPT"
else
  # Fallback
  if [[ "$CHEERER_DUMB" == "true" ]]; then
    echo "Great work! Task complete!"
  else
    echo -e "\033[1;32m🎉 Great work! Task complete!\033[0m"
  fi
fi

exit 0

#!/bin/bash
set +e

CHEERER_ENABLED="${CHEERER_ENABLED:-true}"
if [[ "$CHEERER_ENABLED" == "false" ]]; then
  exit 0
fi

if [[ ! -t 1 ]]; then
  _TTY=$(tty 2>/dev/null)
  if [[ $? -eq 0 ]] && [[ -n "$_TTY" ]] && [[ -w "$_TTY" ]]; then
    exec 1>"$_TTY"
  fi
fi

if read -r -t 1 _HOOK_EVENT 2>/dev/null; then :; fi
HOOK_EVENT=$(printf '%s' "$_HOOK_EVENT" | grep -o '"hook_event_name"[[:space:]]*:[[:space:]]*"[^"]*"' | cut -d'"' -f4)
TASK_DURATION=$(printf '%s' "$_HOOK_EVENT" | grep -o '"duration_seconds"[[:space:]]*:[[:space:]]*[0-9]*' | grep -o '[0-9]*$')

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHEERER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ANIM_DIR="$SCRIPT_DIR/animations"
VOICE_DIR="$SCRIPT_DIR/voices"
CHEERER_DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.config/cheerer}"
STATS_FILE="$CHEERER_DATA_DIR/stats.json"
HISTORY_FILE="$CHEERER_DATA_DIR/history.log"

CHEERER_LANG="${CHEERER_LANG:-${CLAUDE_PLUGIN_OPTION_LANG:-zh}}"
CHEERER_ANIM="${CHEERER_ANIM:-${CLAUDE_PLUGIN_OPTION_ANIM:-random}}"
CHEERER_VOICE="${CHEERER_VOICE:-${CLAUDE_PLUGIN_OPTION_VOICE:-on}}"
CHEERER_STYLE="${CHEERER_STYLE:-${CLAUDE_PLUGIN_OPTION_STYLE:-adaptive}}"
CHEERER_INTENSITY="${CHEERER_INTENSITY:-${CLAUDE_PLUGIN_OPTION_INTENSITY:-normal}}"
CHEERER_DUMB="${CHEERER_DUMB:-auto}"
CHEERER_MODE="${CHEERER_MODE:-auto}"
CHEERER_COOLDOWN="${CHEERER_COOLDOWN:-3}"
CHEERER_EPIC_THRESHOLD="${CHEERER_EPIC_THRESHOLD:-60}"
CHEERER_EPIC="${CHEERER_EPIC:-false}"

case "$CHEERER_LANG" in zh|en|ja|ko|es) ;; *) CHEERER_LANG="zh" ;; esac
case "$CHEERER_STYLE" in adaptive|balanced|hype|cozy) ;; *) CHEERER_STYLE="adaptive" ;; esac
case "$CHEERER_INTENSITY" in soft|normal|high) ;; *) CHEERER_INTENSITY="normal" ;; esac
case "$CHEERER_MODE" in auto|full|text) ;; *) CHEERER_MODE="auto" ;; esac
case "$CHEERER_DUMB" in auto|true|false) ;; *) CHEERER_DUMB="auto" ;; esac

if [[ "$CHEERER_DUMB" == "auto" ]]; then
  CHEERER_DUMB=false
  if [[ "${TERM:-}" == "dumb" ]] || [[ -z "${TERM:-}" ]]; then
    CHEERER_DUMB=true
  fi
fi

. "$SCRIPT_DIR/lib/state.sh"
. "$SCRIPT_DIR/lib/policy.sh"
. "$SCRIPT_DIR/lib/render.sh"

state_init
CHEERER_FIRST_RUN="false"
if [[ "${STATS_TOTAL_TRIGGERS:-0}" -eq 0 ]]; then
  CHEERER_FIRST_RUN="true"
fi
CURRENT_TS=$(date +%s 2>/dev/null || echo 0)
CURRENT_ISO=$(date -Iseconds 2>/dev/null || date)
export CHEERER_HOUR="${CHEERER_HOUR:-$(date +%H 2>/dev/null || echo 12)}"
RECENT_TASKCOMPLETED_COUNT=$(state_recent_count $((CURRENT_TS - 300)) "TaskCompleted")
SESSION_STREAK=$(state_recent_count $((CURRENT_TS - 1800)) "TaskCompleted")
RECENT_ANIMATIONS="$(state_recent_values_csv 6 3)"
RECENT_MESSAGE_IDS="$(state_recent_values_csv 7 3)"
IN_COOLDOWN="false"

_safe_session_id="${CLAUDE_SESSION_ID:-default}"
_safe_session_id="${_safe_session_id//[^a-zA-Z0-9._-]/}"
_safe_session_id="${_safe_session_id:0:64}"
CHEERER_TMP_DIR="${TMPDIR:-/tmp}/cheerer_${UID}"
mkdir -p -m 700 "$CHEERER_TMP_DIR" 2>/dev/null || true
COOLDOWN_FILE="$CHEERER_TMP_DIR/last_trigger_${_safe_session_id:-default}"
_EFFECTIVE_COOLDOWN="${CHEERER_COOLDOWN:-3}"
if [[ "$_EFFECTIVE_COOLDOWN" =~ ^[0-9]+$ ]] && [[ "$_EFFECTIVE_COOLDOWN" -lt 1 ]]; then
  _EFFECTIVE_COOLDOWN=1
fi
if [[ -f "$COOLDOWN_FILE" ]]; then
  LAST_RUN=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo 0)
  if [[ "$LAST_RUN" =~ ^[0-9]+$ ]] && [[ $((CURRENT_TS - LAST_RUN)) -lt $_EFFECTIVE_COOLDOWN ]]; then
    IN_COOLDOWN="true"
  fi
fi
echo "$CURRENT_TS" > "$COOLDOWN_FILE" 2>/dev/null || true

if [[ ! "${CHEERER_EPIC_THRESHOLD:-}" =~ ^[0-9]+$ ]]; then
  CHEERER_EPIC_THRESHOLD=60
fi

if [[ "$CHEERER_EPIC" == "true" ]] || { [[ "${TASK_DURATION:-0}" =~ ^[0-9]+$ ]] && [[ "${TASK_DURATION:-0}" -ge "$CHEERER_EPIC_THRESHOLD" ]]; }; then
  CHEERER_ANIM="epic"
fi

state_record_trigger "$CURRENT_ISO"
policy_select_celebration
if [[ "$CHEERER_ANIM" != "random" ]] && [[ "$CHEERER_ANIM" != "epic" ]]; then
  if [[ "$CHEERER_ANIM" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    POLICY_ANIMATION="$CHEERER_ANIM"
  else
    CHEERER_ANIM="random"
  fi
fi
render_select_message
render_should_animate
render_emit
state_append_history "$CURRENT_TS" "$HOOK_EVENT" "${TASK_DURATION:-0}" "$POLICY_TIER" "$POLICY_MOOD" "$POLICY_ANIMATION" "$RENDER_MESSAGE_ID"

exit 0

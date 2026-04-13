#!/bin/bash
# basketball.sh — Basketball danmaku theme
# Sports-themed encouragement floats across the terminal

ANIM_LIB="$(dirname "${BASH_SOURCE[0]}")/../lib/animation.sh"
if [[ ! -f "$ANIM_LIB" ]]; then
  printf '🎉 %s\n' "$(printf '%s' "${CHEERER_MESSAGE:-Great work!}" | sed $'s/\033\[[0-9;]*[A-Za-z]//g' | tr -d '\001-\037')"
  exit 0
fi
. "$ANIM_LIB"

MSG="$(anim_sanitize_msg "${CHEERER_MESSAGE:-Great work!}")"

DANMAKU_ROWS=6
DANMAKU_TICK=0.065
DANMAKU_FRAMES=30
DANMAKU_ROW=(   1                  2                3           4                           5               6                 )
DANMAKU_TEXT=(  "🏀 Swish! 🏀"    "━━━ ● ━━━"     "🏀 $MSG"  "🏀 Nothing but net! 🏀"   "▸▸▸ ▏▸▸▸"     "🏀 Score! 🏀"   )
DANMAKU_COLOR=($'\033[38;5;208m'  $'\033[33m'      $'\033[1;32m' $'\033[38;5;208m'        $'\033[96m'     $'\033[33m'       )
DANMAKU_SPEED=(3                  4                2            3                           5               4                 )
DANMAKU_DELAY=(0                  5                2            8                           12              3                 )

if ! anim_validate_theme; then
  anim_fallback_plain
  exit 0
fi

anim_danmaku_run

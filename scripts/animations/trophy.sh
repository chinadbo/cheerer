#!/bin/bash
# trophy.sh — Trophy danmaku theme
# Championship-themed encouragement floats across the terminal

ANIM_LIB="$(dirname "${BASH_SOURCE[0]}")/../lib/animation.sh"
if [[ ! -f "$ANIM_LIB" ]]; then
  printf '🎉 %s\n' "${CHEERER_MESSAGE:-Great work!}"
  exit 0
fi
. "$ANIM_LIB"

MSG="$(anim_sanitize_msg "${CHEERER_MESSAGE:-Great work!}")"

DANMAKU_ROWS=6
DANMAKU_TICK=0.07
DANMAKU_FRAMES=30
DANMAKU_ROW=(   1                  2                  3           4                       5                6                  )
DANMAKU_TEXT=(  "🏆 ★ 🏆 ★ 🏆"   "✨ Champion! ✨"  "🏆 $MSG"  "★ 🏆 Winner! 🏆 ★"   "✦ ✧ ✦ ✧ ✦"    "🏆 ★ Gold! ★ 🏆" )
DANMAKU_COLOR=($'\033[33m'        $'\033[97m'        $'\033[1;33m' $'\033[35m'            $'\033[96m'      $'\033[33m'        )
DANMAKU_SPEED=(3                  2                  2            3                       4                3                  )
DANMAKU_DELAY=(0                  5                  2            8                       12               3                  )

anim_danmaku_run

#!/bin/bash
# wave.sh — Wave danmaku theme
# Ocean-themed encouragement floats across the terminal

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
DANMAKU_ROW=(   1                2                  3           4                  5                   6                )
DANMAKU_TEXT=(  "🌊 ～～～ 🌊"  "～～ Flow! ～～"  "🌊 $MSG"  "🌊 Smooth! 🌊"   "～～～ 🌊 ～～～" "🌊 ～～～ 🌊" )
DANMAKU_COLOR=($'\033[34m'      $'\033[96m'        $'\033[1;32m' $'\033[34m'       $'\033[97m'         $'\033[96m'      )
DANMAKU_SPEED=(3                4                  2            3                  5                   3                )
DANMAKU_DELAY=(0                5                  2            8                  12                  3                )

anim_danmaku_run

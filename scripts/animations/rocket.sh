#!/bin/bash
# rocket.sh — Rocket danmaku theme
# Launch-themed encouragement floats across the terminal

ANIM_LIB="$(dirname "${BASH_SOURCE[0]}")/../lib/animation.sh"
if [[ ! -f "$ANIM_LIB" ]]; then
  printf '🎉 %s\n' "${CHEERER_MESSAGE:-Great work!}"
  exit 0
fi
. "$ANIM_LIB"

MSG="${CHEERER_MESSAGE:-Great work!}"

DANMAKU_ROWS=6
DANMAKU_TICK=0.07
DANMAKU_FRAMES=30
DANMAKU_ROW=(   1                   2                     3           4                         5                  6                  )
DANMAKU_TEXT=(  "🚀 3...2...1..."  "▸▸▸ Liftoff! ▸▸▸"   "🚀 $MSG"  "🚀 To the moon! 🚀"    "│ │ │ ★ ★ ★"    "▓▓▒▒░░  ▓▓▒▒░░" )
DANMAKU_COLOR=($'\033[31m'         $'\033[38;5;208m'     $'\033[1;96m' $'\033[33m'             $'\033[97m'        $'\033[31m'        )
DANMAKU_SPEED=(2                   4                     2            3                         3                  5                  )
DANMAKU_DELAY=(0                   5                     2            8                         12                 3                  )

anim_danmaku_run

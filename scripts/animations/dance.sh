#!/bin/bash
# dance.sh — Dance danmaku theme
# Musical notes and encouragement float across the terminal

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
DANMAKU_ROW=(   1    2           3           4                  5            6        )
DANMAKU_TEXT=(  "🎵 ♪ ♫ ♪ 🎵" "🎶 Keep going! 🎶" "🎉 $MSG" "♫ You got this! ♫" "♬ ♪ ♬ ♪ ♬" "🎵 Nice! 🎵")
DANMAKU_COLOR=($'\033[96m'      $'\033[33m'          $'\033[1;32m' $'\033[35m'        $'\033[95m'  $'\033[96m'     )
DANMAKU_SPEED=(3                2                    2            4                   3            5               )
DANMAKU_DELAY=(0                5                    2            10                  3            15              )

anim_danmaku_run

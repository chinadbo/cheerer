#!/bin/bash
# rocket.sh — Rocket liftoff pixel animation
# 6 frames: countdown → ignition → liftoff → through clouds → stars → orbit
# Canvas: 10 rows × 22 chars (with border)

RESET="\033[0m"
RED="\033[31m"
ORANGE="\033[38;5;208m"
YELLOW="\033[38;5;226m"
WHITE="\033[97m"
CYAN="\033[96m"
GRAY="\033[90m"
BOLD="\033[1m"
BLUE="\033[34m"

tput civis 2>/dev/null || true
trap 'tput cnorm 2>/dev/null || true' EXIT

DELAY=0.2
FRAME_LINES=10

draw_frame1() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${WHITE}${BOLD}  ║       3...       ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║      /\\         ║${RESET}\n" \
"${GRAY}  ║      ||         ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame2() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${YELLOW}${BOLD}  ║       2...       ║${RESET}\n" \
"${GRAY}  ║      /\\         ║${RESET}\n" \
"${GRAY}  ║      ||         ║${RESET}\n" \
"${ORANGE}  ║     /  \\        ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame3() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${WHITE}${BOLD}  ║       1...       ║${RESET}\n" \
"${GRAY}  ║      /\\         ║${RESET}\n" \
"${GRAY}  ║      ||         ║${RESET}\n" \
"${ORANGE}  ║     /  \\        ║${RESET}\n" \
"${RED}  ║    🔥🔥🔥      ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame4() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${WHITE}${BOLD}  ║      /\\         ║${RESET}\n" \
"${GRAY}  ║      ||         ║${RESET}\n" \
"${ORANGE}  ║     /  \\        ║${RESET}\n" \
"${RED}  ║    🔥🔥🔥      ║${RESET}\n" \
"${YELLOW}  ║   |||||||||     ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame5() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${WHITE}${BOLD}  ║      /\\         ║${RESET}\n" \
"${GRAY}  ║      ||  ✦      ║${RESET}\n" \
"${GRAY}  ║     /  \\  ✦     ║${RESET}\n" \
"${CYAN}  ║    ✦         ✦   ║${RESET}\n" \
"${YELLOW}  ║   |||||||||     ║${RESET}\n" \
"${CYAN}  ║  ✦    ✦    ✦    ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame6() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${CYAN}  ║ ✦    ✦    ✦  ✦   ║${RESET}\n" \
"${WHITE}${BOLD}  ║      🛰️          ║${RESET}\n" \
"${CYAN}  ║   ✦      ✦       ║${RESET}\n" \
"${BLUE}${BOLD}  ║   🌍 LAUNCHED!  ║${RESET}\n" \
"${CYAN}  ║ ✦    ✦    ✦  ✦  ║${RESET}\n" \
"${CYAN}  ║      ✦    ✦     ║${RESET}\n" \
"${CYAN}  ║   ✦         ✦   ║${RESET}\n" \
"${CYAN}  ║ ✦    ✦    ✦     ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# Play animation
draw_frame1

for frame_fn in draw_frame2 draw_frame3 draw_frame4 draw_frame5 draw_frame6; do
  printf "\033[${FRAME_LINES}A\033[0G"
  "$frame_fn"
  sleep "$DELAY"
done

sleep 0.8

# Clean up
printf "\033[${FRAME_LINES}A\033[0G"
for ((i=0; i<FRAME_LINES; i++)); do
  printf "\033[2K\n"
done
printf "\033[${FRAME_LINES}A\033[0G"

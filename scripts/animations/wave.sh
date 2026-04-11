#!/bin/bash
# wave.sh — Ocean wave celebration pixel animation
# 5 frames: calm → swell → wave rises → surfer rides → celebration splash
# Canvas: 10 rows × 22 chars (with border)

RESET="\033[0m"
BLUE="\033[34m"
CYAN="\033[96m"
WHITE="\033[97m"
YELLOW="\033[38;5;226m"
GREEN="\033[32m"
GRAY="\033[90m"
BOLD="\033[1m"

tput civis 2>/dev/null || true
trap 'tput cnorm 2>/dev/null || true' EXIT

DELAY=0.22
FRAME_LINES=10

draw_frame1() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${BLUE}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${CYAN}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${BLUE}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${BLUE}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame2() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${CYAN}  ║     ~~~~~~       ║${RESET}\n" \
"${BLUE}  ║   ~~~    ~~~~    ║${RESET}\n" \
"${BLUE}  ║ ~~~        ~~~~  ║${RESET}\n" \
"${CYAN}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${BLUE}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame3() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${CYAN}  ║        ~~~~      ║${RESET}\n" \
"${WHITE}${BOLD}  ║       /surf\\     ║${RESET}\n" \
"${BLUE}  ║    ~~~     ~~~~  ║${RESET}\n" \
"${BLUE}  ║  ~~~         ~~  ║${RESET}\n" \
"${CYAN}  ║ ~~~~~~~~~~~~~~~~ ║${RESET}\n" \
"${BLUE}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame4() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${WHITE}${BOLD}  ║     🏄 ~~~~~     ║${RESET}\n" \
"${CYAN}  ║    ~~~   ~~~~    ║${RESET}\n" \
"${BLUE}  ║  ~~~       ~~~~  ║${RESET}\n" \
"${YELLOW}${BOLD}  ║   ✦  RIDE!  ✦   ║${RESET}\n" \
"${CYAN}  ║  ~~~~~~~~~~~~~~  ║${RESET}\n" \
"${BLUE}  ║ ~~~~~~~~~~~~~~~~ ║${RESET}\n" \
"${BLUE}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame5() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${CYAN}  ║  💧  💧  💧  💧  ║${RESET}\n" \
"${WHITE}${BOLD}  ║    🏄‍♂️ ✦  ✦      ║${RESET}\n" \
"${CYAN}  ║  💧  💧  💧  💧  ║${RESET}\n" \
"${GREEN}${BOLD}  ║  🌊 RADICAL! 🌊  ║${RESET}\n" \
"${CYAN}  ║  💧  💧  💧  💧  ║${RESET}\n" \
"${BLUE}  ║ ~~~~~~~~~~~~~~~~ ║${RESET}\n" \
"${BLUE}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${BLUE}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# Play animation
draw_frame1

for frame_fn in draw_frame2 draw_frame3 draw_frame4 draw_frame5; do
  printf "\033[${FRAME_LINES}A\033[0G"
  "$frame_fn"
  sleep "$DELAY"
done

sleep 0.7

# Clean up
printf "\033[${FRAME_LINES}A\033[0G"
for ((i=0; i<FRAME_LINES; i++)); do
  printf "\033[2K\n"
done
printf "\033[${FRAME_LINES}A\033[0G"

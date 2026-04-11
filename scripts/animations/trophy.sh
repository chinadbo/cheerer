#!/bin/bash
# trophy.sh — Trophy celebration pixel animation
# 5 frames: spotlight → trophy slides in → shine → sparkles → celebration
# Canvas: 10 rows × 22 chars (with border)

RESET="\033[0m"
YELLOW="\033[38;5;226m"
WHITE="\033[97m"
CYAN="\033[96m"
GRAY="\033[90m"
BOLD="\033[1m"
MAGENTA="\033[35m"

tput civis 2>/dev/null || true
trap 'tput cnorm 2>/dev/null || true' EXIT

DELAY=0.22
FRAME_LINES=10

draw_frame1() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${WHITE}  ║       |          ║${RESET}\n" \
"${WHITE}  ║      / \\         ║${RESET}\n" \
"${WHITE}  ║     /   \\        ║${RESET}\n" \
"${WHITE}  ║    /spotlight\\   ║${RESET}\n" \
"${WHITE}  ║   /_________ \\   ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame2() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${YELLOW}${BOLD}  ║      ╔═══╗      ║${RESET}\n" \
"${YELLOW}${BOLD}  ║      ║ 1st║      ║${RESET}\n" \
"${YELLOW}${BOLD}  ║      ╚═╤═╝      ║${RESET}\n" \
"${YELLOW}  ║       ──┘        ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame3() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${WHITE}  ║     ✦            ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${YELLOW}${BOLD}  ║      ╔═══╗      ║${RESET}\n" \
"${YELLOW}${BOLD}  ║   ✦  ║1ST║  ✦   ║${RESET}\n" \
"${YELLOW}${BOLD}  ║      ╚═╤═╝      ║${RESET}\n" \
"${YELLOW}  ║       ──┘   ✦   ║${RESET}\n" \
"${WHITE}  ║  ✦          ✦    ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame4() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${CYAN}  ║  ✦    ✦   ✦  ✦   ║${RESET}\n" \
"${YELLOW}${BOLD}  ║      ╔═══╗      ║${RESET}\n" \
"${WHITE}${BOLD}  ║   ✦  ║1ST║  ✦   ║${RESET}\n" \
"${YELLOW}${BOLD}  ║      ╚═╤═╝      ║${RESET}\n" \
"${CYAN}  ║  ✦    ──┘    ✦   ║${RESET}\n" \
"${CYAN}  ║    ✦     ✦      ║${RESET}\n" \
"${WHITE}  ║  ✦           ✦   ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame5() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${CYAN}  ║ ✦  ✦  ✦  ✦  ✦   ║${RESET}\n" \
"${YELLOW}${BOLD}  ║    ╔═══════╗     ║${RESET}\n" \
"${WHITE}${BOLD}  ║ ✦  ║ 🏆1ST║ ✦   ║${RESET}\n" \
"${YELLOW}${BOLD}  ║    ╚═══╤═══╝    ║${RESET}\n" \
"${MAGENTA}${BOLD}  ║   🎉 CHAMPION 🎉║${RESET}\n" \
"${CYAN}  ║ ✦  ──┘  ✦  ✦   ║${RESET}\n" \
"${CYAN}  ║  ✦    ✦    ✦    ║${RESET}\n" \
"${CYAN}  ║ ✦  ✦  ✦  ✦  ✦  ║${RESET}\n" \
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

#!/bin/bash
# fireworks.sh — 烟花绽放像素动画
# 5帧主体（发射→上升→爆炸初始→全开→消散），总时长约 2.4 秒
# 画布：10行 × 22字符（含边框）

RESET="\033[0m"
RED="\033[31m"
YELLOW="\033[38;5;226m"
GREEN="\033[32m"
CYAN="\033[96m"
MAGENTA="\033[35m"
WHITE="\033[97m"
BLUE="\033[34m"
BOLD="\033[1m"
GRAY="\033[90m"

# 隐藏光标，退出时恢复
tput civis 2>/dev/null || true
trap 'tput cnorm 2>/dev/null || true' EXIT

DELAY=0.22
FRAME_LINES=11

# ── 帧1：发射阶段 ──────────────────────────────────────
draw_frame1() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║        |         ║${RESET}\n" \
"${RED}${BOLD}  ║        *         ║${RESET}\n" \
"${YELLOW}  ║        |         ║${RESET}\n" \
"${YELLOW}  ║        |         ║${RESET}\n" \
"${GRAY}  ║        .         ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# ── 帧2：上升阶段 ──────────────────────────────────────
draw_frame2() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${RED}${BOLD}  ║        *         ║${RESET}\n" \
"${YELLOW}  ║        |         ║${RESET}\n" \
"${YELLOW}  ║        |         ║${RESET}\n" \
"${GRAY}  ║        .         ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# ── 帧3：爆炸初始（8方向射线） ─────────────────────────
draw_frame3() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${YELLOW}${BOLD}  ║      \\ | /       ║${RESET}\n" \
"${RED}${BOLD}  ║     - ★ -        ║${RESET}\n" \
"${YELLOW}${BOLD}  ║      / | \\       ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# ── 帧4：全开！多色绽放 ────────────────────────────────
draw_frame4() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${CYAN}  ║  *   \\ ✦ /   *   ║${RESET}\n" \
"${MAGENTA}  ║   \\   \\|/   /    ║${RESET}\n" \
"${YELLOW}${BOLD}  ║ * - -★★★- - *   ║${RESET}\n" \
"${GREEN}  ║   /   /|\\   \\    ║${RESET}\n" \
"${RED}  ║  *   / ✦ \\   *   ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${WHITE}${BOLD}  ║  🎆 AWESOME! 🎆  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# ── 帧5：消散阶段（余烬飘落） ──────────────────────────
draw_frame5() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${YELLOW}  ║    .    *    .   ║${RESET}\n" \
"${RED}  ║  .    .   .    . ║${RESET}\n" \
"${CYAN}  ║    .   ✦   .     ║${RESET}\n" \
"${GREEN}  ║  .   .   .   .   ║${RESET}\n" \
"${MAGENTA}  ║    .       .     ║${RESET}\n" \
"${BLUE}  ║  .   .   .   .   ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# ── 播放动画 ──────────────────────────────────────────
echo ""
draw_frame1
echo ""

# 播放序列：1→2→3→4→5→4（6帧，总时长约 1.32s + 0.6s 停留 = 1.92s）
for frame_fn in draw_frame1 draw_frame2 draw_frame3 draw_frame4 draw_frame5 draw_frame4; do
  printf "\033[${FRAME_LINES}A\033[0G"
  "$frame_fn"
  echo ""
  sleep "$DELAY"
done

# 最后停留 0.6 秒展示全开帧
sleep 0.6

# 清除动画区域，不留残影
printf "\033[${FRAME_LINES}A\033[0G"
for ((i=0; i<FRAME_LINES; i++)); do
  printf "\033[2K\n"
done
printf "\033[${FRAME_LINES}A\033[0G"

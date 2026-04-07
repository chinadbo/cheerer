#!/bin/bash
# dance.sh — 二次元跳舞像素动画
# 4帧主体 + 重复循环，总时长约 2.5 秒
# 画布：10行 × 22字符（含边框）

RESET="\033[0m"
PINK="\033[38;5;213m"
CYAN="\033[96m"
YELLOW="\033[38;5;226m"
MAGENTA="\033[35m"
BOLD="\033[1m"
GRAY="\033[90m"

# 隐藏光标，退出时恢复
tput civis 2>/dev/null || true
trap 'tput cnorm 2>/dev/null || true' EXIT

DELAY=0.2
FRAME_LINES=11

# ── 帧1：初始姿势，双臂水平 ────────────────────────────
draw_frame1() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${CYAN}  ║  ♪              ♫ ║${RESET}\n" \
"${PINK}${BOLD}  ║      (•‿•)       ║${RESET}\n" \
"${PINK}  ║    ───┼───       ║${RESET}\n" \
"${PINK}  ║       |          ║${RESET}\n" \
"${PINK}  ║      / \\         ║${RESET}\n" \
"${CYAN}  ║ ♫              ♪  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# ── 帧2：左摆，左臂上扬 ────────────────────────────────
draw_frame2() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${CYAN}  ║ ♪               ♫ ║${RESET}\n" \
"${PINK}${BOLD}  ║      (^‿^)       ║${RESET}\n" \
"${PINK}  ║   /──┼──         ║${RESET}\n" \
"${PINK}  ║      |\\          ║${RESET}\n" \
"${PINK}  ║     /  \\         ║${RESET}\n" \
"${CYAN}  ║  ♫             ♪  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# ── 帧3：右摆，右臂上扬 ────────────────────────────────
draw_frame3() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${CYAN}  ║  ♫              ♪ ║${RESET}\n" \
"${PINK}${BOLD}  ║      (*‿*)       ║${RESET}\n" \
"${PINK}  ║      ─┼──\\       ║${RESET}\n" \
"${PINK}  ║      /|           ║${RESET}\n" \
"${PINK}  ║     /  \\          ║${RESET}\n" \
"${CYAN}  ║ ♪               ♫ ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# ── 帧4：跳跃！双臂张开，离地 ──────────────────────────
draw_frame4() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${YELLOW}${BOLD}  ║    ★(≧▽≦)★       ║${RESET}\n" \
"${PINK}${BOLD}  ║   /  (^o^)  \\     ║${RESET}\n" \
"${PINK}  ║  /    \\|/    \\    ║${RESET}\n" \
"${PINK}  ║        |          ║${RESET}\n" \
"${GRAY}  ║    ~  ~ ~  ~      ║${RESET}\n" \
"${MAGENTA}${BOLD}  ║   🎵 DANCE!! 🎵   ║${RESET}\n" \
"${CYAN}  ║  ♪  ♫  ♪  ♫  ♪   ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# ── 播放动画 ──────────────────────────────────────────
echo ""
draw_frame1
echo ""

# 播放序列：1→2→3→2→3→4（6帧，总时长约 1.2s + 0.6s 停留 = 1.8s）
for frame_fn in draw_frame1 draw_frame2 draw_frame3 draw_frame2 draw_frame3 draw_frame4; do
  printf "\033[${FRAME_LINES}A\033[0G"
  eval "$frame_fn"
  echo ""
  sleep "$DELAY"
done

# 最后停留 0.6 秒让用户看到跳跃帧
sleep 0.6

# 清除动画区域，不留残影
printf "\033[${FRAME_LINES}A\033[0G"
for ((i=0; i<FRAME_LINES; i++)); do
  printf "\033[2K\n"
done
printf "\033[${FRAME_LINES}A\033[0G"

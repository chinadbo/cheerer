#!/bin/bash
# basketball.sh — 投篮像素动画
# 使用 ANSI escape code 实现帧动画，时长约 2.5 秒

# ── ANSI 颜色定义 ─────────────────────────────────────
RESET="\033[0m"
ORANGE="\033[38;5;208m"
YELLOW="\033[38;5;226m"
WHITE="\033[97m"
CYAN="\033[96m"
GRAY="\033[90m"
BOLD="\033[1m"

# 隐藏光标
tput civis 2>/dev/null || true
# 退出时恢复光标
trap 'tput cnorm 2>/dev/null || true' EXIT

FRAME_LINES=10

# ── 帧定义（10行 × 24列）────────────────────────────
# 篮框在右上角，球从左下弧线飞入

# 使用纯 ANSI 字符重绘，确保终端兼容
draw_frame1() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${ORANGE}${BOLD}  ║  ●               ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${YELLOW}  ║            ┌─┐   ║${RESET}\n" \
"${YELLOW}  ║            │ │   ║${RESET}\n" \
"${YELLOW}  ║           ─┘ └─  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame2() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${ORANGE}${BOLD}  ║      ●           ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${YELLOW}  ║            ┌─┐   ║${RESET}\n" \
"${YELLOW}  ║            │ │   ║${RESET}\n" \
"${YELLOW}  ║           ─┘ └─  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame3() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${ORANGE}${BOLD}  ║          ●       ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${YELLOW}  ║            ┌─┐   ║${RESET}\n" \
"${YELLOW}  ║            │ │   ║${RESET}\n" \
"${YELLOW}  ║           ─┘ └─  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame4() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${ORANGE}${BOLD}  ║              ●   ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${YELLOW}  ║            ┌─┐   ║${RESET}\n" \
"${YELLOW}  ║            │ │   ║${RESET}\n" \
"${YELLOW}  ║           ─┘ └─  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# 球入框帧
draw_frame5() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${YELLOW}  ║            ┌${ORANGE}●${YELLOW}┐   ║${RESET}\n" \
"${YELLOW}  ║            │ │   ║${RESET}\n" \
"${YELLOW}  ║           ─┘ └─  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# 进球！撒花帧
draw_frame6() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${CYAN}  ║  ✨    ✨    ✨   ║${RESET}\n" \
"${CYAN}  ║    🌟      🌟    ║${RESET}\n" \
"${WHITE}${BOLD}  ║    🎉 SCORE! 🎉  ║${RESET}\n" \
"${CYAN}  ║    🌟      🌟    ║${RESET}\n" \
"${CYAN}  ║  ✨    ✨    ✨   ║${RESET}\n" \
"${YELLOW}  ║            ┌─┐   ║${RESET}\n" \
"${ORANGE}  ║            │●│   ║${RESET}\n" \
"${YELLOW}  ║           ─┘ └─  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# ── 播放动画 ─────────────────────────────────────────
# 先绘制第一帧
draw_frame1

DELAY=0.18

# 帧循环（从第二帧开始，每帧先回退再绘制）
for frame_fn in draw_frame2 draw_frame3 draw_frame4 draw_frame5 draw_frame6; do
  # 回到帧起始位置
  printf "\033[${FRAME_LINES}A\033[0G"
  "$frame_fn"
  sleep "$DELAY"
done

# 最后停留 0.8 秒让用户看到进球效果
sleep 0.8

# 清除动画区域，恢复原始位置
printf "\033[${FRAME_LINES}A\033[0G"
for ((i=0; i<FRAME_LINES; i++)); do
  printf "\033[2K\n"
done
printf "\033[${FRAME_LINES}A\033[0G"

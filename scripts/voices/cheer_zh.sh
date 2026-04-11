#!/bin/bash
# cheer_zh.sh — 中文语音鼓励
# 优先 macOS say → espeak → 打印文字
# 语音受 CHEERER_VOICE 环境变量控制（on/off/true/false）
# CHEERER_DUMB=true 时不输出任何 ANSI escape code
# 消息来自 CHEERER_MESSAGE（由 render_emit 从目录选取）

if [[ -n "${CHEERER_MESSAGE:-}" ]]; then
  MSG="$CHEERER_MESSAGE"
else
  MSG="干得漂亮！任务完成。"
fi

CHEERER_DUMB="${CHEERER_DUMB:-false}"
if [[ "$CHEERER_DUMB" == "true" ]]; then
  echo "🎉 $MSG"
else
  printf '\033[1;32m🎉 %s\033[0m\n' "$MSG"
fi

CHEERER_VOICE="${CHEERER_VOICE:-on}"
if [[ "$CHEERER_VOICE" == "off" ]] || [[ "$CHEERER_VOICE" == "false" ]]; then
  exit 0
fi

if command -v say >/dev/null 2>&1; then
  say -v "Ting-Ting" "$MSG" >/dev/null 2>&1 & disown
elif command -v espeak >/dev/null 2>&1; then
  espeak -v zh "$MSG" >/dev/null 2>&1 & disown
fi

exit 0

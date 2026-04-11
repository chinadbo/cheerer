#!/bin/bash
# cheer_ja.sh — 日本語ボイス応援
# 優先度: macOS say → espeak → テキストのみ
# 音声は CHEERER_VOICE 環境変量で制御（on/off/true/false）
# CHEERER_DUMB=true 時は ANSI escape code を出力しない
# メッセージは CHEERER_MESSAGE から取得（render_emit がカタログから選択）

if [[ -n "${CHEERER_MESSAGE:-}" ]]; then
  MSG="$CHEERER_MESSAGE"
else
  MSG="お見事です！タスク完了。"
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
  say -v "Kyoko" "$MSG" >/dev/null 2>&1 & disown
elif command -v espeak >/dev/null 2>&1; then
  espeak -v ja "$MSG" >/dev/null 2>&1 & disown
fi

exit 0

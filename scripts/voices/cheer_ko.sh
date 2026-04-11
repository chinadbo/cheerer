#!/bin/bash
# cheer_ko.sh — 한국어 음성 응원
# 우선순위: macOS say → espeak → 텍스트만
# CHEERER_VOICE로 제어 (on/off/true/false)
# CHEERER_DUMB=true 시 ANSI escape code 미출력
# 메시지는 CHEERER_MESSAGE에서 가져옴 (render_emit이 카탈로그에서 선택)

if [[ -n "${CHEERER_MESSAGE:-}" ]]; then
  MSG="$CHEERER_MESSAGE"
else
  MSG="잘하셨어요! 작업 완료."
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
  say -v "Yuna" "$MSG" >/dev/null 2>&1 & disown
elif command -v espeak >/dev/null 2>&1; then
  espeak -v ko "$MSG" >/dev/null 2>&1 & disown
fi

exit 0

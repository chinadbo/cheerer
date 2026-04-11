#!/bin/bash
# cheer.sh — Shared voice script for all languages
# Called by language-specific wrappers (cheer_zh.sh, cheer_en.sh, etc.)
# Uses CHEERER_LANG to select voice name and fallback message.

_msg="${CHEERER_MESSAGE:-}"

# Fallback messages per language when CHEERER_MESSAGE is not set
if [[ -z "$_msg" ]]; then
  case "${CHEERER_LANG:-zh}" in
    zh) _msg="干得漂亮！任务完成。" ;;
    en) _msg="Great work. Task complete." ;;
    ja) _msg="お見事です！タスク完了。" ;;
    ko) _msg="잘하셨어요! 작업 완료." ;;
    es) _msg="¡Buen trabajo! Tarea completada." ;;
    *)  _msg="Great work. Task complete." ;;
  esac
fi

CHEERER_DUMB="${CHEERER_DUMB:-false}"
if [[ "$CHEERER_DUMB" == "true" ]]; then
  echo "🎉 $_msg"
else
  printf '\033[1;32m🎉 %s\033[0m\n' "$_msg"
fi

CHEERER_VOICE="${CHEERER_VOICE:-on}"
if [[ "$CHEERER_VOICE" == "off" ]] || [[ "$CHEERER_VOICE" == "false" ]]; then
  exit 0
fi

# Voice name mapping
case "${CHEERER_LANG:-zh}" in
  zh) _voice="Ting-Ting"; _espeak="zh" ;;
  en) _voice="Samantha";  _espeak="en" ;;
  ja) _voice="Kyoko";     _espeak="ja" ;;
  ko) _voice="Yuna";      _espeak="ko" ;;
  es) _voice="Monica";    _espeak="es" ;;
  *)  _voice="Samantha";  _espeak="en" ;;
esac

if command -v say >/dev/null 2>&1; then
  say -v "$_voice" "$_msg" >/dev/null 2>&1 & disown
elif command -v espeak >/dev/null 2>&1; then
  espeak -v "$_espeak" "$_msg" >/dev/null 2>&1 & disown
fi

exit 0

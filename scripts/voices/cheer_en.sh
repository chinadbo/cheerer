#!/bin/bash
# cheer_en.sh — English voice cheers
# Priority: macOS say → espeak → text only
# Voice controlled by CHEERER_VOICE env var (on/off/true/false)
# CHEERER_DUMB=true disables all ANSI escape codes
# Message comes from CHEERER_MESSAGE (set by render_emit from catalog)

if [[ -n "${CHEERER_MESSAGE:-}" ]]; then
  MSG="$CHEERER_MESSAGE"
else
  MSG="Great work. Task complete."
fi

CHEERER_DUMB="${CHEERER_DUMB:-false}"
if [[ "$CHEERER_DUMB" == "true" ]]; then
  echo "🎉 $MSG"
else
  echo -e "\033[1;32m🎉 $MSG\033[0m"
fi

CHEERER_VOICE="${CHEERER_VOICE:-on}"
if [[ "$CHEERER_VOICE" == "off" ]] || [[ "$CHEERER_VOICE" == "false" ]]; then
  exit 0
fi

if command -v say >/dev/null 2>&1; then
  say -v "Samantha" "$MSG" >/dev/null 2>&1 & disown
elif command -v espeak >/dev/null 2>&1; then
  espeak -v en "$MSG" >/dev/null 2>&1 & disown
fi

exit 0

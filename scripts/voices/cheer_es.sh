#!/bin/bash
# cheer_es.sh — Voces de ánimo en español
# Prioridad: macOS say → espeak → solo texto
# Controlado por CHEERER_VOICE (on/off/true/false)
# CHEERER_DUMB=true desactiva códigos ANSI
# Mensaje desde CHEERER_MESSAGE (seleccionado por render_emit del catálogo)

if [[ -n "${CHEERER_MESSAGE:-}" ]]; then
  MSG="$CHEERER_MESSAGE"
else
  MSG="¡Buen trabajo! Tarea completada."
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
  say -v "Monica" "$MSG" >/dev/null 2>&1 & disown
elif command -v espeak >/dev/null 2>&1; then
  espeak -v es "$MSG" >/dev/null 2>&1 & disown
fi

exit 0

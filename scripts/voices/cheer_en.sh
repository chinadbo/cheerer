#!/bin/bash
# cheer_en.sh — English voice cheers
# Priority: macOS say → espeak → text only
# Voice controlled by CHEERER_VOICE env var (on/off/true/false)
# CHEERER_DUMB=true disables all ANSI escape codes
#
# Style: tech recognition + programmer humor
# Rule: every message must contain a tech-specific word or programmer meme

MESSAGES=(
  # Tech recognition (1-5)
  "Shipped it like a boss! Another commit in the books!"
  "Bug terminated. Mission complete. Codebase secured."
  "Tests are green, pipeline is clean — you're a machine!"
  "That refactor was clean. Technical debt just took an L."
  "PR merged. The diff gods are pleased with your offering."
  # Programmer humor (6-10)
  "You just turned undefined behavior into defined awesomeness!"
  "Stack trace? More like trophy case at this point!"
  "Another TODO crossed off. The backlog weeps with joy."
  "Code review passed — reviewers couldn't find a single nit. Legendary."
  "Your function is so elegant, the compiler wants to frame it."
  # Bonus (11-13)
  "Commit pushed. History remembers the greats. You are one."
  "Segmentation fault? Never heard of her. Not on your watch."
  "Zero warnings, zero errors. Your compiler is proud of you."
)

MSG="${MESSAGES[$((RANDOM % ${#MESSAGES[@]}))]}"

# Output text cheer (no ANSI in dumb terminal mode)
CHEERER_DUMB="${CHEERER_DUMB:-false}"
if [[ "$CHEERER_DUMB" == "true" ]]; then
  echo "🎉 $MSG"
else
  echo -e "\033[1;32m🎉 $MSG\033[0m"
fi

# Voice playback (controlled by CHEERER_VOICE, background exec, fails silently)
CHEERER_VOICE="${CHEERER_VOICE:-on}"
if [[ "$CHEERER_VOICE" == "off" ]] || [[ "$CHEERER_VOICE" == "false" ]]; then
  exit 0
fi

if command -v say >/dev/null 2>&1; then
  # macOS: background exec, non-blocking (ADR-002)
  say -v "Samantha" "$MSG" >/dev/null 2>&1 & disown
elif command -v espeak >/dev/null 2>&1; then
  # Linux espeak: background exec
  espeak -v en "$MSG" >/dev/null 2>&1 & disown
fi
# Other platforms: text only (already echoed above)

exit 0

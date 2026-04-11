#!/bin/bash
# animation.sh — Danmaku (bullet-screen) engine for cheerer
# Each animation theme sets DANMAKU_* arrays then calls anim_danmaku_run.
# Streams scroll right-to-left at configurable rows, speeds, and delays.
# The main message (CHEERER_MESSAGE) floats as the prominent center stream.

anim_term_width() {
  tput cols 2>/dev/null || echo 80
}

# Draw one frame of the danmaku animation.
# Reads DANMAKU_* arrays and _ANIM_FRAME counter.
anim_danmaku_draw() {
  local i row pos text color text_len start_frame
  local n="${#DANMAKU_ROW[@]}"

  # Move cursor to top of animation area
  printf '\033[%sA\033[0G' "$DANMAKU_ROWS"

  for ((row=1; row<=DANMAKU_ROWS; row++)); do
    printf '\033[2K'

    # Find the best visible stream on this row (rightmost wins)
    local best_pos=-999 best_idx=-1
    for ((i=0; i<n; i++)); do
      [[ "${DANMAKU_ROW[$i]}" -eq "$row" ]] || continue
      start_frame="${DANMAKU_DELAY[$i]:-0}"
      [[ "$_ANIM_FRAME" -ge "$start_frame" ]] || continue

      pos=$(( ANIM_TERM_WIDTH - (_ANIM_FRAME - start_frame) * ${DANMAKU_SPEED[$i]:-2} ))
      text_len="${#DANMAKU_TEXT[$i]}"

      [[ $((pos + text_len)) -ge 1 ]] || continue
      [[ "$pos" -le "$ANIM_TERM_WIDTH" ]] || continue

      if [[ "$pos" -gt "$best_pos" ]]; then
        best_pos="$pos"
        best_idx="$i"
      fi
    done

    if [[ "$best_idx" -ge 0 ]]; then
      text="${DANMAKU_TEXT[$best_idx]}"
      color="${DANMAKU_COLOR[$best_idx]}"
      text_len="${#text}"

      local _RESET=$'\033[0m'
      if [[ "$best_pos" -ge 1 ]]; then
        printf '%*s%s%s%s' "$((best_pos - 1))" "" "$color" "$text" "$_RESET"
      elif [[ $((best_pos + text_len)) -ge 1 ]]; then
        local clip=$((1 - best_pos))
        printf '%s%s%s' "$color" "${text:$clip}" "$_RESET"
      fi
    fi

    printf '\n'
  done
}

# Cleanup: clear animation area, restore cursor
anim_cleanup() {
  printf '\033[%sA\033[0G' "$DANMAKU_ROWS"
  local _i
  for ((_i=1; _i<=DANMAKU_ROWS; _i++)); do
    printf '\033[2K\n'
  done
  printf '\033[%sA\033[0G' "$DANMAKU_ROWS"
  tput cnorm 2>/dev/null || true
}

# Main animation loop.
# Theme must set before calling:
#   DANMAKU_ROWS    — number of terminal rows to use (e.g. 6)
#   DANMAKU_TICK    — seconds between frames (e.g. "0.07")
#   DANMAKU_FRAMES  — total animation frames (e.g. 30)
#   DANMAKU_ROW[i]  — row number (1-based) for stream i
#   DANMAKU_TEXT[i] — display text for stream i
#   DANMAKU_COLOR[i]— ANSI color code for stream i
#   DANMAKU_SPEED[i]— columns to move left per frame
#   DANMAKU_DELAY[i]— frames to wait before stream appears
anim_danmaku_run() {
  local tick="${DANMAKU_TICK:-0.07}"
  local total="${DANMAKU_FRAMES:-28}"
  _ANIM_FRAME=0

  ANIM_TERM_WIDTH="$(anim_term_width)"
  DANMAKU_ROWS="${DANMAKU_ROWS:-6}"

  tput civis 2>/dev/null || true
  trap 'anim_cleanup' EXIT

  # Create animation area (blank rows)
  local _i
  for ((_i=1; _i<=DANMAKU_ROWS; _i++)); do
    printf '\n'
  done

  while [[ "$_ANIM_FRAME" -lt "$total" ]]; do
    anim_danmaku_draw
    sleep "$tick"
    _ANIM_FRAME=$((_ANIM_FRAME + 1))
  done
}

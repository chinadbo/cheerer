#!/bin/bash
# animation.sh — Danmaku (bullet-screen) engine for cheerer
# Each animation theme sets DANMAKU_* arrays then calls anim_danmaku_run.
# Streams scroll right-to-left at configurable rows, speeds, and delays.
# The main message (CHEERER_MESSAGE) floats as the prominent center stream.
#
# Required: must be sourced into a fresh subprocess (bash "$theme.sh"),
# never sourced into a long-lived shell. Each theme invocation via
# render.sh provides process isolation.

anim_term_width() {
  tput cols 2>/dev/null || echo 80
}

# Approximate display width: ASCII = 1 col, non-ASCII (emoji, CJK) = 2 cols.
# Handles the common emoji/CJK case; combining characters not fully supported.
anim_display_width() {
  local text="$1" width=0 i=0 char_len
  while ((i < ${#text})); do
    char_len=$(LC_ALL=C printf '%s' "${text:$i:1}" | wc -c)
    char_len="${char_len##* }"
    if ((char_len == 1)); then
      ((width++))    # ASCII = 1 column
    elif ((char_len == 2)); then
      ((width++))    # 2-byte UTF-8 (Latin extended: é ñ ü) = 1 column
    elif ((char_len == 3)); then
      ((width+=2))   # 3-byte UTF-8 (CJK, Hangul) = 2 columns
    else
      ((width+=2))   # 4-byte UTF-8 (emoji) = 2 columns
    fi
    ((i++))
  done
  printf '%d' "$width"
}

# Sanitize user-supplied message: strip control chars (ESC, newlines, etc.)
anim_sanitize_msg() {
  local raw="$1"
  # Remove C0 control chars (0x01-0x1F) including ESC, newline, CR
  printf '%s' "$raw" | tr -d '\001-\037'
}

# Draw one frame of the danmaku animation.
# Reads DANMAKU_* arrays and _ANIM_FRAME counter.
# NOTE: only one stream is rendered per row per frame (rightmost visible wins).
# Assign distinct rows to streams to avoid invisible streams.
anim_danmaku_draw() {
  local i row pos text color disp_len start_frame
  local n="${#DANMAKU_ROW[@]}"

  # Move cursor to top of animation area
  printf '\033[%sA\033[1G' "$DANMAKU_ROWS"

  for ((row=1; row<=DANMAKU_ROWS; row++)); do
    printf '\033[2K'

    # Find the best visible stream on this row (rightmost wins)
    local best_pos=-999 best_idx=-1
    for ((i=0; i<n; i++)); do
      [[ "${DANMAKU_ROW[$i]}" -eq "$row" ]] || continue
      start_frame="${DANMAKU_DELAY[$i]:-0}"
      [[ "$_ANIM_FRAME" -ge "$start_frame" ]] || continue

      pos=$(( ANIM_TERM_WIDTH - (_ANIM_FRAME - start_frame) * ${DANMAKU_SPEED[$i]:-2} ))
      disp_len="$(anim_display_width "${DANMAKU_TEXT[$i]}")"

      [[ $((pos + disp_len)) -ge 1 ]] || continue
      [[ "$pos" -le "$ANIM_TERM_WIDTH" ]] || continue

      if [[ "$pos" -gt "$best_pos" ]]; then
        best_pos="$pos"
        best_idx="$i"
      fi
    done

    if [[ "$best_idx" -ge 0 ]]; then
      text="${DANMAKU_TEXT[$best_idx]}"
      color="${DANMAKU_COLOR[$best_idx]}"
      disp_len="$(anim_display_width "$text")"

      local _RESET=$'\033[0m'
      if [[ "$best_pos" -ge 1 ]]; then
        printf '%*s%s%s%s' "$((best_pos - 1))" "" "$color" "$text" "$_RESET"
      elif [[ $((best_pos + disp_len)) -ge 1 ]]; then
        local clip=$((1 - best_pos))
        printf '%s%s%s' "$color" "${text:$clip}" "$_RESET"
      fi
    fi

    printf '\n'
  done
}

# Cleanup: clear animation area, restore cursor and terminal attributes
anim_cleanup() {
  printf '\033[0m'  # reset all attributes unconditionally
  local rows="${DANMAKU_ROWS:-6}"
  printf '\033[%sA\033[1G' "$rows"
  local _i
  for ((_i=1; _i<=rows; _i++)); do
    printf '\033[2K\n'
  done
  printf '\033[%sA\033[1G' "$rows"
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
  local total="${DANMAKU_FRAMES:-30}"
  if [[ "${CHEERER_ANIM_DURATION:-}" =~ ^[0-9]+$ ]] && [[ "$CHEERER_ANIM_DURATION" -ge 5 ]]; then
    total="$CHEERER_ANIM_DURATION"
  fi
  _ANIM_FRAME=0

  ANIM_TERM_WIDTH="$(anim_term_width)"
  DANMAKU_ROWS="${DANMAKU_ROWS:-6}"

  tput civis 2>/dev/null || true
  trap 'anim_cleanup' EXIT INT TERM

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

  # Explicit cleanup on normal completion, then clear the trap
  anim_cleanup
  trap - EXIT INT TERM
}

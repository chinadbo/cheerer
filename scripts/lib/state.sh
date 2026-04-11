#!/bin/bash

state_defaults() {
  STATS_TOTAL_TRIGGERS=0
  STATS_LAST_TRIGGER=""
  STATS_MILESTONES='[]'
}

state_write_stats() {
  local tmp="${STATS_FILE}.tmp.$$"
  printf '{"total_triggers":%s,"last_trigger":"%s","milestones":%s}\n' \
    "$STATS_TOTAL_TRIGGERS" "$STATS_LAST_TRIGGER" "$STATS_MILESTONES" > "$tmp"
  mv "$tmp" "$STATS_FILE"
}

state_read_stats() {
  local raw
  raw="$(cat "$STATS_FILE" 2>/dev/null || true)"
  STATS_TOTAL_TRIGGERS="$(printf '%s' "$raw" | grep -o '"total_triggers":[0-9]*' | cut -d: -f2)"
  STATS_LAST_TRIGGER="$(printf '%s' "$raw" | grep -o '"last_trigger":"[^"]*"' | cut -d'"' -f4)"
  STATS_MILESTONES="$(printf '%s' "$raw" | grep -o '"milestones":\[[^]]*\]' | cut -d: -f2-)"

  [[ "$STATS_TOTAL_TRIGGERS" =~ ^[0-9]+$ ]] || return 1
  [[ -n "${STATS_MILESTONES:-}" ]] || STATS_MILESTONES='[]'
  return 0
}

state_init() {
  mkdir -p "$CHEERER_DATA_DIR"
  HISTORY_FILE="${HISTORY_FILE:-$CHEERER_DATA_DIR/history.log}"
  STATS_FILE="${STATS_FILE:-$CHEERER_DATA_DIR/stats.json}"

  [[ -f "$HISTORY_FILE" ]] || : > "$HISTORY_FILE"

  if [[ ! -f "$STATS_FILE" ]]; then
    state_defaults
    state_write_stats
  elif ! state_read_stats; then
    state_defaults
    state_write_stats
  fi
}

state_record_trigger() {
  local now_iso="$1"
  local milestone

  state_read_stats || state_defaults
  STATS_TOTAL_TRIGGERS=$((STATS_TOTAL_TRIGGERS + 1))
  STATS_LAST_TRIGGER="$now_iso"
  STATE_MILESTONE_MSG=""

  for milestone in 10 25 50 100 250 500 1000; do
    if [[ "$STATS_TOTAL_TRIGGERS" -eq "$milestone" ]]; then
      if [[ "$STATS_MILESTONES" == "[]" ]]; then
        STATS_MILESTONES="[$milestone]"
      else
        STATS_MILESTONES="${STATS_MILESTONES%]},$milestone]"
      fi
      STATE_MILESTONE_MSG="🏆 Trigger #$milestone!"
      break
    fi
  done

  state_write_stats
}

state_append_history() {
  local timestamp="$1"
  local hook_event="$2"
  local task_duration="$3"
  local tier="$4"
  local mood="$5"
  local animation="$6"
  local message_id="$7"
  local tmp_file

  printf '%s|%s|%s|%s|%s|%s|%s\n' \
    "$timestamp" "$hook_event" "$task_duration" "$tier" "$mood" "$animation" "$message_id" >> "$HISTORY_FILE"

  tmp_file="${HISTORY_FILE}.tmp"
  tail -n 50 "$HISTORY_FILE" > "$tmp_file"
  mv "$tmp_file" "$HISTORY_FILE"
}

state_recent_count() {
  local since_ts="$1"
  local hook_filter="$2"
  local count=0
  local row_ts row_hook _rest

  while IFS='|' read -r row_ts row_hook _rest; do
    [[ -n "${row_ts:-}" ]] || continue
    [[ "$row_ts" -ge "$since_ts" ]] || continue
    if [[ "$hook_filter" == "any" ]] || [[ "$row_hook" == "$hook_filter" ]]; then
      count=$((count + 1))
    fi
  done < "$HISTORY_FILE"

  printf '%s' "$count"
}

state_recent_values_csv() {
  local field_index="$1"
  local limit="$2"

  tail -n "$limit" "$HISTORY_FILE" 2>/dev/null | cut -d'|' -f"$field_index" | paste -sd, -
}

state_compute_streak() {
  local streak=0 max_streak=0
  local row_ts row_hook _rest
  local thirty_min=$(( $(date +%s 2>/dev/null || echo 0) - 1800 ))

  while IFS='|' read -r row_ts row_hook _rest; do
    [[ -n "${row_ts:-}" ]] || continue
    [[ "$row_ts" -ge "$thirty_min" ]] || continue
    if [[ "$row_hook" == "TaskCompleted" ]]; then
      streak=$((streak + 1))
      [[ "$streak" -gt "$max_streak" ]] && max_streak="$streak"
    else
      streak=0
    fi
  done < "$HISTORY_FILE"

  printf '%s' "$max_streak"
}

state_daily_counts() {
  local days="${1:-7}"
  local i date_str count
  local row_ts row_hook _rest

  for i in $(seq $((days - 1)) -1 0); do
    date_str="$(date -v-${i}d +%Y-%m-%d 2>/dev/null || date -d "$i days ago" +%Y-%m-%d 2>/dev/null || echo "unknown")"
    count=0
    while IFS='|' read -r row_ts row_hook _rest; do
      [[ -n "${row_ts:-}" ]] || continue
      local row_date
      row_date="$(date -r "$row_ts" +%Y-%m-%d 2>/dev/null || date -d "@$row_ts" +%Y-%m-%d 2>/dev/null || echo "")"
      [[ "$row_date" == "$date_str" ]] || continue
      count=$((count + 1))
    done < "$HISTORY_FILE"
    printf '%s|%s\n' "$date_str" "$count"
  done
}

state_most_used() {
  local field_index="$1"
  local counts
  counts="$(mktemp "${TMPDIR:-/tmp}/cheerer_counts.XXXXXX")"

  cut -d'|' -f"$field_index" "$HISTORY_FILE" | sort | uniq -c | sort -rn > "$counts"
  head -1 "$counts" | awk '{print $2}'
  rm -f "$counts"
}

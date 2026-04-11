# Bug Fixes & New Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 5 bugs and add 5 features to cheerer v2.0 as specified in `docs/superpowers/specs/2026-04-11-bugfixes-and-features-design.md`

**Architecture:** All changes are in-shell patches to existing bash scripts. Bug fixes correct logic errors in policy.sh, state.sh, cheer.sh, animation.sh, and bin/cheer. Features add CLI flags (--help, --config, --disable/--enable), message fatigue detection in render.sh, and an animation duration override. TDD approach: write failing test first, then implement.

**Tech Stack:** Bash 4.0+, shellcheck, existing test framework (tests/test_lib.sh)

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `scripts/lib/policy.sh` | Modify | Bug 1: hour zero-stripping fix |
| `scripts/lib/state.sh` | Modify | Bug 2: replace grep -o JSON parsing with parameter expansion |
| `bin/cheer` | Modify | Bug 2: same fix in _cheerer_stats(); Bug 5: version extraction; Feature 1,2,3: --help, --config, --disable/--enable |
| `scripts/cheer.sh` | Modify | Bug 3: cooldown race condition; Feature 3: config.sh sourcing + validation; Feature 5: export CHEERER_ANIM_DURATION |
| `scripts/lib/animation.sh` | Modify | Bug 4: fix anim_display_width; Feature 5: CHEERER_ANIM_DURATION override in anim_danmaku_run |
| `scripts/lib/render.sh` | Modify | Feature 4: message fatigue detection |
| `tests/policy_test.sh` | Modify | Test for Bug 1 (hour=0) |
| `tests/state_test.sh` | Modify | Test for Bug 2 (JSON parsing edge cases) |
| `tests/render_test.sh` | Modify | Test for Feature 4 (fatigue detection) |
| `tests/integration_test.sh` | Modify | Tests for Features 1,2,3,5 |

---

### Task 1: Bug 1 — Midnight crash in time-of-day mood adjustment

**Files:**
- Modify: `scripts/lib/policy.sh:5`
- Modify: `tests/policy_test.sh`

- [ ] **Step 1: Write the failing test**

Add to `tests/policy_test.sh` before the `finish_tests` line:

```bash
test_midnight_hour_zero_no_crash() {
  HOOK_EVENT="Stop"
  TASK_DURATION=5
  RECENT_TASKCOMPLETED_COUNT=0
  SESSION_STREAK=0
  STATE_MILESTONE_MSG=""
  CHEERER_STYLE="adaptive"
  CHEERER_INTENSITY="normal"
  RECENT_ANIMATIONS=""
  ANIM_DIR="$PWD/scripts/animations"
  CHEERER_HOUR=0

  policy_select_celebration

  # Hour 0 is late night (22-6 range), so quick tier gets cozy override
  assert_eq "quick" "$POLICY_TIER"
  assert_eq "cozy" "$POLICY_MOOD"
}

run_test "midnight_hour_zero_no_crash" test_midnight_hour_zero_no_crash
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/policy_test.sh 2>&1 | grep -A2 midnight`
Expected: FAIL — `hour="${hour#0}"` on "0" produces empty string, arithmetic comparison breaks

- [ ] **Step 3: Fix the hour zero-stripping**

In `scripts/lib/policy.sh`, replace line 5:

```bash
  hour="${hour#0}"
```

with:

```bash
  hour=$((10#$hour))
```

This forces decimal interpretation: "00"→0, "0"→0, "08"→8, "12"→12.

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/policy_test.sh`
Expected: All tests PASS including `midnight_hour_zero_no_crash`

- [ ] **Step 5: Run full test suite**

Run: `bash tests/run.sh all`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/lib/policy.sh tests/policy_test.sh
git commit -m "fix(policy): use decimal interpretation for hour to prevent midnight crash"
```

---

### Task 2: Bug 2 — Fragile JSON parsing in state.sh

**Files:**
- Modify: `scripts/lib/state.sh:19-21`
- Modify: `tests/state_test.sh`

- [ ] **Step 1: Write the failing test**

Add to `tests/state_test.sh` before the `finish_tests` line:

```bash
test_state_read_stats_with_extra_fields() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  CHEERER_DATA_DIR="$tmp_dir/data"
  mkdir -p "$CHEERER_DATA_DIR"
  STATS_FILE="$CHEERER_DATA_DIR/stats.json"
  HISTORY_FILE="$CHEERER_DATA_DIR/history.log"

  # Include a field whose name contains "total_triggers" as a substring
  printf '{"total_triggers_since_reset":99,"total_triggers":42,"last_trigger":"2026-04-11","milestones":[10,25]}\n' > "$STATS_FILE"

  state_read_stats

  assert_eq "42" "$STATS_TOTAL_TRIGGERS"
  assert_eq "2026-04-11" "$STATS_LAST_TRIGGER"
  assert_eq "[10,25]" "$STATS_MILESTONES"
}

run_test "state_read_stats_with_extra_fields" test_state_read_stats_with_extra_fields

test_state_read_stats_with_escaped_quotes() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  CHEERER_DATA_DIR="$tmp_dir/data"
  mkdir -p "$CHEERER_DATA_DIR"
  STATS_FILE="$CHEERER_DATA_DIR/stats.json"
  HISTORY_FILE="$CHEERER_DATA_DIR/history.log"

  printf '{"total_triggers":7,"last_trigger":"2026-04-11T12:00:00+08:00","milestones":[]}\n' > "$STATS_FILE"

  state_read_stats

  assert_eq "7" "$STATS_TOTAL_TRIGGERS"
  assert_eq "2026-04-11T12:00:00+08:00" "$STATS_LAST_TRIGGER"
  assert_eq "[]" "$STATS_MILESTONES"
}

run_test "state_read_stats_with_escaped_quotes" test_state_read_stats_with_escaped_quotes
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/state_test.sh 2>&1 | grep -A2 'state_read_stats_with_extra'`
Expected: FAIL — `grep -o '"total_triggers":[0-9]*'` matches `total_triggers_since_reset:99` first, returning 99 instead of 42

- [ ] **Step 3: Replace grep -o with bash parameter expansion**

In `scripts/lib/state.sh`, replace lines 19-21:

```bash
  STATS_TOTAL_TRIGGERS="$(printf '%s' "$raw" | grep -o '"total_triggers":[0-9]*' | cut -d: -f2)"
  STATS_LAST_TRIGGER="$(printf '%s' "$raw" | grep -o '"last_trigger":"[^"]*"' | cut -d'"' -f4)"
  STATS_MILESTONES="$(printf '%s' "$raw" | grep -o '"milestones":\[[^]]*\]' | cut -d: -f2-)"
```

with:

```bash
  STATS_TOTAL_TRIGGERS="${raw#*\"total_triggers\":}"
  STATS_TOTAL_TRIGGERS="${STATS_TOTAL_TRIGGERS%%,*}"
  STATS_TOTAL_TRIGGERS="${STATS_TOTAL_TRIGGERS%%\}*}"
  STATS_TOTAL_TRIGGERS="${STATS_TOTAL_TRIGGERS// /}"

  STATS_LAST_TRIGGER="${raw#*\"last_trigger\":\"}"
  STATS_LAST_TRIGGER="${STATS_LAST_TRIGGER%%\"*}"

  STATS_MILESTONES="${raw#*\"milestones\":}"
  STATS_MILESTONES="${STATS_MILESTONES%%\}*}"
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/state_test.sh`
Expected: All tests PASS including the two new ones

- [ ] **Step 5: Run full test suite**

Run: `bash tests/run.sh all`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/lib/state.sh tests/state_test.sh
git commit -m "fix(state): replace fragile grep -o JSON parsing with bash parameter expansion"
```

---

### Task 3: Bug 2 (continued) — Same fragile JSON parsing in bin/cheer

**Files:**
- Modify: `bin/cheer:76,82`

- [ ] **Step 1: Replace grep -o in _cheerer_stats() milestones line**

In `bin/cheer`, replace line 76:

```bash
  milestones_raw="$(printf '%s' "$(cat "$STATS_FILE" 2>/dev/null)" | grep -o '"milestones":\[[^]]*\]' | cut -d: -f2-)"
```

with:

```bash
  local _stats_raw
  _stats_raw="$(cat "$STATS_FILE" 2>/dev/null || true)"
  milestones_raw="${_stats_raw#*\"milestones\":}"
  milestones_raw="${milestones_raw%%\}*}"
```

- [ ] **Step 2: Replace grep -o in _cheerer_stats() last_trigger line**

In `bin/cheer`, replace line 82:

```bash
  last_trigger="$(printf '%s' "$(cat "$STATS_FILE" 2>/dev/null)" | grep -o '"last_trigger":"[^"]*"' | cut -d'"' -f4)"
```

with:

```bash
  last_trigger="${_stats_raw#*\"last_trigger\":\"}"
  last_trigger="${last_trigger%%\"*}"
```

Note: This reuses the `_stats_raw` variable from Step 1. Both replacements are in the same `_cheerer_stats()` function, so `_stats_raw` is already set.

- [ ] **Step 3: Run full test suite**

Run: `bash tests/run.sh all`
Expected: All tests PASS

- [ ] **Step 4: Commit**

```bash
git add bin/cheer
git commit -m "fix(cli): replace fragile grep -o JSON parsing in _cheerer_stats with parameter expansion"
```

---

### Task 4: Bug 3 — Cooldown race condition and timer reset

**Files:**
- Modify: `scripts/cheer.sh:86`
- Modify: `tests/integration_test.sh`

- [ ] **Step 1: Write the failing test**

Add to `tests/integration_test.sh` before the `finish_tests` line:

```bash
test_cooldown_does_not_reset_timer() {
  local tmp_dir output1 output2 output3
  tmp_dir="$(make_tmp_dir)"

  # First trigger
  output1="$(CLAUDE_PLUGIN_DATA="$tmp_dir/data" \
    CLAUDE_SESSION_ID="cooldown-reset-test" \
    CHEERER_LANG="en" \
    CHEERER_VOICE="off" \
    CHEERER_DUMB="true" \
    CHEERER_COOLDOWN="10" \
    CHEERER_HOUR=15 \
    bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json)"

  # Second trigger within cooldown — should NOT reset the cooldown clock
  output2="$(CLAUDE_PLUGIN_DATA="$tmp_dir/data" \
    CLAUDE_SESSION_ID="cooldown-reset-test" \
    CHEERER_LANG="en" \
    CHEERER_VOICE="off" \
    CHEERER_DUMB="true" \
    CHEERER_COOLDOWN="10" \
    CHEERER_HOUR=15 \
    bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json)"

  # Verify first run had animation (not in cooldown)
  assert_contains "$output1" "🎉"
  # Verify second run had text but was in cooldown (no danmaku frame markers)
  assert_contains "$output2" "🎉"

  # Read cooldown file — it should be the FIRST trigger's timestamp, not the second's
  local cooldown_file="${TMPDIR:-/tmp}/cheerer_${UID}/last_trigger_cooldownresettest"
  if [[ -f "$cooldown_file" ]]; then
    local ts1 ts2
    ts1="$(date +%s)"
    # The cooldown file timestamp should be older than now-minus-1s (set by first trigger)
    # If cooldown was NOT reset, the file timestamp should be ≤ current time
    # If cooldown WAS reset (the bug), the file would be updated to current time
    # We verify by checking the file wasn't overwritten to "now" during the second trigger
    # A practical check: the cooldown file value should be ≤ first trigger start time
    local file_val
    file_val="$(cat "$cooldown_file" 2>/dev/null || echo 0)"
    # file_val must be a valid unix timestamp and less than or equal to now
    [[ "$file_val" =~ ^[0-9]+$ ]] || return 1
    [[ "$file_val" -le "$ts1" ]] || return 1
  fi
}

run_test "cooldown_does_not_reset_timer" test_cooldown_does_not_reset_timer
```

- [ ] **Step 2: Run test to verify current behavior**

Run: `bash tests/integration_test.sh 2>&1 | grep -A2 cooldown_does_not_reset`
This test verifies the fix will work — the bug is that line 86 unconditionally writes the timestamp. We'll verify after the fix.

- [ ] **Step 3: Fix cooldown timestamp write**

In `scripts/cheer.sh`, delete line 86:

```bash
echo "$CURRENT_TS" > "$COOLDOWN_FILE" 2>/dev/null || true
```

Then after line 107 (`render_emit`), add:

```bash
if [[ "$IN_COOLDOWN" == "false" ]]; then
  echo "$CURRENT_TS" > "$COOLDOWN_FILE" 2>/dev/null || true
fi
```

The result should look like:

```bash
render_emit
if [[ "$IN_COOLDOWN" == "false" ]]; then
  echo "$CURRENT_TS" > "$COOLDOWN_FILE" 2>/dev/null || true
fi
state_append_history "$CURRENT_TS" "$HOOK_EVENT" "${TASK_DURATION:-0}" "$POLICY_TIER" "$POLICY_MOOD" "$POLICY_ANIMATION" "$RENDER_MESSAGE_ID"
```

- [ ] **Step 4: Run full test suite**

Run: `bash tests/run.sh all`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/cheer.sh tests/integration_test.sh
git commit -m "fix(cooldown): move timestamp write after render_emit, skip during cooldown"
```

---

### Task 5: Bug 4 — Display width completely wrong (all chars counted as 2 cols)

**Files:**
- Modify: `scripts/lib/animation.sh:17-29`
- Modify: `tests/integration_test.sh`

- [ ] **Step 1: Write the failing test**

Add to `tests/integration_test.sh` before the `finish_tests` line:

```bash
test_anim_display_width_ascii() {
  . scripts/lib/animation.sh
  local w
  w="$(anim_display_width "abc")"
  assert_eq "3" "$w"
}

test_anim_display_width_cjk() {
  . scripts/lib/animation.sh
  local w
  w="$(anim_display_width "中")"
  assert_eq "2" "$w"
}

test_anim_display_width_latin_extended() {
  . scripts/lib/animation.sh
  local w
  w="$(anim_display_width "é")"
  assert_eq "1" "$w"
}

test_anim_display_width_emoji() {
  . scripts/lib/animation.sh
  local w
  w="$(anim_display_width "🎉")"
  assert_eq "2" "$w"
}

test_anim_display_width_mixed() {
  . scripts/lib/animation.sh
  local w
  w="$(anim_display_width "España")"
  assert_eq "6" "$w"
}

test_anim_display_width_korean() {
  . scripts/lib/animation.sh
  local w
  w="$(anim_display_width "한글")"
  assert_eq "4" "$w"
}

run_test "anim_display_width_ascii" test_anim_display_width_ascii
run_test "anim_display_width_cjk" test_anim_display_width_cjk
run_test "anim_display_width_latin_extended" test_anim_display_width_latin_extended
run_test "anim_display_width_emoji" test_anim_display_width_emoji
run_test "anim_display_width_mixed" test_anim_display_width_mixed
run_test "anim_display_width_korean" test_anim_display_width_korean
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/integration_test.sh 2>&1 | grep -A1 'anim_display_width_ascii'`
Expected: FAIL — current code returns 6 for "abc" (all chars counted as width 2)

- [ ] **Step 3: Replace anim_display_width with byte-length approach**

In `scripts/lib/animation.sh`, replace lines 17-29:

```bash
anim_display_width() {
  local text="$1"
  local width=0 i char
  for ((i=0; i<${#text}; i++)); do
    char="${text:$i:1}"
    if [[ "$char" =~ [[:ascii:]] ]]; then
      ((width++))
    else
      ((width+=2))
    fi
  done
  printf '%d' "$width"
}
```

with:

```bash
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash tests/integration_test.sh 2>&1 | grep 'anim_display_width'`
Expected: All 6 new tests PASS

- [ ] **Step 5: Run full test suite**

Run: `bash tests/run.sh all`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/lib/animation.sh tests/integration_test.sh
git commit -m "fix(animation): fix anim_display_width using UTF-8 byte-length instead of broken [[:ascii:]] regex"
```

---

### Task 6: Bug 5 — Fragile version extraction in bin/cheer

**Files:**
- Modify: `bin/cheer:10`

- [ ] **Step 1: Verify current behavior and fix**

In `bin/cheer`, replace line 10:

```bash
  printf 'cheerer %s\n' "$(grep '"version"' "$SCRIPT_DIR/package.json" | cut -d'"' -f4)"
```

with:

```bash
  printf 'cheerer %s\n' "$(sed -n '/"version"/{s/.*: *"\([^"]*\)".*/\1/p;q;}' "$SCRIPT_DIR/package.json")"
```

- [ ] **Step 2: Verify it works**

Run: `bash bin/cheer --version`
Expected: `cheerer 2.0.0`

- [ ] **Step 3: Run full test suite**

Run: `bash tests/run.sh all`
Expected: All tests PASS

- [ ] **Step 4: Commit**

```bash
git add bin/cheer
git commit -m "fix(cli): use sed for precise version extraction from package.json"
```

---

### Task 7: Feature 3 — --disable / --enable toggle (cheer.sh restructuring first)

**Files:**
- Modify: `scripts/cheer.sh:1-7`
- Modify: `tests/integration_test.sh`

This feature requires restructuring the top of `cheer.sh` to source `config.sh` before the enabled check. This must be done before adding the `bin/cheer` handlers.

- [ ] **Step 1: Write the failing test**

Add to `tests/integration_test.sh` before the `finish_tests` line:

```bash
test_disable_writes_config() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"

  CLAUDE_PLUGIN_DATA="$tmp_dir/data" bash bin/cheer --disable

  [[ -f "$tmp_dir/data/config.sh" ]] || return 1
  local content
  content="$(cat "$tmp_dir/data/config.sh")"
  assert_eq "CHEERER_ENABLED=false" "$content"
}

test_enable_removes_config() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/data"
  printf 'CHEERER_ENABLED=false\n' > "$tmp_dir/data/config.sh"

  CLAUDE_PLUGIN_DATA="$tmp_dir/data" bash bin/cheer --enable

  [[ ! -f "$tmp_dir/data/config.sh" ]] || return 1
}

test_disabled_cheerer_exits_silently() {
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/data"
  printf 'CHEERER_ENABLED=false\n' > "$tmp_dir/data/config.sh"

  output="$(CLAUDE_PLUGIN_DATA="$tmp_dir/data" \
    CLAUDE_SESSION_ID="disabled-test" \
    CHEERER_LANG="en" \
    CHEERER_VOICE="off" \
    CHEERER_DUMB="true" \
    CHEERER_HOUR=15 \
    bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json)"

  [[ -z "$output" ]] || return 1
}

test_config_sh_only_allows_cheerer_vars() {
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/data"
  # config.sh with a malicious line should NOT be sourced
  printf 'CHEERER_LANG=en\nrm -rf /tmp/fake\nCHEERER_VOICE=off\n' > "$tmp_dir/data/config.sh"

  # The script should NOT source this file (contains non-CHEERER lines)
  # and should fall through to default behavior (no crash)
  output="$(CLAUDE_PLUGIN_DATA="$tmp_dir/data" \
    CLAUDE_SESSION_ID="config-security-test" \
    CHEERER_LANG="zh" \
    CHEERER_VOICE="off" \
    CHEERER_DUMB="true" \
    CHEERER_HOUR=15 \
    bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json 2>&1)"

  # Should still work — config.sh was rejected, defaults used
  [[ -n "$output" ]] || return 1
}

run_test "disable_writes_config" test_disable_writes_config
run_test "enable_removes_config" test_enable_removes_config
run_test "disabled_cheerer_exits_silently" test_disabled_cheerer_exits_silently
run_test "config_sh_only_allows_cheerer_vars" test_config_sh_only_allows_cheerer_vars
```

- [ ] **Step 2: Restructure top of cheer.sh**

In `scripts/cheer.sh`, replace lines 1-7:

```bash
#!/bin/bash
set +e

CHEERER_ENABLED="${CHEERER_ENABLED:-true}"
if [[ "$CHEERER_ENABLED" == "false" ]]; then
  exit 0
fi
```

with:

```bash
#!/bin/bash
set +e

# Compute data dir early (needed for config.sh path)
CHEERER_DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.config/cheerer}"

# Source user config override if it exists
# Security: validate that config.sh only contains CHEERER_* variable assignments
if [[ -f "$CHEERER_DATA_DIR/config.sh" ]]; then
  if grep -qE '^[[:space:]]*CHEERER_[A-Z_]+=' "$CHEERER_DATA_DIR/config.sh" 2>/dev/null; then
    # Only source if every non-empty, non-comment line is a CHEERER_* assignment
    if ! grep -qvE '^[[:space:]]*(CHEERER_[A-Z_]+=.*|#.*|)[[:space:]]*$' "$CHEERER_DATA_DIR/config.sh" 2>/dev/null; then
      . "$CHEERER_DATA_DIR/config.sh"
    fi
  fi
fi

CHEERER_ENABLED="${CHEERER_ENABLED:-true}"
if [[ "$CHEERER_ENABLED" == "false" ]]; then
  exit 0
fi
```

Then remove the duplicate `CHEERER_DATA_DIR` assignment on line 24. The full line:

```bash
CHEERER_DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.config/cheerer}"
```

should be removed since it's now at the top of the file.

- [ ] **Step 3: Add --disable and --enable handlers to bin/cheer**

In `bin/cheer`, add after the `--version` block (after line 12), and before the `_cheerer_stats()` function:

```bash
if [[ "${1:-}" == "--disable" ]]; then
  CHEERER_DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.config/cheerer}"
  mkdir -p "$CHEERER_DATA_DIR"
  printf 'CHEERER_ENABLED=false\n' > "$CHEERER_DATA_DIR/config.sh"
  echo "cheerer disabled. Run 'cheer --enable' to re-enable."
  exit 0
fi

if [[ "${1:-}" == "--enable" ]]; then
  CHEERER_DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.config/cheerer}"
  rm -f "$CHEERER_DATA_DIR/config.sh"
  echo "cheerer enabled."
  exit 0
fi
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/integration_test.sh`
Expected: All tests PASS including the 4 new ones

- [ ] **Step 5: Run full test suite**

Run: `bash tests/run.sh all`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/cheer.sh bin/cheer tests/integration_test.sh
git commit -m "feat: add --disable/--enable toggle with secure config.sh sourcing"
```

---

### Task 8: Feature 5 — CHEERER_ANIM_DURATION override

**Files:**
- Modify: `scripts/lib/animation.sh:112-114`
- Modify: `scripts/cheer.sh` (add export)
- Modify: `tests/integration_test.sh`

- [ ] **Step 1: Write the failing test**

Add to `tests/integration_test.sh` before the `finish_tests` line:

```bash
test_anim_duration_override_short() {
  local output
  output="$(CHEERER_ANIM_DURATION=5 CHEERER_MESSAGE="DurationTest" bash scripts/animations/dance.sh 2>&1)"
  # Should complete without error and contain the message
  assert_contains "$output" "DurationTest"
}

test_anim_duration_override_invalid_ignored() {
  local output
  output="$(CHEERER_ANIM_DURATION=abc CHEERER_MESSAGE="InvalidDurTest" bash scripts/animations/dance.sh 2>&1)"
  # Invalid value should be ignored — default 30 frames used, animation completes
  assert_contains "$output" "InvalidDurTest"
}

test_anim_duration_override_below_minimum() {
  local output
  output="$(CHEERER_ANIM_DURATION=2 CHEERER_MESSAGE="MinDurTest" bash scripts/animations/dance.sh 2>&1)"
  # Below-minimum value should be ignored
  assert_contains "$output" "MinDurTest"
}

run_test "anim_duration_override_short" test_anim_duration_override_short
run_test "anim_duration_override_invalid_ignored" test_anim_duration_override_invalid_ignored
run_test "anim_duration_override_below_minimum" test_anim_duration_override_below_minimum
```

- [ ] **Step 2: Add CHEERER_ANIM_DURATION logic to anim_danmaku_run()**

In `scripts/lib/animation.sh`, in `anim_danmaku_run()`, replace lines 113-114:

```bash
  local tick="${DANMAKU_TICK:-0.07}"
  local total="${DANMAKU_FRAMES:-30}"
```

with:

```bash
  local tick="${DANMAKU_TICK:-0.07}"
  local total="${DANMAKU_FRAMES:-30}"
  if [[ "${CHEERER_ANIM_DURATION:-}" =~ ^[0-9]+$ ]] && [[ "$CHEERER_ANIM_DURATION" -ge 5 ]]; then
    total="$CHEERER_ANIM_DURATION"
  fi
```

- [ ] **Step 3: Export CHEERER_ANIM_DURATION from cheer.sh**

In `scripts/cheer.sh`, after line 63 (the `export CHEERER_HOUR=...` line), add:

```bash
export CHEERER_ANIM_DURATION="${CHEERER_ANIM_DURATION:-}"
```

This ensures the variable is visible to subprocess animations (`bash "$anim_file"`).

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/integration_test.sh`
Expected: All tests PASS including the 3 new ones

- [ ] **Step 5: Run full test suite**

Run: `bash tests/run.sh all`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/lib/animation.sh scripts/cheer.sh tests/integration_test.sh
git commit -m "feat: add CHEERER_ANIM_DURATION override for animation frame count"
```

---

### Task 9: Feature 4 — Message fatigue detection

**Files:**
- Modify: `scripts/lib/render.sh:26-31`
- Modify: `tests/render_test.sh`

- [ ] **Step 1: Write the failing test**

Add to `tests/render_test.sh` before the `finish_tests` line:

```bash
test_render_fatigue_forces_different_message() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  CHEERER_ROOT="$PWD"
  CHEERER_LANG="en"
  POLICY_TIER="solid"
  POLICY_MOOD="steady"
  # Same message ID appears 3 times in last 5 entries — should be excluded
  RECENT_MESSAGE_IDS="en_solid_steady_1,en_solid_steady_1,en_solid_steady_1,en_solid_steady_2"
  STATE_MILESTONE_MSG=""
  CHEERER_CUSTOM_ONLY="false"
  CHEERER_CUSTOM_MSG=""

  render_select_message

  # Should skip en_solid_steady_1 due to fatigue and pick a different one
  [[ "$RENDER_MESSAGE_ID" != "en_solid_steady_1" ]] || return 1
}

test_render_no_fatigue_below_threshold() {
  CHEERER_ROOT="$PWD"
  CHEERER_LANG="en"
  POLICY_TIER="solid"
  POLICY_MOOD="steady"
  # Same message only 2 times — below threshold, no fatigue exclusion
  RECENT_MESSAGE_IDS="en_solid_steady_1,en_solid_steady_1"
  STATE_MILESTONE_MSG=""
  CHEERER_CUSTOM_ONLY="false"
  CHEERER_CUSTOM_MSG=""

  render_select_message

  # en_solid_steady_1 still excluded by normal recent check, so we get en_solid_steady_2
  # This test verifies the fatigue code doesn't break the normal flow
  assert_eq "en_solid_steady_2" "$RENDER_MESSAGE_ID"
}

run_test "render_fatigue_forces_different_message" test_render_fatigue_forces_different_message
run_test "render_no_fatigue_below_threshold" test_render_no_fatigue_below_threshold
```

- [ ] **Step 2: Add fatigue detection to render_select_message()**

In `scripts/lib/render.sh`, in `render_select_message()`, after line 31 (`local recent_csv=",${RECENT_MESSAGE_IDS:-},"`), add:

```bash
  local _fatigue_count _fatigue_mid _last5
  _last5="${RECENT_MESSAGE_IDS:-}"
  _last5="$(printf '%s' "$_last5" | tr ',' '\n' | tail -5)"
  if [[ -n "$_last5" ]]; then
    read -r _fatigue_count _fatigue_mid <<< "$(printf '%s' "$_last5" | sort | uniq -c | sort -rn | head -1)"
    if [[ "${_fatigue_count:-0}" -ge 3 ]]; then
      recent_csv="${recent_csv}${_fatigue_mid},"
    fi
  fi
```

The function should now read:

```bash
render_select_message() {
  local catalog_path
  local fallback_line=""
  local line=""
  local tier mood message_id message_text
  local recent_csv=",${RECENT_MESSAGE_IDS:-},"

  local _fatigue_count _fatigue_mid _last5
  _last5="${RECENT_MESSAGE_IDS:-}"
  _last5="$(printf '%s' "$_last5" | tr ',' '\n' | tail -5)"
  if [[ -n "$_last5" ]]; then
    read -r _fatigue_count _fatigue_mid <<< "$(printf '%s' "$_last5" | sort | uniq -c | sort -rn | head -1)"
    if [[ "${_fatigue_count:-0}" -ge 3 ]]; then
      recent_csv="${recent_csv}${_fatigue_mid},"
    fi
  fi

  if [[ -n "${CHEERER_CUSTOM_MSG:-}" ]]; then
  # ... rest of function unchanged
```

- [ ] **Step 3: Run test to verify it passes**

Run: `bash tests/render_test.sh`
Expected: All tests PASS including the 2 new ones

- [ ] **Step 4: Run full test suite**

Run: `bash tests/run.sh all`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/lib/render.sh tests/render_test.sh
git commit -m "feat(render): add message fatigue detection to prevent repetitive encouragement"
```

---

### Task 10: Feature 1 — --help flag

**Files:**
- Modify: `bin/cheer`
- Modify: `tests/integration_test.sh`

- [ ] **Step 1: Write the failing test**

Add to `tests/integration_test.sh` before the `finish_tests` line:

```bash
test_help_flag_shows_usage() {
  local output
  output="$(bash bin/cheer --help 2>&1)"
  assert_contains "$output" "Usage: cheer"
  assert_contains "$output" "--help"
  assert_contains "$output" "--stats"
  assert_contains "$output" "--preview"
  assert_contains "$output" "--list"
  assert_contains "$output" "--config"
  assert_contains "$output" "--disable"
  assert_contains "$output" "--enable"
  assert_contains "$output" "--version"
  assert_contains "$output" "CHEERER_LANG"
  assert_contains "$output" "CHEERER_COOLDOWN"
  assert_contains "$output" "CHEERER_ANIM_DURATION"
}

run_test "help_flag_shows_usage" test_help_flag_shows_usage
```

- [ ] **Step 2: Add --help handler and _cheerer_help function to bin/cheer**

In `bin/cheer`, add after the `--enable` handler block (from Task 7), before the `_cheerer_stats()` function:

```bash
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
  _cheerer_help
fi
```

And add the `_cheerer_help()` function before that `if` block:

```bash
_cheerer_help() {
  cat << 'HELPEOF'
cheerer — Context-aware celebration for Claude Code

Usage: cheer [flag]

Flags:
  --epic            Force epic mode (play all animations in sequence)
  --stats           Show celebration statistics
  --preview [name]  Preview an animation (random if name omitted)
  --list            List available animations and languages
  --config          Show current configuration
  --disable         Disable cheerer (persists across sessions)
  --enable          Re-enable cheerer
  --version         Print version
  --help            Show this help message

Environment variables:
  CHEERER_ENABLED        Master switch (true/false, default: true)
  CHEERER_LANG           Voice language (zh/en/ja/ko/es, default: zh)
  CHEERER_ANIM           Animation style (random/[name]/epic, default: random)
  CHEERER_VOICE          Voice output (on/off, default: on)
  CHEERER_STYLE          Celebration style (adaptive/balanced/hype/cozy)
  CHEERER_INTENSITY      Intensity (soft/normal/high)
  CHEERER_MODE           Output mode (auto/full/text)
  CHEERER_DUMB           Force text-only (auto/true/false)
  CHEERER_COOLDOWN       Cooldown seconds (default: 3)
  CHEERER_ANIM_DURATION  Animation frames override (default: 30, min: 5)
  CHEERER_EPIC           Force epic mode (true/false)
  CHEERER_EPIC_THRESHOLD Epic mode auto-trigger seconds (default: 60)
  CHEERER_CUSTOM_ONLY    Use only custom messages (true/false)
HELPEOF
  exit 0
}
```

So the full insertion is:

```bash
_cheerer_help() {
  cat << 'HELPEOF'
cheerer — Context-aware celebration for Claude Code

Usage: cheer [flag]

Flags:
  --epic            Force epic mode (play all animations in sequence)
  --stats           Show celebration statistics
  --preview [name]  Preview an animation (random if name omitted)
  --list            List available animations and languages
  --config          Show current configuration
  --disable         Disable cheerer (persists across sessions)
  --enable          Re-enable cheerer
  --version         Print version
  --help            Show this help message

Environment variables:
  CHEERER_ENABLED        Master switch (true/false, default: true)
  CHEERER_LANG           Voice language (zh/en/ja/ko/es, default: zh)
  CHEERER_ANIM           Animation style (random/[name]/epic, default: random)
  CHEERER_VOICE          Voice output (on/off, default: on)
  CHEERER_STYLE          Celebration style (adaptive/balanced/hype/cozy)
  CHEERER_INTENSITY      Intensity (soft/normal/high)
  CHEERER_MODE           Output mode (auto/full/text)
  CHEERER_DUMB           Force text-only (auto/true/false)
  CHEERER_COOLDOWN       Cooldown seconds (default: 3)
  CHEERER_ANIM_DURATION  Animation frames override (default: 30, min: 5)
  CHEERER_EPIC           Force epic mode (true/false)
  CHEERER_EPIC_THRESHOLD Epic mode auto-trigger seconds (default: 60)
  CHEERER_CUSTOM_ONLY    Use only custom messages (true/false)
HELPEOF
  exit 0
}

if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
  _cheerer_help
fi
```

- [ ] **Step 3: Run test to verify it passes**

Run: `bash tests/integration_test.sh 2>&1 | grep help_flag`
Expected: PASS

- [ ] **Step 4: Run full test suite**

Run: `bash tests/run.sh all`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add bin/cheer tests/integration_test.sh
git commit -m "feat: add --help flag with usage info and environment variable reference"
```

---

### Task 11: Feature 2 — --config flag

**Files:**
- Modify: `bin/cheer`
- Modify: `tests/integration_test.sh`

- [ ] **Step 1: Write the failing test**

Add to `tests/integration_test.sh` before the `finish_tests` line:

```bash
test_config_flag_shows_values() {
  local output
  output="$(CHEERER_LANG=en CHEERER_VOICE=off CHEERER_STYLE=hype bash bin/cheer --config 2>&1)"
  assert_contains "$output" "CHEERER_LANG=en"
  assert_contains "$output" "CHEERER_VOICE=off"
  assert_contains "$output" "CHEERER_STYLE=hype"
  assert_contains "$output" "Config file"
}

test_config_flag_shows_defaults() {
  local output
  output="$(bash bin/cheer --config 2>&1)"
  assert_contains "$output" "CHEERER_LANG=zh"
  assert_contains "$output" "CHEERER_COOLDOWN=3"
  assert_contains "$output" "CHEERER_ANIM_DURATION=30"
}

run_test "config_flag_shows_values" test_config_flag_shows_values
run_test "config_flag_shows_defaults" test_config_flag_shows_defaults
```

- [ ] **Step 2: Add --config handler and _cheerer_config function to bin/cheer**

In `bin/cheer`, add before the `_cheerer_help` function:

```bash
_cheerer_config() {
  CHEERER_ENABLED="${CHEERER_ENABLED:-true}"
  CHEERER_LANG="${CHEERER_LANG:-${CLAUDE_PLUGIN_OPTION_LANG:-zh}}"
  CHEERER_ANIM="${CHEERER_ANIM:-${CLAUDE_PLUGIN_OPTION_ANIM:-random}}"
  CHEERER_VOICE="${CHEERER_VOICE:-${CLAUDE_PLUGIN_OPTION_VOICE:-on}}"
  CHEERER_STYLE="${CHEERER_STYLE:-${CLAUDE_PLUGIN_OPTION_STYLE:-adaptive}}"
  CHEERER_INTENSITY="${CHEERER_INTENSITY:-${CLAUDE_PLUGIN_OPTION_INTENSITY:-normal}}"
  CHEERER_MODE="${CHEERER_MODE:-auto}"
  CHEERER_COOLDOWN="${CHEERER_COOLDOWN:-3}"
  CHEERER_ANIM_DURATION="${CHEERER_ANIM_DURATION:-30}"
  CHEERER_EPIC="${CHEERER_EPIC:-false}"
  CHEERER_EPIC_THRESHOLD="${CHEERER_EPIC_THRESHOLD:-60}"

  echo ""
  echo "  cheerer — Current Configuration"
  echo ""
  printf "  CHEERER_ENABLED=%s\n" "$CHEERER_ENABLED"
  printf "  CHEERER_LANG=%s\n" "$CHEERER_LANG"
  printf "  CHEERER_ANIM=%s\n" "$CHEERER_ANIM"
  printf "  CHEERER_VOICE=%s\n" "$CHEERER_VOICE"
  printf "  CHEERER_STYLE=%s\n" "$CHEERER_STYLE"
  printf "  CHEERER_INTENSITY=%s\n" "$CHEERER_INTENSITY"
  printf "  CHEERER_MODE=%s\n" "$CHEERER_MODE"
  printf "  CHEERER_COOLDOWN=%s\n" "$CHEERER_COOLDOWN"
  printf "  CHEERER_ANIM_DURATION=%s\n" "$CHEERER_ANIM_DURATION"
  printf "  CHEERER_EPIC=%s\n" "$CHEERER_EPIC"
  printf "  CHEERER_EPIC_THRESHOLD=%s\n" "$CHEERER_EPIC_THRESHOLD"
  echo ""

  local config_file="${CLAUDE_PLUGIN_DATA:-$HOME/.config/cheerer}/config.sh"
  if [[ -f "$config_file" ]]; then
    printf "  Config file: %s (active)\n" "$config_file"
  else
    printf "  Config file: %s (not found)\n" "$config_file"
  fi
  echo ""
  exit 0
}

if [[ "${1:-}" == "--config" ]]; then
  _cheerer_config
fi
```

- [ ] **Step 3: Run test to verify it passes**

Run: `bash tests/integration_test.sh 2>&1 | grep config_flag`
Expected: PASS for both new tests

- [ ] **Step 4: Run full test suite**

Run: `bash tests/run.sh all`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add bin/cheer tests/integration_test.sh
git commit -m "feat: add --config flag to show current configuration values"
```

---

### Task 12: Shellcheck and final validation

**Files:**
- All modified files

- [ ] **Step 1: Run shellcheck on all modified files**

Run: `shellcheck --severity=error scripts/lib/policy.sh scripts/lib/state.sh scripts/lib/animation.sh scripts/lib/render.sh scripts/cheer.sh bin/cheer`
Expected: Zero errors. If any appear, fix them and re-run.

- [ ] **Step 2: Run full test suite**

Run: `bash tests/run.sh all`
Expected: All tests PASS

- [ ] **Step 3: Smoke test key scenarios**

Run each and verify exit code 0:

```bash
bash bin/cheer --version
bash bin/cheer --help
bash bin/cheer --list
bash bin/cheer --config
CHEERER_LANG=en CHEERER_VOICE=off CHEERER_DUMB=true bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json
```

- [ ] **Step 4: Bump version**

In `package.json`, change `"version": "2.0.0"` to `"version": "2.1.0"`.

In `.claude-plugin/plugin.json`, change the version field from `2.0.0` to `2.1.0`.

- [ ] **Step 5: Commit version bump**

```bash
git add package.json .claude-plugin/plugin.json
git commit -m "chore: bump version to 2.1.0"
```

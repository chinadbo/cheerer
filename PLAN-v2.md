# cheerer v2.0 World-Class Upgrade — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade cheerer from v1.0 to v2.0 with dynamic animation registry, 3 new animations, expanded messages, 2 new languages, voice-text alignment, time-of-day context, rich stats, new CLI commands, and first-run experience.

**Architecture:** Pure-shell, zero-dependency approach preserved. All changes are additive — no breaking changes to existing data formats or hook contracts. Animation auto-discovery replaces hard-coded lists. Voice scripts simplified to read `CHEERER_MESSAGE` instead of maintaining duplicate message arrays.

**Tech Stack:** Bash 3.2+, POSIX utilities, ANSI escape codes, macOS `say` / Linux `espeak-ng` for TTS.

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `scripts/lib/policy.sh` | Modify | Dynamic animation discovery, time-of-day mood |
| `scripts/lib/render.sh` | Modify | First-run welcome, pass CHEERER_MESSAGE to voice |
| `scripts/lib/state.sh` | Modify | Add `state_compute_streak`, `state_daily_counts` |
| `scripts/cheer.sh` | Modify | Lang validation (ko/es), time-of-day hour export |
| `bin/cheer` | Modify | Add `--preview`, `--list`, rich `--stats` |
| `scripts/voices/cheer_en.sh` | Modify | Remove MESSAGES array, use CHEERER_MESSAGE |
| `scripts/voices/cheer_zh.sh` | Modify | Remove MESSAGES array, use CHEERER_MESSAGE |
| `scripts/voices/cheer_ja.sh` | Modify | Remove MESSAGES array, use CHEERER_MESSAGE |
| `scripts/voices/cheer_ko.sh` | Create | Korean voice script |
| `scripts/voices/cheer_es.sh` | Create | Spanish voice script |
| `scripts/animations/rocket.sh` | Create | Rocket liftoff animation |
| `scripts/animations/trophy.sh` | Create | Trophy celebration animation |
| `scripts/animations/wave.sh` | Create | Ocean wave animation |
| `scripts/messages/catalog_en.tsv` | Modify | Expanded English messages |
| `scripts/messages/catalog_zh.tsv` | Modify | Expanded Chinese messages |
| `scripts/messages/catalog_ja.tsv` | Modify | Expanded Japanese messages |
| `scripts/messages/catalog_ko.tsv` | Create | Korean message catalog |
| `scripts/messages/catalog_es.tsv` | Create | Spanish message catalog |
| `tests/policy_test.sh` | Modify | Tests for animation discovery, time-of-day |
| `tests/render_test.sh` | Modify | Tests for voice CHEERER_MESSAGE usage |
| `tests/state_test.sh` | Modify | Tests for streak/daily count computation |
| `tests/integration_test.sh` | Modify | Tests for --preview, --list, --stats, first-run |
| `package.json` | Modify | Bump to 2.0.0 |
| `.claude-plugin/plugin.json` | Modify | Bump to 2.0.0, add ko/es to lang description |

---

### Task 1: Dynamic Animation Registry

**Files:**
- Modify: `scripts/lib/policy.sh:1-15`
- Test: `tests/policy_test.sh`

- [ ] **Step 1: Write the failing test**

Add to `tests/policy_test.sh` before the `run_test` lines:

```bash
test_animation_discovers_from_anim_dir() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/animations"
  printf '#!/bin/bash\n' > "$tmp_dir/animations/rocket.sh"
  printf '#!/bin/bash\n' > "$tmp_dir/animations/trophy.sh"
  ANIM_DIR="$tmp_dir/animations"
  RECENT_ANIMATIONS=""

  policy_pick_animation

  assert_eq "rocket" "$POLICY_ANIMATION"
}

test_animation_avoids_recent_picks() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/animations"
  printf '#!/bin/bash\n' > "$tmp_dir/animations/rocket.sh"
  printf '#!/bin/bash\n' > "$tmp_dir/animations/trophy.sh"
  printf '#!/bin/bash\n' > "$tmp_dir/animations/wave.sh"
  ANIM_DIR="$tmp_dir/animations"
  RECENT_ANIMATIONS="rocket,trophy"

  policy_pick_animation

  assert_eq "wave" "$POLICY_ANIMATION"
}

test_animation_falls_back_when_all_recent() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/animations"
  printf '#!/bin/bash\n' > "$tmp_dir/animations/rocket.sh"
  ANIM_DIR="$tmp_dir/animations"
  RECENT_ANIMATIONS="rocket"

  policy_pick_animation

  assert_eq "rocket" "$POLICY_ANIMATION"
}
```

Add `run_test` lines at the bottom before `finish_tests`:

```bash
run_test "animation_discovers_from_anim_dir" test_animation_discovers_from_anim_dir
run_test "animation_avoids_recent_picks" test_animation_avoids_recent_picks
run_test "animation_falls_back_when_all_recent" test_animation_falls_back_when_all_recent
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/run.sh policy`
Expected: FAIL — `policy_pick_animation` still uses hard-coded list, ignores `ANIM_DIR`

- [ ] **Step 3: Write minimal implementation**

Replace `policy_pick_animation()` in `scripts/lib/policy.sh` (lines 3-15):

```bash
policy_pick_animation() {
  local recent_csv=",${RECENT_ANIMATIONS:-},"
  local candidate candidates=()

  for f in "$ANIM_DIR"/*.sh; do
    [[ -f "$f" ]] || continue
    candidates+=("$(basename "$f" .sh)")
  done

  for candidate in "${candidates[@]}"; do
    if [[ "$recent_csv" != *",$candidate,"* ]]; then
      POLICY_ANIMATION="$candidate"
      return 0
    fi
  done

  POLICY_ANIMATION="${candidates[0]:-basketball}"
}
```

Also update epic mode in `scripts/lib/render.sh` (lines 93-98) to auto-discover:

```bash
    if [[ "${CHEERER_ANIM:-random}" == "epic" ]]; then
      for anim_file in "$ANIM_DIR"/*.sh; do
        [[ -f "$anim_file" ]] || continue
        bash "$anim_file"
      done
```

- [ ] **Step 4: Run all tests to verify nothing broke**

Run: `bash tests/run.sh all`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/lib/policy.sh scripts/lib/render.sh tests/policy_test.sh
git commit -m "feat(policy): dynamic animation discovery from filesystem"
```

---

### Task 2: Rocket Animation

**Files:**
- Create: `scripts/animations/rocket.sh`

- [ ] **Step 1: Create rocket.sh**

Create `scripts/animations/rocket.sh`:

```bash
#!/bin/bash
# rocket.sh — Rocket liftoff pixel animation
# 6 frames: countdown → ignition → liftoff → through clouds → stars → orbit
# Canvas: 10 rows × 22 chars (with border)

RESET="\033[0m"
RED="\033[31m"
ORANGE="\033[38;5;208m"
YELLOW="\033[38;5;226m"
WHITE="\033[97m"
CYAN="\033[96m"
GRAY="\033[90m"
BOLD="\033[1m"
BLUE="\033[34m"

tput civis 2>/dev/null || true
trap 'tput cnorm 2>/dev/null || true' EXIT

DELAY=0.2
FRAME_LINES=10

draw_frame1() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${WHITE}${BOLD}  ║       3...       ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║      /\\         ║${RESET}\n" \
"${GRAY}  ║      ||         ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame2() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${YELLOW}${BOLD}  ║       2...       ║${RESET}\n" \
"${GRAY}  ║      /\\         ║${RESET}\n" \
"${GRAY}  ║      ||         ║${RESET}\n" \
"${ORANGE}  ║     /  \\        ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame3() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${WHITE}${BOLD}  ║       1...       ║${RESET}\n" \
"${GRAY}  ║      /\\         ║${RESET}\n" \
"${GRAY}  ║      ||         ║${RESET}\n" \
"${ORANGE}  ║     /  \\        ║${RESET}\n" \
"${RED}  ║    🔥🔥🔥      ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame4() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${WHITE}${BOLD}  ║      /\\         ║${RESET}\n" \
"${GRAY}  ║      ||         ║${RESET}\n" \
"${ORANGE}  ║     /  \\        ║${RESET}\n" \
"${RED}  ║    🔥🔥🔥      ║${RESET}\n" \
"${YELLOW}  ║   |||||||||     ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame5() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${WHITE}${BOLD}  ║      /\\         ║${RESET}\n" \
"${GRAY}  ║      ||  ✦      ║${RESET}\n" \
"${GRAY}  ║     /  \\  ✦     ║${RESET}\n" \
"${CYAN}  ║    ✦         ✦   ║${RESET}\n" \
"${YELLOW}  ║   |||||||||     ║${RESET}\n" \
"${CYAN}  ║  ✦    ✦    ✦    ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame6() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${CYAN}  ║ ✦    ✦    ✦  ✦   ║${RESET}\n" \
"${WHITE}${BOLD}  ║      🛰️          ║${RESET}\n" \
"${CYAN}  ║   ✦      ✦       ║${RESET}\n" \
"${BLUE}${BOLD}  ║   🌍 LAUNCHED!  ║${RESET}\n" \
"${CYAN}  ║ ✦    ✦    ✦  ✦  ║${RESET}\n" \
"${CYAN}  ║      ✦    ✦     ║${RESET}\n" \
"${CYAN}  ║   ✦         ✦   ║${RESET}\n" \
"${CYAN}  ║ ✦    ✦    ✦     ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# Play animation
draw_frame1

for frame_fn in draw_frame2 draw_frame3 draw_frame4 draw_frame5 draw_frame6; do
  printf "\033[${FRAME_LINES}A\033[0G"
  "$frame_fn"
  sleep "$DELAY"
done

sleep 0.8

# Clean up
printf "\033[${FRAME_LINES}A\033[0G"
for ((i=0; i<FRAME_LINES; i++)); do
  printf "\033[2K\n"
done
printf "\033[${FRAME_LINES}A\033[0G"
```

- [ ] **Step 2: Smoke test**

Run: `bash scripts/animations/rocket.sh`
Expected: Rocket animation plays, terminal clean after

- [ ] **Step 3: Commit**

```bash
chmod +x scripts/animations/rocket.sh
git add scripts/animations/rocket.sh
git commit -m "feat(anim): add rocket liftoff animation"
```

---

### Task 3: Trophy Animation

**Files:**
- Create: `scripts/animations/trophy.sh`

- [ ] **Step 1: Create trophy.sh**

Create `scripts/animations/trophy.sh`:

```bash
#!/bin/bash
# trophy.sh — Trophy celebration pixel animation
# 5 frames: spotlight → trophy slides in → shine → sparkles → celebration
# Canvas: 10 rows × 22 chars (with border)

RESET="\033[0m"
YELLOW="\033[38;5;226m"
WHITE="\033[97m"
CYAN="\033[96m"
GRAY="\033[90m"
BOLD="\033[1m"
MAGENTA="\033[35m"

tput civis 2>/dev/null || true
trap 'tput cnorm 2>/dev/null || true' EXIT

DELAY=0.22
FRAME_LINES=10

draw_frame1() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${WHITE}  ║       |          ║${RESET}\n" \
"${WHITE}  ║      / \\         ║${RESET}\n" \
"${WHITE}  ║     /   \\        ║${RESET}\n" \
"${WHITE}  ║    /spotlight\\   ║${RESET}\n" \
"${WHITE}  ║   /_________ \\   ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame2() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${YELLOW}${BOLD}  ║      ╔═══╗      ║${RESET}\n" \
"${YELLOW}${BOLD}  ║      ║ 1st║      ║${RESET}\n" \
"${YELLOW}${BOLD}  ║      ╚═╤═╝      ║${RESET}\n" \
"${YELLOW}  ║       ──┘        ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame3() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${WHITE}  ║     ✦            ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${YELLOW}${BOLD}  ║      ╔═══╗      ║${RESET}\n" \
"${YELLOW}${BOLD}  ║   ✦  ║1ST║  ✦   ║${RESET}\n" \
"${YELLOW}${BOLD}  ║      ╚═╤═╝      ║${RESET}\n" \
"${YELLOW}  ║       ──┘   ✦   ║${RESET}\n" \
"${WHITE}  ║  ✦          ✦    ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame4() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${CYAN}  ║  ✦    ✦   ✦  ✦   ║${RESET}\n" \
"${YELLOW}${BOLD}  ║      ╔═══╗      ║${RESET}\n" \
"${WHITE}${BOLD}  ║   ✦  ║1ST║  ✦   ║${RESET}\n" \
"${YELLOW}${BOLD}  ║      ╚═╤═╝      ║${RESET}\n" \
"${CYAN}  ║  ✦    ──┘    ✦   ║${RESET}\n" \
"${CYAN}  ║    ✦     ✦      ║${RESET}\n" \
"${WHITE}  ║  ✦           ✦   ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame5() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${CYAN}  ║ ✦  ✦  ✦  ✦  ✦   ║${RESET}\n" \
"${YELLOW}${BOLD}  ║    ╔═══════╗     ║${RESET}\n" \
"${WHITE}${BOLD}  ║ ✦  ║ 🏆1ST║ ✦   ║${RESET}\n" \
"${YELLOW}${BOLD}  ║    ╚═══╤═══╝    ║${RESET}\n" \
"${MAGENTA}${BOLD}  ║   🎉 CHAMPION 🎉║${RESET}\n" \
"${CYAN}  ║ ✦  ──┘  ✦  ✦   ║${RESET}\n" \
"${CYAN}  ║  ✦    ✦    ✦    ║${RESET}\n" \
"${CYAN}  ║ ✦  ✦  ✦  ✦  ✦  ║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# Play animation
draw_frame1

for frame_fn in draw_frame2 draw_frame3 draw_frame4 draw_frame5; do
  printf "\033[${FRAME_LINES}A\033[0G"
  "$frame_fn"
  sleep "$DELAY"
done

sleep 0.7

# Clean up
printf "\033[${FRAME_LINES}A\033[0G"
for ((i=0; i<FRAME_LINES; i++)); do
  printf "\033[2K\n"
done
printf "\033[${FRAME_LINES}A\033[0G"
```

- [ ] **Step 2: Smoke test**

Run: `bash scripts/animations/trophy.sh`
Expected: Trophy animation plays, terminal clean after

- [ ] **Step 3: Commit**

```bash
chmod +x scripts/animations/trophy.sh
git add scripts/animations/trophy.sh
git commit -m "feat(anim): add trophy celebration animation"
```

---

### Task 4: Wave Animation

**Files:**
- Create: `scripts/animations/wave.sh`

- [ ] **Step 1: Create wave.sh**

Create `scripts/animations/wave.sh`:

```bash
#!/bin/bash
# wave.sh — Ocean wave celebration pixel animation
# 5 frames: calm → swell → wave rises → surfer rides → celebration splash
# Canvas: 10 rows × 22 chars (with border)

RESET="\033[0m"
BLUE="\033[34m"
CYAN="\033[96m"
WHITE="\033[97m"
YELLOW="\033[38;5;226m"
GREEN="\033[32m"
GRAY="\033[90m"
BOLD="\033[1m"

tput civis 2>/dev/null || true
trap 'tput cnorm 2>/dev/null || true' EXIT

DELAY=0.22
FRAME_LINES=10

draw_frame1() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${BLUE}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${CYAN}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${BLUE}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${BLUE}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame2() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${CYAN}  ║     ~~~~~~       ║${RESET}\n" \
"${BLUE}  ║   ~~~    ~~~~    ║${RESET}\n" \
"${BLUE}  ║ ~~~        ~~~~  ║${RESET}\n" \
"${CYAN}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${BLUE}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame3() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${CYAN}  ║        ~~~~      ║${RESET}\n" \
"${WHITE}${BOLD}  ║       /surf\\     ║${RESET}\n" \
"${BLUE}  ║    ~~~     ~~~~  ║${RESET}\n" \
"${BLUE}  ║  ~~~         ~~  ║${RESET}\n" \
"${CYAN}  ║ ~~~~~~~~~~~~~~~~ ║${RESET}\n" \
"${BLUE}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame4() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${GRAY}  ║                  ║${RESET}\n" \
"${WHITE}${BOLD}  ║     🏄 ~~~~~     ║${RESET}\n" \
"${CYAN}  ║    ~~~   ~~~~    ║${RESET}\n" \
"${BLUE}  ║  ~~~       ~~~~  ║${RESET}\n" \
"${YELLOW}${BOLD}  ║   ✦  RIDE!  ✦   ║${RESET}\n" \
"${CYAN}  ║  ~~~~~~~~~~~~~~  ║${RESET}\n" \
"${BLUE}  ║ ~~~~~~~~~~~~~~~~ ║${RESET}\n" \
"${BLUE}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

draw_frame5() {
printf "%b" \
"${GRAY}  ╔══════════════════╗${RESET}\n" \
"${CYAN}  ║  💧  💧  💧  💧  ║${RESET}\n" \
"${WHITE}${BOLD}  ║    🏄‍♂️ ✦  ✦      ║${RESET}\n" \
"${CYAN}  ║  💧  💧  💧  💧  ║${RESET}\n" \
"${GREEN}${BOLD}  ║  🌊 RADICAL! 🌊  ║${RESET}\n" \
"${CYAN}  ║  💧  💧  💧  💧  ║${RESET}\n" \
"${BLUE}  ║ ~~~~~~~~~~~~~~~~ ║${RESET}\n" \
"${BLUE}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${BLUE}  ║~~~~~~~~~~~~~~~~~~║${RESET}\n" \
"${GRAY}  ╚══════════════════╝${RESET}\n"
}

# Play animation
draw_frame1

for frame_fn in draw_frame2 draw_frame3 draw_frame4 draw_frame5; do
  printf "\033[${FRAME_LINES}A\033[0G"
  "$frame_fn"
  sleep "$DELAY"
done

sleep 0.7

# Clean up
printf "\033[${FRAME_LINES}A\033[0G"
for ((i=0; i<FRAME_LINES; i++)); do
  printf "\033[2K\n"
done
printf "\033[${FRAME_LINES}A\033[0G"
```

- [ ] **Step 2: Smoke test**

Run: `bash scripts/animations/wave.sh`
Expected: Wave animation plays, terminal clean after

- [ ] **Step 3: Commit**

```bash
chmod +x scripts/animations/wave.sh
git add scripts/animations/wave.sh
git commit -m "feat(anim): add ocean wave animation"
```

---

### Task 5: Voice-Text Alignment

**Files:**
- Modify: `scripts/voices/cheer_en.sh`
- Modify: `scripts/voices/cheer_zh.sh`
- Modify: `scripts/voices/cheer_ja.sh`
- Test: `tests/render_test.sh`

- [ ] **Step 1: Write the failing test**

Add to `tests/render_test.sh` before the `run_test` lines:

```bash
test_voice_script_uses_cheerer_message() {
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/voices"
  cat > "$tmp_dir/voices/cheer_en.sh" << 'VOICE_EOF'
#!/bin/bash
if [[ -n "${CHEERER_MESSAGE:-}" ]]; then
  MSG="$CHEERER_MESSAGE"
else
  MSG="fallback message"
fi
CHEERER_DUMB="true"
CHEERER_VOICE="off"
echo "🎉 $MSG"
VOICE_EOF
  chmod +x "$tmp_dir/voices/cheer_en.sh"

  ANIM_DIR="$tmp_dir/animations"
  VOICE_DIR="$tmp_dir/voices"
  mkdir -p "$ANIM_DIR"
  CHEERER_LANG="en"
  RENDER_ANIMATE="false"
  IN_COOLDOWN="false"
  POLICY_ANIMATION="basketball"
  RENDER_MESSAGE_TEXT="Test message from catalog"
  RENDER_MESSAGE_ID="test_id"
  CHEERER_DUMB="true"
  CHEERER_VOICE="off"

  render_emit

  assert_contains "$RENDER_EMIT_OUTPUT" "Test message from catalog"
}
```

Note: `render_emit` currently doesn't capture output. We need to adjust the test to capture it. Replace the test with:

```bash
test_voice_script_uses_cheerer_message() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/voices"
  # Simplified voice script that proves it uses CHEERER_MESSAGE
  cat > "$tmp_dir/voices/cheer_en.sh" << 'VOICE_EOF'
#!/bin/bash
if [[ -n "${CHEERER_MESSAGE:-}" ]]; then
  MSG="$CHEERER_MESSAGE"
else
  MSG="fallback message"
fi
CHEERER_DUMB="true"
CHEERER_VOICE="off"
echo "🎉 $MSG"
VOICE_EOF
  chmod +x "$tmp_dir/voices/cheer_en.sh"

  # Test that CHEERER_MESSAGE is exported before voice script runs
  export CHEERER_MESSAGE="Test message from catalog"
  export CHEERER_DUMB="true"
  export CHEERER_VOICE="off"
  export CHEERER_MESSAGE_ID="test_id"

  local result
  result="$(bash "$tmp_dir/voices/cheer_en.sh")"

  assert_contains "$result" "Test message from catalog"
}
```

Add at the bottom before `finish_tests`:
```bash
run_test "voice_script_uses_cheerer_message" test_voice_script_uses_cheerer_message
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/run.sh render`
Expected: FAIL — voice scripts still have MESSAGES arrays that ignore CHEERER_MESSAGE when present

- [ ] **Step 3: Simplify voice scripts**

Replace `scripts/voices/cheer_en.sh` entirely:

```bash
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
```

Replace `scripts/voices/cheer_zh.sh` entirely:

```bash
#!/bin/bash
# cheer_zh.sh — 中文语音鼓励
# 优先 macOS say → espeak → 打印文字
# 语音受 CHEERER_VOICE 环境变量控制（on/off/true/false）
# CHEERER_DUMB=true 时不输出任何 ANSI escape code
# 消息来自 CHEERER_MESSAGE（由 render_emit 从目录选取）

if [[ -n "${CHEERER_MESSAGE:-}" ]]; then
  MSG="$CHEERER_MESSAGE"
else
  MSG="干得漂亮！任务完成。"
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
  say -v "Ting-Ting" "$MSG" >/dev/null 2>&1 & disown
elif command -v espeak >/dev/null 2>&1; then
  espeak -v zh "$MSG" >/dev/null 2>&1 & disown
fi

exit 0
```

Replace `scripts/voices/cheer_ja.sh` entirely:

```bash
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
  echo -e "\033[1;32m🎉 $MSG\033[0m"
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
```

- [ ] **Step 4: Run all tests**

Run: `bash tests/run.sh all`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/voices/cheer_en.sh scripts/voices/cheer_zh.sh scripts/voices/cheer_ja.sh tests/render_test.sh
git commit -m "feat(voice): align voice scripts with catalog via CHEERER_MESSAGE"
```

---

### Task 6: Expanded Message Catalogs

**Files:**
- Modify: `scripts/messages/catalog_en.tsv`
- Modify: `scripts/messages/catalog_zh.tsv`
- Modify: `scripts/messages/catalog_ja.tsv`

- [ ] **Step 1: Expand English catalog**

Append to `scripts/messages/catalog_en.tsv`:

```
quick|gentle|en_quick_gentle_2|Small step, real progress. Keep it rolling.
quick|gentle|en_quick_gentle_3|One more down. Smooth and steady.
quick|hype|en_quick_hype_2|Quick and clean. That is how it is done.
solid|steady|en_solid_steady_3|Task closed, quality intact. Onward.
solid|steady|en_solid_steady_4|Done and dusted. Clean work.
solid|rapid_fire|en_solid_rapid_fire_3|Back-to-back wins. The compiler is impressed.
solid|cozy|en_solid_cozy_2|That felt right. Quiet and effective.
solid|cozy|en_solid_cozy_3|No drama, just results. Nice.
solid|streak|en_solid_streak_2|Momentum is building. You are in the zone.
solid|triumphant|en_solid_triumphant_2|Solid execution. That is how it is done.
big|triumphant|en_big_triumphant_2|That was a marathon finish. Respect.
big|triumphant|en_big_triumphant_3|Major milestone energy. You earned this.
big|streak|en_big_streak_2|Big streak moment. The run continues.
big|hype|en_big_hype_2|This is peak performance. You just leveled up.
legendary|milestone|en_legendary_milestone_2|Achievement unlocked. The stats do not lie.
legendary|milestone|en_legendary_milestone_3|You just made history. This session is legendary.
```

- [ ] **Step 2: Expand Chinese catalog**

Append to `scripts/messages/catalog_zh.tsv`:

```
quick|gentle|zh_quick_gentle_2|小步快跑，进步看得见。
quick|gentle|zh_quick_gentle_3|又稳了一步，节奏保持住。
quick|hype|zh_quick_hype_2|干净利落，这一波操作很秀。
solid|steady|zh_solid_steady_3|任务关闭，质量在线，继续。
solid|steady|zh_solid_steady_4|稳稳收工，代码人就该这样。
solid|rapid_fire|zh_solid_rapid_fire_3|连着拿下，编译器都看呆了。
solid|cozy|zh_solid_cozy_2|这波很舒服，静悄悄就把活干了。
solid|cozy|zh_solid_cozy_3|不声不响，结果说话。赞。
solid|streak|zh_solid_streak_2|势头起来了，你现在已经上道了。
solid|triumphant|zh_solid_triumphant_2|执行到位，就是这样拿下的。
big|triumphant|zh_big_triumphant_2|马拉松式收尾，这波很有分量。
big|triumphant|zh_big_triumphant_3|大场面拿下了，这波值得庆祝。
big|streak|zh_big_streak_2|大连胜时刻，你的节奏停不下来。
big|hype|zh_big_hype_2|巅峰表现，你刚刚又升级了。
legendary|milestone|zh_legendary_milestone_2|成就解锁，数据不会说谎。
legendary|milestone|zh_legendary_milestone_3|你刚刚创造了历史，这波真的传说级。
```

- [ ] **Step 3: Expand Japanese catalog**

Append to `scripts/messages/catalog_ja.tsv`:

```
quick|gentle|ja_quick_gentle_2|小さな一歩、確かな前進です。
quick|gentle|ja_quick_gentle_3|また一つ完了。滑らかですね。
quick|hype|ja_quick_hype_2|速攻クリーン。これこそプロの仕事。
solid|steady|ja_solid_steady_3|タスク完了、品質問題なし。次へ。
solid|steady|ja_solid_steady_4|きれいに終わりました。見事です。
solid|rapid_fire|ja_solid_rapid_fire_3|連続クリア。コンパイラも驚きです。
solid|cozy|ja_solid_cozy_2|静かに、でも確実に。いい仕事です。
solid|cozy|ja_solid_cozy_3|地味だけど効果的。これぞ職人技。
solid|streak|ja_solid_streak_2|波に乗っています。ゾーンに入りましたね。
solid|triumphant|ja_solid_triumphant_2|見事な実行。これができる人のやり方です。
big|triumphant|ja_big_triumphant_2|マラソンフィニッシュ。脱帽です。
big|triumphant|ja_big_triumphant_3|ビッグマイルストーン。勝ち取りましたね。
big|streak|ja_big_streak_2|大連勝モード。止まりませんね。
big|hype|ja_big_hype_2|ピークパフォーマンス。レベルアップしました。
legendary|milestone|ja_legendary_milestone_2|実績解除。数字は嘘をつきません。
legendary|milestone|ja_legendary_milestone_3|歴史を作りました。伝説的セッションです。
```

- [ ] **Step 4: Run tests**

Run: `bash tests/run.sh all`
Expected: All PASS — existing tests still work, new messages available but not breaking anything

- [ ] **Step 5: Commit**

```bash
git add scripts/messages/catalog_en.tsv scripts/messages/catalog_zh.tsv scripts/messages/catalog_ja.tsv
git commit -m "feat(messages): expand catalogs to 30 messages per language"
```

---

### Task 7: Korean and Spanish Languages

**Files:**
- Create: `scripts/messages/catalog_ko.tsv`
- Create: `scripts/messages/catalog_es.tsv`
- Create: `scripts/voices/cheer_ko.sh`
- Create: `scripts/voices/cheer_es.sh`
- Modify: `scripts/cheer.sh:39` (lang validation)

- [ ] **Step 1: Create Korean message catalog**

Create `scripts/messages/catalog_ko.tsv`:

```
quick|gentle|ko_quick_gentle_1|작은 한 걸음, 확실한 전진이에요.
quick|gentle|ko_quick_gentle_2|하나 더 끝냈네요. 순조롭습니다.
quick|hype|ko_quick_hype_1|빠르고 깔끔하게! 이게 프로의 실력이죠.
quick|hype|ko_quick_hype_2|끝내주는 속도! 불꽃이 튀네요.
solid|steady|ko_solid_steady_1|탄탄하게 완료했습니다. 상태 좋습니다.
solid|steady|ko_solid_steady_2|깔끔한 마무리. 흐름이 좋네요.
solid|steady|ko_solid_steady_3|작업 완료, 품질 인증. 계속 갑시다.
solid|rapid_fire|ko_solid_rapid_fire_1|연속 클리어! 컴파일러도 놀라고 있어요.
solid|rapid_fire|ko_solid_rapid_fire_2|끊임없이 해내고 있네요. 대단합니다.
solid|cozy|ko_solid_cozy_1|조용하지만 확실하게. 좋은 작업이에요.
solid|cozy|ko_solid_cozy_2|드라마 없이 결과만. 이게 진짜 실력이죠.
solid|streak|ko_solid_streak_1|기세가 좋습니다. 완전 존 모드네요.
solid|streak|ko_solid_streak_2|물결을 타고 있어요. 멈추지 마세요.
solid|triumphant|ko_solid_triumphant_1|완벽한 실행. 이렇게 하는 겁니다.
solid|triumphant|ko_solid_triumphant_2|끝내주는 완수. 박수 받으실 만해요.
big|triumphant|ko_big_triumphant_1|마라톤 피니시! 탈모네요.
big|triumphant|ko_big_triumphant_2|큰 마일스톤 달성! 이걸 위해 달려왔네요.
big|streak|ko_big_streak_1|대연승 모드! 멈출 줄 모르시네요.
big|streak|ko_big_streak_2|끝내주는 연승! 오늘 진짜 폼이 좋으시네요.
big|hype|ko_big_hype_1|피크 퍼포먼스! 레벨업하셨어요.
big|hype|ko_big_hype_2|이건 전설적인 한 수! 모멘텀이 살아있어요.
legendary|milestone|ko_legendary_milestone_1|업적 달성! 숫자는 거짓말하지 않아요.
legendary|milestone|ko_legendary_milestone_2|역사를 만드셨어요. 전설적인 세션입니다.
```

- [ ] **Step 2: Create Spanish message catalog**

Create `scripts/messages/catalog_es.tsv`:

```
quick|gentle|es_quick_gentle_1|Un pequeño paso, un progreso real. Sigue así.
quick|gentle|es_quick_gentle_2|Uno más hecho. Suave y constante.
quick|hype|es_quick_hype_1|Rápido y limpio. Así se hace.
quick|hype|es_quick_hype_2|Velocidad impresionante. La chispa sigue viva.
solid|steady|es_solid_steady_1|Trabajo sólido completado. Buen ritmo.
solid|steady|es_solid_steady_2|Cierre limpio. Calidad y ritmo impecables.
solid|steady|es_solid_steady_3|Tarea cerrada, calidad intacta. Adelante.
solid|rapid_fire|es_solid_rapid_fire_1|Victorias consecutivas. El compilador está impresionado.
solid|rapid_fire|es_solid_rapid_fire_2|No paras. Esta racha es real. Sigue así.
solid|cozy|es_solid_cozy_1|Tranquilo pero efectivo. Buen trabajo.
solid|cozy|es_solid_cozy_2|Sin drama, solo resultados. Así se hace.
solid|streak|es_solid_streak_1|El momento sigue creciendo. Estás en la zona.
solid|streak|es_solid_streak_2|Racha imparable. Sigue con esa energía.
solid|triumphant|es_solid_triumphant_1|Ejecución sólida. Así se hace.
solid|triumphant|es_solid_triumphant_2|Cierre contundente. Te lo ganaste.
big|triumphant|es_big_triumphant_1|Gran final. Lo llevaste con maestría.
big|triumphant|es_big_triumphant_2|Fin de maratón. Respeto total.
big|streak|es_big_streak_1|Racha épica. No hay quien te pare.
big|streak|es_big_streak_2|Gran momento de racha. Sigue así.
big|hype|es_big_hype_1|Rendimiento máximo. Acabas de subir de nivel.
big|hype|es_big_hype_2|Energía brutal. Convirtiendo esfuerzo en momento.
legendary|milestone|es_legendary_milestone_1|Logro desbloqueado. Los números no mienten.
legendary|milestone|es_legendary_milestone_2|Acabas de hacer historia. Sesión legendaria.
```

- [ ] **Step 3: Create Korean voice script**

Create `scripts/voices/cheer_ko.sh`:

```bash
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
  echo -e "\033[1;32m🎉 $MSG\033[0m"
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
```

- [ ] **Step 4: Create Spanish voice script**

Create `scripts/voices/cheer_es.sh`:

```bash
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
  echo -e "\033[1;32m🎉 $MSG\033[0m"
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
```

- [ ] **Step 5: Update lang validation in cheer.sh**

Change line 39 of `scripts/cheer.sh` from:
```bash
case "$CHEERER_LANG" in zh|en|ja) ;; *) CHEERER_LANG="zh" ;; esac
```
to:
```bash
case "$CHEERER_LANG" in zh|en|ja|ko|es) ;; *) CHEERER_LANG="zh" ;; esac
```

- [ ] **Step 6: Run all tests**

Run: `bash tests/run.sh all`
Expected: All PASS

- [ ] **Step 7: Commit**

```bash
chmod +x scripts/voices/cheer_ko.sh scripts/voices/cheer_es.sh
git add scripts/messages/catalog_ko.tsv scripts/messages/catalog_es.tsv scripts/voices/cheer_ko.sh scripts/voices/cheer_es.sh scripts/cheer.sh
git commit -m "feat(lang): add Korean and Spanish language support"
```

---

### Task 8: Time-of-Day Context

**Files:**
- Modify: `scripts/lib/policy.sh:17-71`
- Modify: `scripts/cheer.sh` (add CHEERER_HOUR export)
- Test: `tests/policy_test.sh`

- [ ] **Step 1: Write the failing test**

Add to `tests/policy_test.sh` before the `run_test` lines:

```bash
test_morning_upgrades_gentle_to_steady() {
  HOOK_EVENT="Stop"
  TASK_DURATION=5
  RECENT_TASKCOMPLETED_COUNT=0
  SESSION_STREAK=0
  STATE_MILESTONE_MSG=""
  CHEERER_STYLE="adaptive"
  CHEERER_INTENSITY="normal"
  RECENT_ANIMATIONS=""
  ANIM_DIR="$PWD/scripts/animations"
  CHEERER_HOUR=9

  policy_select_celebration

  assert_eq "quick" "$POLICY_TIER"
  assert_eq "steady" "$POLICY_MOOD"
}

test_late_night_overrides_to_cozy() {
  HOOK_EVENT="TaskCompleted"
  TASK_DURATION=10
  RECENT_TASKCOMPLETED_COUNT=0
  SESSION_STREAK=0
  STATE_MILESTONE_MSG=""
  CHEERER_STYLE="adaptive"
  CHEERER_INTENSITY="normal"
  RECENT_ANIMATIONS=""
  ANIM_DIR="$PWD/scripts/animations"
  CHEERER_HOUR=23

  policy_select_celebration

  assert_eq "cozy" "$POLICY_MOOD"
}
```

Add at the bottom before `finish_tests`:
```bash
run_test "morning_upgrades_gentle_to_steady" test_morning_upgrades_gentle_to_steady
run_test "late_night_overrides_to_cozy" test_late_night_overrides_to_cozy
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/run.sh policy`
Expected: FAIL — no time-of-day logic yet

- [ ] **Step 3: Implement time-of-day in policy.sh**

Add a new function at the top of `scripts/lib/policy.sh` (after the shebang line):

```bash
_policy_apply_time_of_day() {
  local hour="${CHEERER_HOUR:-$(date +%H 2>/dev/null || echo 12)}"
  hour="${hour#0}"  # strip leading zero for arithmetic

  # Morning (6-12): +1 mood energy
  if [[ "$hour" -ge 6 ]] && [[ "$hour" -lt 12 ]]; then
    if [[ "$POLICY_MOOD" == "gentle" ]]; then
      POLICY_MOOD="steady"
    elif [[ "$POLICY_MOOD" == "steady" ]]; then
      POLICY_MOOD="rapid_fire"
    fi
  fi

  # Late night (22-6): cozy override for quick/solid
  if [[ "$hour" -ge 22 ]] || [[ "$hour" -lt 6 ]]; then
    if [[ "$POLICY_TIER" == "quick" ]] || [[ "$POLICY_TIER" == "solid" ]]; then
      POLICY_MOOD="cozy"
    fi
  fi
}
```

Then call `_policy_apply_time_of_day` inside `policy_select_celebration()`, right before the style `case` block. Add this line after `policy_pick_animation` call (line 70):

```bash
  _policy_apply_time_of_day
```

Wait — the call should be *before* style overrides so style can still win. Place it after the streak/milestone logic but before the style case. Insert after line 48 (milestone return) and before line 49 (style case):

Actually the milestone case does an early return, so we need to place the call right before the style case. Insert `_policy_apply_time_of_day` call right before the `case "${CHEERER_STYLE:-adaptive}" in` block.

- [ ] **Step 4: Export CHEERER_HOUR in cheer.sh**

Add after line 58 in `scripts/cheer.sh` (after `CURRENT_ISO=` line):

```bash
export CHEERER_HOUR=$(date +%H 2>/dev/null || echo 12)
```

- [ ] **Step 5: Run all tests**

Run: `bash tests/run.sh all`
Expected: All PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/lib/policy.sh scripts/cheer.sh tests/policy_test.sh
git commit -m "feat(policy): add time-of-day mood adjustment"
```

---

### Task 9: Rich Stats CLI

**Files:**
- Modify: `bin/cheer`
- Modify: `scripts/lib/state.sh`
- Test: `tests/state_test.sh`

- [ ] **Step 1: Add state helper functions**

Add to `scripts/lib/state.sh` (at end of file):

```bash
state_compute_streak() {
  local streak=0 max_streak=0
  local row_ts row_hook _rest prev_ts=0
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
  local counts="$TMPDIR/cheerer_counts_$$"
  : > "$counts"
  local val _rest

  cut -d'|' -f"$field_index" "$HISTORY_FILE" | sort | uniq -c | sort -rn > "$counts"
  head -1 "$counts" | awk '{print $2}'
  rm -f "$counts"
}
```

- [ ] **Step 2: Write failing test for state_compute_streak**

Add to `tests/state_test.sh` before `finish_tests`:

```bash
test_state_compute_streak() {
  local tmp_dir i
  tmp_dir="$(make_tmp_dir)"
  CHEERER_DATA_DIR="$tmp_dir/data"
  STATS_FILE="$CHEERER_DATA_DIR/stats.json"
  HISTORY_FILE="$CHEERER_DATA_DIR/history.log"

  state_init

  local now
  now=$(date +%s)
  for i in 1 2 3; do
    state_append_history "$((now - 100 + i * 10))" "TaskCompleted" "12" "solid" "steady" "dance" "msg$i"
  done

  local streak
  streak="$(state_compute_streak)"

  [[ "$streak" -ge 3 ]] || return 1
}
```

Add `run_test` line:
```bash
run_test "state_compute_streak" test_state_compute_streak
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bash tests/run.sh state`
Expected: FAIL — `state_compute_streak` doesn't exist yet

- [ ] **Step 4: Run tests after adding functions**

Run: `bash tests/run.sh state`
Expected: PASS

- [ ] **Step 5: Rewrite --stats in bin/cheer**

Replace the `--stats` block in `bin/cheer` (lines 9-27) with:

```bash
if [[ "${1:-}" == "--stats" ]]; then
  CHEERER_DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.config/cheerer}"
  STATS_FILE="$CHEERER_DATA_DIR/stats.json"
  HISTORY_FILE="$CHEERER_DATA_DIR/history.log"

  if [[ ! -f "$STATS_FILE" ]]; then
    echo "No stats yet — complete some tasks with Claude Code!"
    exit 0
  fi

  SCRIPT_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
  . "$SCRIPT_DIR/scripts/lib/state.sh"

  state_read_stats || state_defaults

  echo ""
  echo "  cheerer — Your Celebration Stats"
  echo ""
  printf "  Total celebrations:   %s\n" "${STATS_TOTAL_TRIGGERS:-0}"

  if [[ -f "$HISTORY_FILE" ]] && [[ -s "$HISTORY_FILE" ]]; then
    local_streak
    streak="$(state_compute_streak)"
    printf "  Current streak:       %s (last 30 min)\n" "$streak"

    echo ""
    echo "  Last 7 days:"

    local max_count=1
    daily_raw="$(state_daily_counts 7)"
    while IFS='|' read -r d c; do
      [[ "$c" -gt "$max_count" ]] && max_count="$c"
    done <<< "$daily_raw"

    while IFS='|' read -r d c; do
      local bar_len=$(( c * 20 / max_count ))
      local bar=""
      local j
      for ((j=0; j<20; j++)); do
        if [[ "$j" -lt "$bar_len" ]]; then
          bar+="█"
        else
          bar+="░"
        fi
      done
      local day_name
      day_name="$(date -j -f "%Y-%m-%d" "$d" +%a 2>/dev/null || date -d "$d" +%a 2>/dev/null || echo "$d")"
      printf "  %s %s %s\n" "$day_name" "$bar" "$c"
    done <<< "$daily_raw"

    local fav_anim
    fav_anim="$(state_most_used 6)"
    local fav_tier
    fav_tier="$(state_most_used 4)"
    echo ""
    printf "  Most used animation:  %s\n" "${fav_anim:-?}"
    printf "  Favorite tier:        %s\n" "${fav_tier:-?}"
  else
    echo "  (no history yet)"
  fi

  local milestones_raw
  milestones_raw="$(printf '%s' "$(cat "$STATS_FILE" 2>/dev/null)" | grep -o '"milestones":\[[^]]*\]' | cut -d: -f2-)"
  [[ "$milestones_raw" == "[]" ]] && milestones_raw="none yet"
  [[ "$milestones_raw" != "none yet" ]] && milestones_raw="$(printf '%s' "$milestones_raw" | tr -d '[]')"
  printf "  Milestones:           %s\n" "$milestones_raw"

  local last_trigger
  last_trigger="$(printf '%s' "$(cat "$STATS_FILE" 2>/dev/null)" | grep -o '"last_trigger":"[^"]*"' | cut -d'"' -f4)"
  printf "  Last trigger:         %s\n" "${last_trigger:-never}"

  echo ""
  exit 0
fi
```

- [ ] **Step 6: Commit**

```bash
git add scripts/lib/state.sh bin/cheer tests/state_test.sh
git commit -m "feat(stats): add rich stats dashboard with streak and daily chart"
```

---

### Task 10: New CLI Commands (--preview, --list)

**Files:**
- Modify: `bin/cheer`

- [ ] **Step 1: Add --preview and --list to bin/cheer**

Add after the `--epic` block (after line 7) in `bin/cheer`:

```bash
if [[ "${1:-}" == "--list" ]]; then
  SCRIPT_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
  echo "Animations:"
  for f in "$SCRIPT_DIR/scripts/animations"/*.sh; do
    [[ -f "$f" ]] || continue
    echo "  $(basename "$f" .sh)"
  done
  echo "Languages: zh, en, ja, ko, es"
  exit 0
fi

if [[ "${1:-}" == "--preview" ]]; then
  SCRIPT_DIR="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
  ANIM_NAME="${2:-}"
  ANIM_DIR="$SCRIPT_DIR/scripts/animations"

  if [[ -z "$ANIM_NAME" ]]; then
    # Pick random
    local anims=()
    for f in "$ANIM_DIR"/*.sh; do
      [[ -f "$f" ]] || continue
      anims+=("$(basename "$f" .sh)")
    done
    ANIM_NAME="${anims[$((RANDOM % ${#anims[@]}))]}"
  fi

  if [[ -f "$ANIM_DIR/$ANIM_NAME.sh" ]]; then
    bash "$ANIM_DIR/$ANIM_NAME.sh"
  else
    echo "Animation not found: $ANIM_NAME"
    echo "Available: $(cd "$ANIM_DIR" && ls *.sh 2>/dev/null | sed 's/.sh//g' | tr '\n' ' ')"
    exit 1
  fi
  exit 0
fi
```

- [ ] **Step 2: Test manually**

Run: `bin/cheer --list`
Expected: Lists all 6 animations + languages

Run: `bin/cheer --preview rocket`
Expected: Plays rocket animation

Run: `bin/cheer --preview`
Expected: Plays a random animation

- [ ] **Step 3: Commit**

```bash
git add bin/cheer
git commit -m "feat(cli): add --preview and --list commands"
```

---

### Task 11: First-Run Experience

**Files:**
- Modify: `scripts/lib/render.sh`
- Modify: `scripts/cheer.sh`

- [ ] **Step 1: Add first-run detection in cheer.sh**

Add after `state_init` (line 56) in `scripts/cheer.sh`:

```bash
CHEERER_FIRST_RUN="false"
if [[ "${STATS_TOTAL_TRIGGERS:-0}" -eq 0 ]]; then
  CHEERER_FIRST_RUN="true"
fi
```

Wait — `state_record_trigger` is called after `state_init` (line 86). We need to check *before* recording. The `STATS_TOTAL_TRIGGERS` is 0 right after `state_init` on first run. Move the check to after `state_init`:

Add after line 56 (`state_init`):
```bash
CHEERER_FIRST_RUN="false"
if [[ "${STATS_TOTAL_TRIGGERS:-0}" -eq 0 ]]; then
  CHEERER_FIRST_RUN="true"
fi
```

- [ ] **Step 2: Add welcome message in render_emit**

Add at the top of `render_emit()` in `scripts/lib/render.sh` (after the function declaration):

```bash
  if [[ "${CHEERER_FIRST_RUN:-false}" == "true" ]]; then
    if [[ "${CHEERER_DUMB:-false}" == "true" ]]; then
      echo ""
      echo "  cheerer — Welcome!"
      echo ""
      echo "  Your celebration plugin is active."
      echo "  Animations and encouragement will play when you complete tasks."
      echo ""
      echo "  Configure: cheer --list"
      echo "  Preview:   cheer --preview"
      echo "  Stats:     cheer --stats"
      echo ""
    else
      echo ""
      echo -e "\033[1;36m  cheerer — Welcome!\033[0m"
      echo ""
      echo "  Your celebration plugin is active."
      echo "  Animations and encouragement will play when you complete tasks."
      echo ""
      echo -e "  Configure: \033[1mcheer --list\033[0m"
      echo -e "  Preview:   \033[1mcheer --preview\033[0m"
      echo -e "  Stats:     \033[1mcheer --stats\033[0m"
      echo ""
    fi
  fi
```

- [ ] **Step 3: Run all tests**

Run: `bash tests/run.sh all`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add scripts/cheer.sh scripts/lib/render.sh
git commit -m "feat(onboarding): add first-run welcome message"
```

---

### Task 12: Version Bump and Plugin Config

**Files:**
- Modify: `package.json`
- Modify: `.claude-plugin/plugin.json`

- [ ] **Step 1: Bump package.json**

Change version in `package.json` from `"1.0.0"` to `"2.0.0"`.

- [ ] **Step 2: Update plugin.json**

In `.claude-plugin/plugin.json`:
- Change version from `"1.0.0"` to `"2.0.0"`
- Update lang description from `"zh / en / ja, default: zh"` to `"zh / en / ja / ko / es, default: zh"`
- Update anim description from `"random / basketball / dance / fireworks / epic, default: random"` to `"random / [animation-name] / epic, default: random"`

- [ ] **Step 3: Run all tests**

Run: `bash tests/run.sh all`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add package.json .claude-plugin/plugin.json
git commit -m "chore: bump version to 2.0.0"
```

---

### Task 13: Final Integration Test Pass

**Files:**
- Modify: `tests/integration_test.sh`

- [ ] **Step 1: Add integration tests for new features**

Add to `tests/integration_test.sh` before `finish_tests`:

```bash
test_preview_command_runs_animation() {
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/animations"
  printf '#!/bin/bash\necho "rocket-launched"\n' > "$tmp_dir/animations/rocket.sh"
  chmod +x "$tmp_dir/animations/rocket.sh"

  output="$(ANIM_DIR="$tmp_dir/animations" CHEERER_DUMB="true" bash "$tmp_dir/animations/rocket.sh")"
  assert_contains "$output" "rocket-launched"
}

test_list_command_discovers_animations() {
  local tmp_dir
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/animations"
  touch "$tmp_dir/animations/basketball.sh"
  touch "$tmp_dir/animations/rocket.sh"
  touch "$tmp_dir/animations/trophy.sh"

  local found
  found="$(for f in "$tmp_dir/animations"/*.sh; do basename "$f" .sh; done)"
  assert_contains "$found" "basketball"
  assert_contains "$found" "rocket"
  assert_contains "$found" "trophy"
}

test_first_run_shows_welcome() {
  local tmp_dir output
  tmp_dir="$(make_tmp_dir)"
  mkdir -p "$tmp_dir/data"

  output="$(CLAUDE_PLUGIN_DATA="$tmp_dir/data" CLAUDE_SESSION_ID="first-run-test" CHEERER_LANG="en" CHEERER_VOICE="off" CHEERER_DUMB="true" bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json)"

  assert_contains "$output" "Welcome!"
  assert_contains "$output" "cheer --list"
}

test_korean_lang_works() {
  local output
  output="$(CLAUDE_PLUGIN_DATA="$(make_tmp_dir)/data" CLAUDE_SESSION_ID="ko-test" CHEERER_LANG="ko" CHEERER_VOICE="off" CHEERER_DUMB="true" bash scripts/cheer.sh < tests/fixtures/taskcompleted-short.json)"

  # Should produce non-empty output without error
  [[ -n "$output" ]] || return 1
}
```

Add `run_test` lines before `finish_tests`:
```bash
run_test "preview_command_runs_animation" test_preview_command_runs_animation
run_test "list_command_discovers_animations" test_list_command_discovers_animations
run_test "first_run_shows_welcome" test_first_run_shows_welcome
run_test "korean_lang_works" test_korean_lang_works
```

- [ ] **Step 2: Run full test suite**

Run: `bash tests/run.sh all`
Expected: All PASS

- [ ] **Step 3: Commit**

```bash
git add tests/integration_test.sh
git commit -m "test: add integration tests for v2.0 features"
```

---

## Spec Coverage Check

| Spec Section | Task |
|---|---|
| Dynamic Animation Registry | Task 1 |
| Three New Animations | Tasks 2, 3, 4 |
| Expanded Message Catalogs | Task 6 |
| Two New Languages | Task 7 |
| Voice-Text Alignment | Task 5 |
| Time-of-Day Context | Task 8 |
| Rich Stats CLI | Task 9 |
| New CLI Commands | Task 10 |
| First-Run Experience | Task 11 |
| Version Bump | Task 12 |
| Integration Tests | Task 13 |

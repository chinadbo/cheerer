# cheerer v2.0 — World-Class Upgrade Design

**Date:** 2026-04-10
**Status:** Approved (auto-approved by owner directive)
**Approach:** Comprehensive upgrade across animation, intelligence, and polish

---

## Problem

cheerer v1.0 is functional but feels limited after extended use:
- 3 animations with a hard-coded registry — repetitive, hard to extend
- 13 messages per language (1-2 per tier/mood) — predictable
- Voice scripts maintain separate message arrays that drift from catalogs
- Stats CLI is 3 lines of raw data — no streaks, no visualization
- No time-of-day or session-momentum awareness
- No way to preview or discover animations without triggering a hook
- Only 3 languages

## Design

### 1. Dynamic Animation Registry

**Current:** `policy_pick_animation()` iterates a hard-coded list `basketball dance fireworks`.

**New:** Auto-discover `.sh` files in `scripts/animations/` at runtime.

```bash
policy_pick_animation() {
  local recent_csv=",${RECENT_ANIMATIONS:-},"
  local candidate candidates=()

  for f in "$ANIM_DIR"/*.sh; do
    candidates+=("$(basename "$f" .sh)")
  done

  for candidate in "${candidates[@]}"; do
    if [[ "$recent_csv" != *",$candidate,"* ]]; then
      POLICY_ANIMATION="$candidate"
      return 0
    fi
  done

  POLICY_ANIMATION="${candidates[0]}"
}
```

Adding a new animation = dropping a `.sh` file. No code changes needed.

Epic mode also auto-discovers: iterate all `*.sh` in animations dir.

### 2. Three New Animations

| Animation | Concept | Frames | Duration |
|-----------|---------|--------|----------|
| `rocket` | Countdown → ignition → liftoff → stars | 6 | ~2.5s |
| `trophy` | Trophy slides in → spotlight → sparkles | 5 | ~2.2s |
| `wave` | Ocean swell → surfer rides → celebration | 5 | ~2.3s |

Each follows the existing pattern: `tput civis`, frame functions, cursor rewind, `tput cnorm`, clean exit. Same 10-row canvas with border.

### 3. Expanded Message Catalogs

**Current:** ~13 messages per language (1-2 per tier/mood combination).

**New:** 3-5 messages per tier/mood combination, totaling ~30 messages per language.

New messages added to existing tier/mood keys in TSV format. No new tiers or moods — just more variety within existing slots.

Example additions for `catalog_en.tsv`:
```
quick|gentle|en_quick_gentle_2|Small step, real progress. Keep it rolling.
quick|gentle|en_quick_gentle_3|One more down. Smooth and steady.
solid|steady|en_solid_steady_3|Task closed, quality intact. Onward.
solid|steady|en_solid_steady_4|Done and dusted. Clean work.
big|triumphant|en_big_triumphant_2|That was a marathon finish. Respect.
big|triumphant|en_big_triumphant_3|Major milestone energy. You earned this.
legendary|milestone|en_legendary_milestone_2|Achievement unlocked. The stats do not lie.
```

Same pattern for zh and ja — tech-flavorful, culturally tuned.

### 4. Two New Languages

| Language | Code | TTS (macOS) | TTS (Linux) |
|----------|------|-------------|-------------|
| Korean | ko | `say -v Yuna` | `espeak -v ko` |
| Spanish | es | `say -v Monica` | `espeak -v es` |

New files: `scripts/messages/catalog_ko.tsv`, `scripts/messages/catalog_es.tsv`, `scripts/voices/cheer_ko.sh`, `scripts/voices/cheer_es.sh`.

Lang validation in `cheer.sh` updated: `case "$CHEERER_LANG" in zh|en|ja|ko|es) ;; *)`.

### 5. Voice-Text Alignment

**Current:** Voice scripts (`cheer_en.sh` etc.) contain independent `MESSAGES=()` arrays that drift from catalog TSV content.

**New:** Voice scripts receive the selected message via `CHEERER_MESSAGE` env var (already set in `render_emit()`). Remove the `MESSAGES=()` arrays from voice scripts. If `CHEERER_MESSAGE` is empty, fall back to the catalog.

This ensures voice always reads the same message displayed on screen. No drift possible.

```bash
# Voice script simplified structure:
if [[ -n "${CHEERER_MESSAGE:-}" ]]; then
  MSG="$CHEERER_MESSAGE"
else
  # Read fallback from catalog
  MSG="Great work. Task complete."
fi
```

### 6. Time-of-Day Context

Add time-of-day as a factor in `policy_select_celebration()`:

| Time | Period | Effect |
|------|--------|--------|
| 6-12 | Morning | +1 mood energy (gentle→steady, steady→rapid_fire) |
| 12-18 | Afternoon | No change |
| 18-22 | Evening | -1 mood energy when tier is quick (no hype on quick) |
| 22-6 | Late night | Cozy override for quick/solid tiers |

Implementation: read `date +%H`, apply mood adjustment before style override.

### 7. Rich Stats CLI

**Current:** `cheer --stats` prints 3 lines.

**New:** Formatted stats dashboard:

```
  cheerer — Your Celebration Stats

  Total celebrations:   42
  Current streak:       5 (last 30 min)
  Longest streak:       8 (Apr 8)
  Milestones:           10, 25

  Last 7 days:
  Mon ░░░░░░░░░░░░░░░░░░ 2
  Tue ██████████░░░░░░░░░ 5
  Wed ████████████████░░░ 8
  Thu ██████████████░░░░░ 7
  Fri ████████████████████ 10
  Sat ████░░░░░░░░░░░░░░░ 2
  Sun ░░░░░░░░░░░░░░░░░░░ 0

  Most used animation:  fireworks (15x)
  Favorite tier:        solid (60%)
```

Data source: `history.log` (already stores timestamp, tier, animation). Parse and format at display time. No new fields in stats.json — streaks and daily counts are derived from history.log on the fly. This avoids schema migration and keeps state simple.

### 8. New CLI Commands

| Command | Description |
|---------|-------------|
| `cheer --preview [name]` | Play an animation without hook trigger. `name` optional (random if omitted). |
| `cheer --list` | List all available animations and languages. |

Implementation in `bin/cheer`:

```bash
if [[ "${1:-}" == "--preview" ]]; then
  ANIM_NAME="${2:-random}"
  # source cheer.sh config, pick animation, play it
fi

if [[ "${1:-}" == "--list" ]]; then
  echo "Animations:"
  for f in "$SCRIPT_DIR/scripts/animations"/*.sh; do
    echo "  $(basename "$f" .sh)"
  done
  echo "Languages: zh, en, ja, ko, es"
fi
```

### 9. First-Run Experience

On first trigger (when `stats.json` doesn't exist yet), show a welcome message:

```
  cheerer — Welcome!

  Your celebration plugin is active.
  Animations and encouragement will play when you complete tasks.

  Configure: cheer --list
  Preview:   cheer --preview
  Stats:     cheer --stats
```

Implementation: check if `STATS_TOTAL_TRIGGERS` is 0 after `state_init`. If so, set a welcome flag that `render_emit` checks.

---

## Scope Exclusions

- No GUI/web dashboard
- No network calls (remains pure-shell, zero deps)
- No persistence schema changes (history.log format unchanged, stats.json additive only)
- No Windows support (macOS + Linux only, same as v1)
- No new hook events (Stop + TaskCompleted remain the only triggers)

## Testing Plan

- All existing tests must continue passing
- New test: `policy_test.sh` — verify animation auto-discovery with mock dir
- New test: `policy_test.sh` — verify time-of-day mood adjustment
- New test: `render_test.sh` — verify voice scripts use CHEERER_MESSAGE
- New test: `state_test.sh` — verify new stats fields (longest_streak, daily_counts)
- New test: `integration_test.sh` — verify --preview, --list, --stats, first-run
- New animations each get a smoke test (run without error, correct frame count)

## Migration

- Existing `stats.json` is forward-compatible (new fields default if missing)
- Existing `history.log` format unchanged
- New animations and languages are additive — no breaking changes
- Voice script change (removing MESSAGES arrays) is internal-only; `CHEERER_MESSAGE` already flows through

## Version

Bump to `2.0.0` in `package.json` and `plugin.json`.

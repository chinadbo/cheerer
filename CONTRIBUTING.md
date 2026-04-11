# Contributing to cheerer

Thanks for taking the time to contribute! cheerer is a pure-Shell Claude Code plugin — no Node, no Python, just bash. Contributions of all kinds are welcome.

## Requirements

All you need to contribute:

- `bash` (4.0+)
- [`shellcheck`](https://www.shellcheck.net/) for linting

## How to Add a New Animation

1. Create a new script in `scripts/animations/`, e.g. `scripts/animations/confetti.sh`
2. Follow the existing pattern:
   - Source the shared danmaku library: `. "$(dirname "${BASH_SOURCE[0]}")/../lib/animation.sh"`
   - Sanitize the message: `MSG="$(anim_sanitize_msg "${CHEERER_MESSAGE:-Great work!}")"`
   - Set `DANMAKU_*` arrays (`DANMAKU_ROWS`, `DANMAKU_TICK`, `DANMAKU_FRAMES`, `DANMAKU_ROW`, `DANMAKU_TEXT`, `DANMAKU_COLOR`, `DANMAKU_SPEED`, `DANMAKU_DELAY`)
   - Call `anim_danmaku_run` to play the animation
   - Clean up after playback — leave the terminal exactly as you found it
3. The animation is auto-discovered at runtime — no registration needed
4. Run shellcheck and the smoke test (see below)

## How to Add a New Language

1. Create `scripts/voices/cheer_XX.sh` (use an [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) code)
2. Follow the existing pattern:
   - Read the selected message from `CHEERER_MESSAGE` env var (already set by `render_emit()`)
   - If `CHEERER_MESSAGE` is empty, fall back to a hardcoded default
   - Print with `\033[1;32m🎉 $MSG\033[0m` (or plain text when `CHEERER_DUMB=true`)
   - Call `say` (macOS) or `espeak` (Linux) in the background (`& disown`)
   - Fall back gracefully when neither TTS engine is available
3. Update the `case "$CHEERER_LANG"` validation block in `scripts/cheer.sh` to include the new code
4. Update `userConfig.lang.description` in `.claude-plugin/plugin.json`
5. Run shellcheck and the smoke test

## Linting

```bash
shellcheck --severity=error \
  scripts/cheer.sh \
  scripts/animations/*.sh \
  scripts/voices/*.sh \
  bin/cheer \
  scripts/check-secrets.sh \
  scripts/install-hooks.sh
```

All scripts must pass with **zero errors** at `--severity=error`.
Warnings are not blocking but please fix them when practical.

## Smoke Test

```bash
# Basic trigger (should print animation + encouragement, exit 0)
bash scripts/cheer.sh

# Language switching
CHEERER_LANG=en bash scripts/cheer.sh
CHEERER_LANG=ja bash scripts/cheer.sh

# Dumb terminal (no ANSI output)
CHEERER_DUMB=true bash scripts/cheer.sh

# Disabled
CHEERER_ENABLED=false bash scripts/cheer.sh; echo "exit: $?"  # should print nothing and exit 0

# Cooldown (second call within 3s should skip animation)
bash scripts/cheer.sh && bash scripts/cheer.sh
```

> **Note:** there is no `bash scripts/cheer.sh test` mode — run the commands above instead.

## PR Requirements

Before opening a PR:

- [ ] `shellcheck --severity=error` passes on all shell files
- [ ] Smoke test passes (see above)
- [ ] If you add an animation or language, update the directory listing in all four READMEs (`README.md`, `README.en.md`, `README.zh.md`, `README.ja.md`)
- [ ] Keep commits focused; one logical change per commit
- [ ] Write a clear commit message (imperative mood: `add fireworks animation`, not `added`)

## Project Structure

```text
cheerer/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest (name, version, userConfig, hooks path)
├── hooks/
│   └── hooks.json           # Hook events: Stop + TaskCompleted → cheer.sh
├── scripts/
│   ├── cheer.sh             # Entry point: selects animation + language, manages cooldown
│   ├── animations/          # One script per danmaku theme (auto-discovered)
│   │   ├── basketball.sh
│   │   ├── dance.sh
│   │   ├── fireworks.sh
│   │   ├── rocket.sh
│   │   ├── trophy.sh
│   │   └── wave.sh
│   ├── lib/
│   │   ├── animation.sh     # Shared danmaku engine
│   │   ├── policy.sh        # Tier/mood selection logic
│   │   ├── render.sh        # Message selection and output
│   │   └── state.sh         # Stats, history, milestones
│   ├── messages/            # One TSV catalog per language
│   │   ├── catalog_zh.tsv
│   │   ├── catalog_en.tsv
│   │   ├── catalog_ja.tsv
│   │   ├── catalog_ko.tsv
│   │   └── catalog_es.tsv
│   └── voices/              # One script per language (TTS + text fallback)
│       ├── cheer_zh.sh
│       ├── cheer_en.sh
│       ├── cheer_ja.sh
│       ├── cheer_ko.sh
│       └── cheer_es.sh
├── bin/
│   └── cheer                # Wrapper command (--epic, --stats, --preview, --list)
└── .github/
    └── workflows/
        └── ci.yml           # shellcheck lint + smoke test + tag-based release
```

## Design Principles

1. **Zero dependencies** — no package managers, no runtimes, just bash
2. **Never break Claude Code** — always `exit 0`, use `set +e`
3. **Terminal-safe** — dumb terminal detection, cursor restore on `EXIT` trap
4. **Non-blocking** — TTS runs in the background (`& disown`), animation finishes before voice starts
5. **Cooldown-aware** — `/tmp/cheerer_last_trigger_${CLAUDE_SESSION_ID:-default}` prevents same-session rapid re-trigger spam

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Be kind, be constructive.

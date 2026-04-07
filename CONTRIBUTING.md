# Contributing to cheerer

Thanks for taking the time to contribute! cheerer is a pure-Shell Claude Code plugin — no Node, no Python, just bash. Contributions of all kinds are welcome.

## Requirements

All you need to contribute:

- `bash` (4.0+)
- [`shellcheck`](https://www.shellcheck.net/) for linting

## How to Add a New Animation

1. Create a new script in `scripts/animations/`, e.g. `scripts/animations/confetti.sh`
2. Follow the existing pattern:
   - Define `draw_frameN()` functions for each frame
   - Hide the cursor with `tput civis` and restore it in a `trap 'tput cnorm' EXIT`
   - Clear frame area with ANSI cursor-up escape (`\033[11A\033[0G`) between frames
   - Clean up after playback — leave the terminal exactly as you found it
3. Register the animation name in the `ANIMS` array inside `scripts/cheer.sh`
4. Run shellcheck and the smoke test (see below)

## How to Add a New Language

1. Create `scripts/voices/cheer_XX.sh` (use an [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) code)
2. Follow the existing pattern:
   - Define a `MESSAGES` array with ≥10 entries; each must contain at least one tech-specific term or programmer meme
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
- [ ] If you add an animation or language, update the directory listing in all three READMEs (`README.md`, `README.zh.md`, `README.ja.md`)
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
│   ├── animations/          # One script per animation (frame-based ANSI)
│   │   ├── basketball.sh
│   │   ├── dance.sh
│   │   └── fireworks.sh
│   └── voices/              # One script per language (TTS + text fallback)
│       ├── cheer_zh.sh
│       ├── cheer_en.sh
│       └── cheer_ja.sh
├── bin/
│   └── cheer                # Bare command available in Claude Code's Bash tool
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

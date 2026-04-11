# 🎉 cheerer — Claude Code Cheer Plugin

![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)
![Shell](https://img.shields.io/badge/Shell-Bash-89e051?logo=gnu-bash&logoColor=white)
![GitHub Repo stars](https://img.shields.io/github/stars/chinadbo/cheerer?style=social)

Whenever Claude Code finishes a task, cheerer plays a danmaku (bullet-screen) floating-subtitle animation and a multilingual voice encouragement to make coding more fun.

## ✨ Features

- 🏀 Six danmaku animations: basketball, dance, fireworks, rocket, trophy, wave
- 🔊 Multilingual voice encouragement (Chinese / English / Japanese / Korean / Spanish)
- 🎲 Random animation selection, or force a specific animation
- 🚀 Epic mode that plays all six animations in sequence
- 📊 Trigger stats and milestone celebrations (`--stats`, milestone fireworks)
- 📝 Optional custom message pool loaded from `custom-messages.txt`
- 🖥️ Automatic dumb-terminal fallback and session-scoped cooldown handling

## 🎬 Demo Preview

After Claude Code finishes a task, your terminal instantly plays a short danmaku animation (floating subtitles scrolling right-to-left) and a matching voice encouragement. This is a text placeholder for now — a GIF demo will be added later.

## 📦 Installation

### Method 1: Add cheerer as a marketplace (recommended)

Add this repo as a plugin marketplace, then install the `cheerer` plugin from it:

```bash
claude plugin marketplace add chinadbo/cheerer
claude plugin install cheerer@cheerer
```

Or inside a Claude Code session:

```text
/plugin marketplace add chinadbo/cheerer
/plugin install cheerer@cheerer
```

Run `/reload-plugins` if you install it during an active session.

### Method 2: Manual hook setup

```bash
git clone https://github.com/chinadbo/cheerer.git ~/.cheerer
chmod +x ~/.cheerer/scripts/cheer.sh
chmod +x ~/.cheerer/scripts/animations/*.sh
chmod +x ~/.cheerer/scripts/voices/*.sh
chmod +x ~/.cheerer/bin/cheer
```

Configure hooks in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.cheerer/scripts/cheer.sh",
            "async": true,
            "statusMessage": "🎉 Cheering..."
          }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.cheerer/scripts/cheer.sh",
            "async": true,
            "statusMessage": "🎉 Cheering..."
          }
        ]
      }
    ]
  }
}
```

## 🚀 Usage

### Run directly

```bash
# Random animation + default Chinese encouragement
bash scripts/cheer.sh

# Choose language with env vars
CHEERER_LANG=en bash scripts/cheer.sh
CHEERER_LANG=ja bash scripts/cheer.sh

# Choose animation with env vars
CHEERER_ANIM=basketball bash scripts/cheer.sh
CHEERER_ANIM=dance bash scripts/cheer.sh
CHEERER_ANIM=fireworks bash scripts/cheer.sh
CHEERER_ANIM=rocket bash scripts/cheer.sh
CHEERER_ANIM=trophy bash scripts/cheer.sh
CHEERER_ANIM=wave bash scripts/cheer.sh
CHEERER_ANIM=epic bash scripts/cheer.sh

# Force text-only fallback
CHEERER_DUMB=true bash scripts/cheer.sh
CHEERER_MODE=text bash scripts/cheer.sh

# Wrapper command
bash bin/cheer --epic
bash bin/cheer --stats
bash bin/cheer --preview
bash bin/cheer --list
```

`bin/cheer` supports four flags:

- `--epic` — force epic mode (plays all six animations in sequence)
- `--stats` — print total triggers, milestones reached, and last trigger time
- `--preview [name]` — play an animation without a hook trigger; `name` is optional (random if omitted)
- `--list` — list all available animations and languages

### Run animations individually

```bash
bash scripts/animations/basketball.sh
bash scripts/animations/dance.sh
bash scripts/animations/fireworks.sh
```

### Run voice scripts individually

```bash
bash scripts/voices/cheer_zh.sh
bash scripts/voices/cheer_en.sh
bash scripts/voices/cheer_ja.sh
```

## ⚙️ Environment Variables

| Variable | Description | Values | Default |
|------|------|--------|---------|
| `CHEERER_ENABLED` | Master switch | `true` / `false` | `true` |
| `CHEERER_LANG` | Voice language | `zh` / `en` / `ja` / `ko` / `es` | `zh` |
| `CHEERER_ANIM` | Animation style | `basketball` / `dance` / `fireworks` / `rocket` / `trophy` / `wave` / `epic` / `random` | `random` |
| `CHEERER_VOICE` | Enable or disable voice | `on` / `off` / `true` / `false` | `on` |
| `CHEERER_DUMB` | Force text-only fallback or keep auto-detect | `auto` / `true` / `false` | `auto` |
| `CHEERER_MODE` | Output mode | `auto` / `full` / `text` | `auto` |
| `CHEERER_COOLDOWN` | Cooldown seconds between triggers | positive integer | `3` |
| `CHEERER_EPIC_THRESHOLD` | Auto-enable epic mode at this task duration | positive integer | `60` |
| `CHEERER_EPIC` | Force epic mode for one run | `true` / `false` | `false` |
| `CHEERER_CUSTOM_ONLY` | Use only custom messages when available | `true` / `false` | `false` |
| `CHEERER_STYLE` | Celebration personality | `adaptive` / `balanced` / `hype` / `cozy` | `adaptive` |
| `CHEERER_INTENSITY` | Celebration energy | `soft` / `normal` / `high` | `normal` |

`CHEERER_*` env vars override plugin settings.

### Runtime behavior

- `CHEERER_MODE=auto` animates `TaskCompleted` hooks and keeps `Stop` hooks text-only unless `CHEERER_INTENSITY=high`.
- `CHEERER_MODE=full` always plays animation.
- `CHEERER_MODE=text` always skips animation.
- `CHEERER_ANIM=epic`, `CHEERER_EPIC=true`, or a task duration at or above `CHEERER_EPIC_THRESHOLD` plays all six animations in sequence.
- `CHEERER_COOLDOWN` has an effective minimum of 1 second even if set to `0`.
- Cooldown suppresses animation only; text/voice output still runs.
- `CHEERER_DUMB=auto` is the default; cheerer also auto-detects dumb terminals and empty `TERM` values.
- `CHEERER_STYLE=adaptive` uses hook type, duration, milestones, and recent history to vary cheer tone.
- `CHEERER_INTENSITY=soft` keeps quick wins lighter; `high` makes celebration output more energetic, including animated `Stop` hooks in `CHEERER_MODE=auto`.
- Messages are selected from per-language catalogs and avoid immediate repeats when possible.

## Testing

```bash
bash tests/run.sh all
bash tests/run.sh state
bash tests/run.sh policy
bash tests/run.sh render
bash tests/run.sh integration
```

## 📁 State and data files

By default, cheerer stores plugin data in `${CLAUDE_PLUGIN_DATA:-$HOME/.config/cheerer}`:

- `stats.json` — total triggers, last trigger time, milestone history
- `history.log` — per-trigger log (timestamp, event, duration, tier, mood, animation, message id)
- `custom-messages.txt` — optional custom encouragements, one message per line (`#` starts a comment)

Cooldown state is tracked in `/tmp/cheerer_last_trigger_${CLAUDE_SESSION_ID:-default}`.

Milestones currently trigger at 10, 25, 50, 100, 250, 500, and 1000 total runs. Milestone runs append a trophy message and force the fireworks animation.

## 🛠️ Technical Notes

- **Pure Shell implementation** with zero runtime dependencies
- **ANSI escape codes** for colors and cursor movement
- **Danmaku engine** — floating subtitles scroll right-to-left at configurable rows, speeds, and delays
- **Voice fallback**: macOS `say` → `espeak` → plain text
- **Animation duration**: around 2–3 seconds, designed not to interrupt your workflow
- **Terminal compatibility**: automatically detects dumb terminals and falls back gracefully

## 📁 Directory Structure

```text
cheerer/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── bin/
│   └── cheer                # Wrapper command (--epic, --stats, --preview, --list)
├── hooks/
│   └── hooks.json           # Hook configuration
├── scripts/
│   ├── cheer.sh             # Main entry point (hooks + routing + stats)
│   ├── animations/
│   │   ├── basketball.sh    # Basketball danmaku theme
│   │   ├── dance.sh         # Dance danmaku theme
│   │   ├── fireworks.sh     # Fireworks danmaku theme
│   │   ├── rocket.sh        # Rocket danmaku theme
│   │   ├── trophy.sh        # Trophy danmaku theme
│   │   └── wave.sh          # Wave danmaku theme
│   ├── lib/
│   │   ├── animation.sh     # Shared danmaku engine
│   │   ├── policy.sh        # Tier/mood selection logic
│   │   ├── render.sh        # Message selection and output
│   │   └── state.sh         # Stats, history, milestones
│   ├── messages/
│   │   ├── catalog_en.tsv   # English message catalog
│   │   ├── catalog_zh.tsv   # Chinese message catalog
│   │   ├── catalog_ja.tsv   # Japanese message catalog
│   │   ├── catalog_ko.tsv   # Korean message catalog
│   │   └── catalog_es.tsv   # Spanish message catalog
│   └── voices/
│       ├── cheer_zh.sh      # Chinese encouragement
│       ├── cheer_en.sh      # English encouragement
│       ├── cheer_ja.sh      # Japanese encouragement
│       ├── cheer_ko.sh      # Korean encouragement
│       └── cheer_es.sh      # Spanish encouragement
├── tests/
│   ├── run.sh               # Test runner
│   ├── fixtures/            # JSON hook event fixtures
│   ├── integration_test.sh
│   ├── policy_test.sh
│   ├── render_test.sh
│   └── state_test.sh
├── README.md
├── README.en.md
├── README.zh.md
└── README.ja.md
```

## 🔧 Customization

### Add a new animation

1. Create a new `.sh` file in `scripts/animations/` — set `DANMAKU_*` arrays then call `anim_danmaku_run`
2. The animation is auto-discovered at runtime (no registration needed)
3. Run `bash scripts/cheer.sh` or `CHEERER_ANIM=<name> bash scripts/cheer.sh` to verify it works

### Add a new language

1. Create `cheer_XX.sh` in `scripts/voices/`
2. Add the matching language handling in `scripts/cheer.sh`
3. Run `CHEERER_LANG=<code> bash scripts/cheer.sh` to verify the output

## 📝 License

MIT © chinadbo

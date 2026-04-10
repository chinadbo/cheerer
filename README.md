# 🎉 cheerer — Claude Code Cheer Plugin

![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)
![Shell](https://img.shields.io/badge/Shell-Bash-89e051?logo=gnu-bash&logoColor=white)
![GitHub Repo stars](https://img.shields.io/github/stars/chinadbo/cheerer?style=social)

**Language:** English | [中文](README.zh.md) | [日本語](README.ja.md)

Whenever Claude Code finishes a task, cheerer plays a pixel-style terminal animation and a multilingual voice encouragement to make coding more fun.

## ✨ Features

- 🏀 Basketball, dance, and fireworks terminal animations
- 🔊 Multilingual voice encouragement (Chinese / English / Japanese)
- 🎲 Random animation selection, or force a specific animation
- 🚀 Epic mode that plays all three animations in sequence
- 📊 Trigger stats and milestone celebrations (`--stats`, milestone fireworks)
- 📝 Optional custom message pool loaded from `custom-messages.txt`
- 🖥️ Automatic dumb-terminal fallback and session-scoped cooldown handling

## 🎬 Demo Preview

After Claude Code finishes a task, your terminal instantly plays a short pixel animation and a matching voice encouragement. This is a text placeholder for now — a GIF demo will be added later.

## 📦 Installation

### Method 1: Add cheerer as a marketplace (recommended) ⭐

Requires Claude Code. First add this repo as a plugin marketplace, then install the `cheerer` plugin from that marketplace:

```bash
claude plugin marketplace add chinadbo/cheerer
claude plugin install cheerer@cheerer
```

Or from inside a Claude Code session:

```text
/plugin marketplace add chinadbo/cheerer
/plugin install cheerer@cheerer
```

Then run `/reload-plugins` if you installed it during an active session.

### Method 2: Plugin Marketplace (for teams)

If you manage a team marketplace, add cheerer as an entry in your `marketplace.json`:

```json
{
  "name": "your-marketplace",
  "plugins": [
    {
      "name": "cheerer",
      "source": {
        "source": "github",
        "repo": "chinadbo/cheerer"
      },
      "description": "Pixel animations + voice encouragement when tasks complete"
    }
  ]
}
```

This repository also works as a single-plugin marketplace out of the box:

```bash
claude plugin marketplace add chinadbo/cheerer
claude plugin install cheerer@cheerer
```

### Method 3: Manual hook setup (no Claude Code plugin system)

```bash
git clone https://github.com/chinadbo/cheerer.git ~/.cheerer
chmod +x ~/.cheerer/scripts/cheer.sh
chmod +x ~/.cheerer/scripts/animations/*.sh
chmod +x ~/.cheerer/scripts/voices/*.sh
chmod +x ~/.cheerer/bin/cheer
```

Add to `~/.claude/settings.json`:

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

## ⚙️ Configuration

### Option 1: Plugin configuration

If Claude Code prompts for plugin settings during `/plugin enable cheerer`, you can configure:

```
/plugin enable cheerer
> Voice language (zh / en / ja): zh
> Animation style (random / basketball / dance / fireworks / epic): random
> Enable voice output (on / off): on
> Celebration style (adaptive / balanced / hype / cozy): adaptive
> Celebration intensity (soft / normal / high): normal
```

If no prompt appears, set the same values with environment variables instead.

### Option 2: Environment variables

Set in your shell profile (`~/.bashrc`, `~/.zshrc`) or `.claude/settings.json`:

| Variable | Description | Values | Default |
|------|------|--------|---------|
| `CHEERER_ENABLED` | Master switch | `true` / `false` | `true` |
| `CHEERER_LANG` | Voice language | `zh` / `en` / `ja` | `zh` |
| `CHEERER_ANIM` | Animation style | `basketball` / `dance` / `fireworks` / `epic` / `random` | `random` |
| `CHEERER_VOICE` | Voice output | `on` / `off` / `true` / `false` | `on` |
| `CHEERER_DUMB` | Force text-only fallback or keep auto-detect | `auto` / `true` / `false` | `auto` |
| `CHEERER_MODE` | Output mode | `auto` / `full` / `text` | `auto` |
| `CHEERER_COOLDOWN` | Cooldown between triggers (seconds) | positive integer | `3` |
| `CHEERER_EPIC_THRESHOLD` | Auto-enable epic mode when task duration reaches this many seconds | positive integer | `60` |
| `CHEERER_EPIC` | Force epic mode for one run | `true` / `false` | `false` |
| `CHEERER_CUSTOM_ONLY` | Use only custom messages when available | `true` / `false` | `false` |
| `CHEERER_STYLE` | Celebration personality | `adaptive` / `balanced` / `hype` / `cozy` | `adaptive` |
| `CHEERER_INTENSITY` | Celebration energy | `soft` / `normal` / `high` | `normal` |

> `CHEERER_*` env vars override plugin `userConfig` settings.

### Runtime behavior

- `CHEERER_MODE=auto` plays animation on `TaskCompleted`, and keeps `Stop` hooks text-only unless `CHEERER_INTENSITY=high`.
- `CHEERER_MODE=full` always plays animation.
- `CHEERER_MODE=text` always skips animation and prints only the encouragement text/voice.
- `CHEERER_ANIM=epic`, `CHEERER_EPIC=true`, or a task duration at or above `CHEERER_EPIC_THRESHOLD` plays all three animations in sequence.
- `CHEERER_COOLDOWN` has an effective minimum of 1 second, even if you set `0`.
- Cooldown suppresses animation only; text/voice output still runs.
- `CHEERER_DUMB=auto` is the default; cheerer also auto-detects dumb terminals and empty `TERM` values.
- `CHEERER_STYLE=adaptive` uses hook type, duration, milestones, and recent history to vary cheer tone.
- `CHEERER_INTENSITY=soft` keeps quick wins lighter; `high` makes celebration output more energetic, including animated `Stop` hooks in `CHEERER_MODE=auto`.
- Messages are selected from per-language catalogs and avoid immediate repeats when possible.

## 🚀 Direct usage

From a repo checkout:

```bash
# Main script
bash scripts/cheer.sh
CHEERER_LANG=en bash scripts/cheer.sh
CHEERER_LANG=ja CHEERER_VOICE=off bash scripts/cheer.sh
CHEERER_ANIM=fireworks bash scripts/cheer.sh
CHEERER_ANIM=epic bash scripts/cheer.sh
CHEERER_MODE=text bash scripts/cheer.sh
CHEERER_DUMB=true bash scripts/cheer.sh

# Wrapper command
bash bin/cheer --epic
bash bin/cheer --stats
```

`bin/cheer` currently supports exactly two flags:

- `--epic` — force epic mode (basketball + dance + fireworks)
- `--stats` — print total triggers, milestones reached, and last trigger time

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
- `history.log` — per-trigger log (timestamp, event, duration, tier, mood, animation, message id); trimmed to the last 50 rows
- `custom-messages.txt` — optional custom encouragements, one message per line (`#` starts a comment)

Cooldown state is tracked separately in `/tmp/cheerer_last_trigger_${CLAUDE_SESSION_ID:-default}`.

Milestones currently trigger at 10, 25, 50, 100, 250, 500, and 1000 total runs. Milestone runs append a trophy message and force the fireworks animation.

## 🛠️ Technical Notes

- **Pure Shell implementation** with zero runtime dependencies
- **ANSI escape codes** for colors and cursor movement
- **Frame animation** rendered in place with cursor rewind (`\033[11A`)
- **Voice fallback**: macOS `say` → `espeak` → plain text
- **Animation duration**: around 2–3 seconds, designed not to interrupt your workflow
- **Terminal compatibility**: automatically detects dumb terminals and falls back gracefully

## 📁 Directory Structure

```text
cheerer/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── bin/
│   └── cheer                # Wrapper command (--epic, --stats)
├── hooks/
│   └── hooks.json           # Hook configuration
├── scripts/
│   ├── cheer.sh             # Main entry point (hooks + routing + stats)
│   ├── animations/
│   │   ├── basketball.sh    # Basketball animation
│   │   ├── dance.sh         # Dancing animation
│   │   └── fireworks.sh     # Fireworks animation
│   ├── lib/
│   │   ├── policy.sh        # Tier/mood selection logic
│   │   ├── render.sh        # Message selection and output
│   │   └── state.sh         # Stats, history, milestones
│   ├── messages/
│   │   ├── catalog_en.tsv   # English message catalog
│   │   ├── catalog_zh.tsv   # Chinese message catalog
│   │   └── catalog_ja.tsv   # Japanese message catalog
│   └── voices/
│       ├── cheer_zh.sh      # Chinese encouragement
│       ├── cheer_en.sh      # English encouragement
│       └── cheer_ja.sh      # Japanese encouragement
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

1. Create a new `.sh` file in `scripts/animations/`
2. Add the animation name to the candidate list in `policy_pick_animation` in `scripts/lib/policy.sh`
3. Run `bash scripts/cheer.sh` or `CHEERER_ANIM=<name> bash scripts/cheer.sh` to verify it works

### Add a new language

1. Create `cheer_XX.sh` in `scripts/voices/`
2. Add the matching language handling in `scripts/cheer.sh`
3. Run `CHEERER_LANG=<code> bash scripts/cheer.sh` to verify the output

### Add custom messages

Create `${CLAUDE_PLUGIN_DATA:-$HOME/.config/cheerer}/custom-messages.txt`:

```text
Ship it!
Nice refactor.
Tests are green — enjoy the win.
```

Set `CHEERER_CUSTOM_ONLY=true` if you want to skip the built-in message pool.

## 📝 License

MIT © chinadbo

# 🎉 cheerer — Claude Code Cheer Plugin

![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)
![Shell](https://img.shields.io/badge/Shell-Bash-89e051?logo=gnu-bash&logoColor=white)
![GitHub Repo stars](https://img.shields.io/github/stars/chinadbo/cheerer?style=social)

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
CHEERER_ANIM=epic bash scripts/cheer.sh

# Force text-only fallback
CHEERER_DUMB=true bash scripts/cheer.sh
CHEERER_MODE=text bash scripts/cheer.sh

# Wrapper command
bash bin/cheer --epic
bash bin/cheer --stats
```

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
| `CHEERER_LANG` | Voice language | `zh` / `en` / `ja` | `zh` |
| `CHEERER_ANIM` | Animation style | `basketball` / `dance` / `fireworks` / `epic` / `random` | `random` |
| `CHEERER_VOICE` | Enable or disable voice | `on` / `off` / `true` / `false` | `on` |
| `CHEERER_DUMB` | Force text-only fallback or keep auto-detect | `auto` / `true` / `false` | `auto` |
| `CHEERER_MODE` | Output mode | `auto` / `full` / `text` | `auto` |
| `CHEERER_COOLDOWN` | Cooldown seconds between triggers | positive integer | `3` |
| `CHEERER_EPIC_THRESHOLD` | Auto-enable epic mode at this task duration | positive integer | `60` |
| `CHEERER_EPIC` | Force epic mode for one run | `true` / `false` | `false` |
| `CHEERER_CUSTOM_ONLY` | Use only custom messages when available | `true` / `false` | `false` |

`CHEERER_*` env vars override plugin settings.

### Runtime behavior

- `CHEERER_MODE=auto` keeps `Stop` hooks text-only and animates `TaskCompleted` hooks.
- `CHEERER_MODE=full` always plays animation.
- `CHEERER_MODE=text` always skips animation.
- `CHEERER_ANIM=epic`, `CHEERER_EPIC=true`, or a task duration at or above `CHEERER_EPIC_THRESHOLD` plays all three animations in sequence.
- `CHEERER_COOLDOWN` has an effective minimum of 1 second even if set to `0`.
- Cooldown suppresses animation only; text/voice output still runs.

## 📁 State and data files

By default, cheerer stores plugin data in `${CLAUDE_PLUGIN_DATA:-$HOME/.config/cheerer}`:

- `stats.json` — total triggers, last trigger time, milestone history
- `custom-messages.txt` — optional custom encouragements, one message per line (`#` starts a comment)

Cooldown state is tracked in `/tmp/cheerer_last_trigger_${CLAUDE_SESSION_ID:-default}`.

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
│   └── voices/
│       ├── cheer_zh.sh      # Chinese encouragement
│       ├── cheer_en.sh      # English encouragement
│       └── cheer_ja.sh      # Japanese encouragement
├── README.md
├── README.en.md
├── README.zh.md
└── README.ja.md
```

## 🔧 Customization

### Add a new animation

1. Create a new `.sh` file in `scripts/animations/`
2. Add the animation name to the `ANIMS` array in `scripts/cheer.sh`
3. Run `bash scripts/cheer.sh` or `CHEERER_ANIM=<name> bash scripts/cheer.sh` to verify it works

### Add a new language

1. Create `cheer_XX.sh` in `scripts/voices/`
2. Add the matching language handling in `scripts/cheer.sh`
3. Run `CHEERER_LANG=<code> bash scripts/cheer.sh` to verify the output

## 📝 License

MIT © chinadbo

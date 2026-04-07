# 🎉 cheerer — Claude Code Cheer Plugin

![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)
![Shell](https://img.shields.io/badge/Shell-Bash-89e051?logo=gnu-bash&logoColor=white)
![GitHub Repo stars](https://img.shields.io/github/stars/chinadbo/cheerer?style=social)


**Language:** English | [中文](README.zh.md) | [日本語](README.ja.md)

Whenever Claude Code finishes a task, cheerer plays a pixel-style terminal animation and a multilingual voice encouragement to make coding more fun.

## ✨ Features

- 🏀 Basketball pixel animation with ANSI frame rendering
- 💃 Dancing pixel animation
- 🎆 Fireworks animation
- 🔊 Multilingual voice encouragement (Chinese / English / Japanese)
- 🎲 Random animation and language selection for a different experience each time

## 🎬 Demo Preview

After Claude Code finishes a task, your terminal instantly plays a short pixel animation and a matching voice encouragement. This is a text placeholder for now — a GIF demo will be added later.

## 📦 Installation

### Method 1: Claude Code Plugin (one command — recommended) ⭐

Requires Claude Code. Installs directly from GitHub — no cloning needed:

```bash
claude plugin install github:chinadbo/cheerer
```

Or from inside a Claude Code session:

```
/plugin install github:chinadbo/cheerer
```

That's it. cheerer auto-registers the hooks and starts working immediately.

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

Or add chinadbo/cheerer directly as a single-plugin marketplace:

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
            "command": "~/.cheerer/scripts/cheer.sh"
          }
        ]
      }
    ]
  }
}
```

## ⚙️ Configuration

### Option 1: Interactive setup (recommended for Plugin install)

When you enable the plugin, Claude Code prompts you to configure:

```
/plugin enable cheerer
> Voice language (zh / en / ja): zh
> Animation style (random / basketball / dance / fireworks): random  
> Enable voice output (on / off): on
```

Settings are saved automatically and persist across sessions.

### Option 2: Environment variables

Set in your shell profile (`~/.bashrc`, `~/.zshrc`) or `.claude/settings.json`:

| Variable | Description | Values | Default |
|------|------|--------|---------|
| `CHEERER_LANG` | Voice language | `zh` / `en` / `ja` | `zh` |
| `CHEERER_ANIM` | Animation style | `basketball` / `dance` / `fireworks` / `random` | `random` |
| `CHEERER_ENABLED` | Master switch | `true` / `false` | `true` |
| `CHEERER_VOICE` | Voice output | `on` / `off` | `on` |
| `CHEERER_COOLDOWN` | Cooldown between triggers (seconds) | positive integer | `3` |

> `CHEERER_*` env vars override plugin userConfig settings.

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
├── hooks/
│   └── hooks.json           # Hook configuration
├── scripts/
│   ├── cheer.sh             # Main entry point (random animation + language)
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
└── README.ja.md
```

## 🔧 Customization

### Add a new animation

1. Create a new `.sh` file in `scripts/animations/`
2. Add the animation name to the `ANIMS` array in `scripts/cheer.sh`
3. Run `bash scripts/cheer.sh test` to verify it works

### Add a new language

1. Create `cheer_XX.sh` in `scripts/voices/`
2. Add the matching language handling in `scripts/cheer.sh`
3. Run `bash scripts/cheer.sh test` to verify the output

## 📝 License

MIT © chinadbo

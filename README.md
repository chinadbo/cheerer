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

### Method 1: Claude Code plugin (recommended)

```bash
# Clone the repository
git clone https://github.com/chinadbo/cheerer.git ~/.cheerer

# Make the main script and subdirectory scripts executable
chmod +x ~/.cheerer/scripts/cheer.sh
chmod +x ~/.cheerer/scripts/animations/*.sh
chmod +x ~/.cheerer/scripts/voices/*.sh
```

Configure hooks in Claude Code `~/.claude/settings.json`:

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
    ],
    "TaskCompleted": [
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

### Method 2: Manual hook setup (for local testing)

If you install cheerer somewhere other than `~/.cheerer`, replace the command path with your local path and add this to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/cheerer/scripts/cheer.sh"
          }
        ]
      }
    ],
    "TaskCompleted": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/cheerer/scripts/cheer.sh"
          }
        ]
      }
    ]
  }
}
```

## 🚀 Usage

### Run directly (for testing)

```bash
# Random animation + Chinese encouragement
./scripts/cheer.sh

# Choose a language
./scripts/cheer.sh en    # English
./scripts/cheer.sh zh    # Chinese (default)
./scripts/cheer.sh ja    # Japanese

# Choose an animation with env vars
CHEERER_ANIM=basketball ./scripts/cheer.sh
CHEERER_ANIM=dance ./scripts/cheer.sh
CHEERER_ANIM=fireworks ./scripts/cheer.sh

# Choose language with env vars (highest priority)
CHEERER_LANG=en ./scripts/cheer.sh
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

| Variable | Description | Values |
|------|------|--------|
| `CHEERER_LANG` | Language (higher priority than CLI args) | `zh` / `en` / `ja` |
| `CHEERER_ANIM` | Force a specific animation | `basketball` / `dance` / `fireworks` |
| `CHEERER_ENABLED` | Master switch | `true` / `false` |
| `CHEERER_VOICE` | Enable or disable voice | `on` / `off` / `true` / `false` |
| `CHEERER_COOLDOWN` | Cooldown seconds between triggers | positive integer |

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

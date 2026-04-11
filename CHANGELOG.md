# CHANGELOG

## [2.0.0] - 2026-04-11

- Replaced pixel-art frame animations with danmaku (bullet-screen) floating-subtitle engine
- Added three new animations: rocket, trophy, wave (six total)
- Added two new languages: Korean (ko), Spanish (es) (five total)
- Animation auto-discovery — drop a `.sh` file in `scripts/animations/`, no registration needed
- Shared danmaku engine (`scripts/lib/animation.sh`) with configurable rows, speeds, and delays
- Context-aware celebration pipeline (tier/mood/style/intensity/duration)
- First-run welcome message
- `cheer --preview [name]` and `cheer --list` CLI commands
- Voice-text alignment — voice scripts read `CHEERER_MESSAGE` instead of separate arrays
- Per-trigger history log (`history.log`) with auto-trim to 50 rows
- Milestone celebrations at 10, 25, 50, 100, 250, 500, 1000 triggers
- Expanded message catalogs (~30 messages per language)
- `CHEERER_STYLE` (adaptive/balanced/hype/cozy) and `CHEERER_INTENSITY` (soft/normal/high) controls
- Message sanitization to prevent ANSI injection in danmaku text

## [1.0.0] - 2026-04-07

- Initial release of cheerer
- Pixel terminal animations: basketball, dance, fireworks
- Multilingual voice encouragement: Chinese, English, Japanese
- Random animation and language selection
- Claude Code hooks integration for Stop and TaskCompleted
- Environment variable support for language, animation, voice, enable switch, and cooldown
- Dumb terminal fallback and non-blocking shell execution

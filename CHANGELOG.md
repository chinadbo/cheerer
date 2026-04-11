# CHANGELOG

## [2.1.1] - 2026-04-11

### Bug Fixes

- Fixed multi-byte character clipping in danmaku animation — `${text:$clip}` used character offset for a column-based value, corrupting CJK/emoji at left edge; now skips by accumulated display width
- Fixed temp file leak in `state_most_used()` — replaced `mktemp` + file pipeline with inline pipe, no orphan files on early exit
- Fixed milestone message unbounded length — capped concatenation at 60 chars to prevent terminal width overflow in danmaku
- Fixed cooldown race condition — timestamp write moved before `render_emit` so concurrent processes see the lock immediately
- Fixed silent animation discovery failure — added directory existence check before glob; falls back gracefully if ANIM_DIR missing
- Fixed invalid animation name accepted — `CHEERER_ANIM` now validates the `.sh` file exists before using it; falls back to random

## [2.1.0] - 2026-04-11

### Bug Fixes

- Fixed midnight crash in time-of-day mood adjustment — `hour="${hour#0}"` replaced with `hour=$((10#$hour))` for forced decimal interpretation
- Fixed fragile JSON parsing in state.sh and bin/cheer — replaced `grep -o` with bash parameter expansion
- Fixed cooldown race condition — timestamp write moved after render_emit, skipped during cooldown
- Fixed display width calculation — ALL characters were getting width 2 because `[[:ascii:]]` doesn't work in bash `[[ =~ ]]`; replaced with UTF-8 byte-length approach
- Fixed fragile version extraction in bin/cheer — replaced `grep | cut` with precise `sed -n` anchoring

### Features

- Added `--help` flag with usage info and all environment variable documentation
- Added `--config` flag to display current effective configuration values
- Added `--disable` / `--enable` toggle with secure config.sh sourcing (only CHEERER_* assignments allowed)
- Added message fatigue detection — same message excluded after 3+ appearances in last 5 history entries
- Added `CHEERER_ANIM_DURATION` environment variable override for animation frame count (min: 5)

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

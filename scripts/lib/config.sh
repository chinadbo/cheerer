#!/bin/bash
# scripts/lib/config.sh — Shared config loading and normalization for cheerer.
# Sourced by scripts/cheer.sh and bin/cheer.  Must be pure Bash, no set -e.

# ---------------------------------------------------------------------------
# config_data_dir() — returns the cheerer data directory path (no side effects)
# ---------------------------------------------------------------------------
config_data_dir() {
  printf '%s' "${CLAUDE_PLUGIN_DATA:-$HOME/.config/cheerer}"
}

# ---------------------------------------------------------------------------
# config_file_path() — returns the config file path
# ---------------------------------------------------------------------------
config_file_path() {
  printf '%s/config.sh' "$(config_data_dir)"
}

# ---------------------------------------------------------------------------
# config_load_file(file) — safely source a cheerer config file.
# Loads only when the file:
#   - exists
#   - contains at least one CHEERER_*= assignment
#   - contains NO lines that are not a comment, blank, or CHEERER_*= assignment
#   - all CHEERER_*= values contain only safe characters (no shell metacharacters)
#
# Safe value characters: letters, digits, and _-./: @ space only.
# This explicitly blocks inline command injection such as:
#   CHEERER_LANG=en; rm -rf /
# ---------------------------------------------------------------------------
config_load_file() {
  local _file="${1:-}"
  [[ -n "$_file" ]] || return 0
  [[ -f "$_file" ]] || return 0

  # Must have at least one CHEERER_*= line
  grep -qE '^[[:space:]]*CHEERER_[A-Z_]+=' "$_file" 2>/dev/null || return 0

  # Must NOT contain any line that is not: blank, comment, or CHEERER_*= assignment
  # Value portion is restricted to safe characters: no ;|&$`(){}<>!\
  if grep -qvE '^[[:space:]]*(CHEERER_[A-Z_]+=[A-Za-z0-9_./:@ -]*|#.*|[[:space:]]*)$' "$_file" 2>/dev/null; then
    return 0
  fi

  # Safe to source
  . "$_file"
}

# ---------------------------------------------------------------------------
# config_apply_defaults() — set CHEERER_* variables from plugin options /
# environment, then normalize to known-good values.
# ---------------------------------------------------------------------------
config_apply_defaults() {
  CHEERER_ENABLED="${CHEERER_ENABLED:-true}"
  CHEERER_LANG="${CHEERER_LANG:-${CLAUDE_PLUGIN_OPTION_LANG:-zh}}"
  CHEERER_ANIM="${CHEERER_ANIM:-${CLAUDE_PLUGIN_OPTION_ANIM:-random}}"
  CHEERER_VOICE="${CHEERER_VOICE:-${CLAUDE_PLUGIN_OPTION_VOICE:-on}}"
  CHEERER_STYLE="${CHEERER_STYLE:-${CLAUDE_PLUGIN_OPTION_STYLE:-adaptive}}"
  CHEERER_INTENSITY="${CHEERER_INTENSITY:-${CLAUDE_PLUGIN_OPTION_INTENSITY:-normal}}"
  CHEERER_DUMB="${CHEERER_DUMB:-auto}"
  CHEERER_MODE="${CHEERER_MODE:-auto}"
  CHEERER_COOLDOWN="${CHEERER_COOLDOWN:-3}"
  CHEERER_ANIM_DURATION="${CHEERER_ANIM_DURATION:-30}"
  CHEERER_EPIC="${CHEERER_EPIC:-false}"
  CHEERER_EPIC_THRESHOLD="${CHEERER_EPIC_THRESHOLD:-60}"

  # Normalize to valid enumerations
  case "$CHEERER_LANG"      in zh|en|ja|ko|es)             ;; *) CHEERER_LANG="zh"       ;; esac
  case "$CHEERER_STYLE"     in adaptive|balanced|hype|cozy) ;; *) CHEERER_STYLE="adaptive" ;; esac
  case "$CHEERER_INTENSITY" in soft|normal|high)            ;; *) CHEERER_INTENSITY="normal" ;; esac
  case "$CHEERER_DUMB"      in auto|true|false)             ;; *) CHEERER_DUMB="auto"     ;; esac
  case "$CHEERER_MODE"      in auto|full|text)              ;; *) CHEERER_MODE="auto"     ;; esac
}

# ---------------------------------------------------------------------------
# config_resolve_runtime_flags() — convert CHEERER_DUMB=auto to true/false
# based on the current TERM value.
# ---------------------------------------------------------------------------
config_resolve_runtime_flags() {
  if [[ "${CHEERER_DUMB:-auto}" == "auto" ]]; then
    if [[ "${TERM:-}" == "dumb" ]] || [[ -z "${TERM:-}" ]]; then
      CHEERER_DUMB=true
    else
      CHEERER_DUMB=false
    fi
  fi
}

# ---------------------------------------------------------------------------
# config_ensure_data_dir() — create the data directory and export
# CHEERER_DATA_DIR pointing to it.
# ---------------------------------------------------------------------------
config_ensure_data_dir() {
  CHEERER_DATA_DIR="$(config_data_dir)"
  mkdir -p "$CHEERER_DATA_DIR" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# config_print_current() — print effective CHEERER_* values, one per line,
# using "  KEY=value" format (two leading spaces, matching bin/cheer output).
# ---------------------------------------------------------------------------
config_print_current() {
  printf "  CHEERER_ENABLED=%s\n"        "${CHEERER_ENABLED:-}"
  printf "  CHEERER_LANG=%s\n"           "${CHEERER_LANG:-}"
  printf "  CHEERER_ANIM=%s\n"           "${CHEERER_ANIM:-}"
  printf "  CHEERER_VOICE=%s\n"          "${CHEERER_VOICE:-}"
  printf "  CHEERER_STYLE=%s\n"          "${CHEERER_STYLE:-}"
  printf "  CHEERER_INTENSITY=%s\n"      "${CHEERER_INTENSITY:-}"
  printf "  CHEERER_MODE=%s\n"           "${CHEERER_MODE:-}"
  printf "  CHEERER_DUMB=%s\n"           "${CHEERER_DUMB:-}"
  printf "  CHEERER_COOLDOWN=%s\n"       "${CHEERER_COOLDOWN:-}"
  printf "  CHEERER_ANIM_DURATION=%s\n"  "${CHEERER_ANIM_DURATION:-}"
  printf "  CHEERER_EPIC=%s\n"           "${CHEERER_EPIC:-}"
  printf "  CHEERER_EPIC_THRESHOLD=%s\n" "${CHEERER_EPIC_THRESHOLD:-}"
}

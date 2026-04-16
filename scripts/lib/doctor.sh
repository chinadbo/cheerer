#!/bin/bash
# scripts/lib/doctor.sh — Read-only diagnostics for cheerer.
# Sourced by tests and by bin/cheer --doctor.
# Must not call any mutating functions (no mkdir, no file writes).
# Requires: config.sh and catalog.sh already sourced.

# Internal state: parallel arrays of level + message
_DOCTOR_LEVELS=()
_DOCTOR_MESSAGES=()
_DOCTOR_HAS_FAIL=0
# Temp file path derived from the shell's top-level PID ($$) so it is the
# same value in both the parent shell and any subshells it spawns.
_DOCTOR_FAIL_FILE="${TMPDIR:-/tmp}/cheerer-doctor-$$.tmp"

# ---------------------------------------------------------------------------
# doctor_reset() — clear accumulated results (call before a fresh run).
# Resets the temp file so doctor_exit_code works after a subshell.
# ---------------------------------------------------------------------------
doctor_reset() {
  _DOCTOR_LEVELS=()
  _DOCTOR_MESSAGES=()
  _DOCTOR_HAS_FAIL=0
  printf '0' > "$_DOCTOR_FAIL_FILE"
}

# ---------------------------------------------------------------------------
# _doctor_record(level, message) — internal: append one result line
# ---------------------------------------------------------------------------
_doctor_record() {
  local level="$1"
  local msg="$2"
  _DOCTOR_LEVELS+=("$level")
  _DOCTOR_MESSAGES+=("$msg")
  if [[ "$level" == "FAIL" ]]; then
    _DOCTOR_HAS_FAIL=1
    # Persist FAIL flag to the temp file so the parent shell can read it
    printf '1' > "$_DOCTOR_FAIL_FILE"
  fi
}

# ---------------------------------------------------------------------------
# doctor_check_config() — inspect config file load status
# Calls config_load_file() to populate CONFIG_LOAD_STATUS, then records
# a PASS/WARN/FAIL line describing the result.  Read-only: uses a temp
# config path derived from CHEERER_DATA_DIR (already set by caller).
# ---------------------------------------------------------------------------
doctor_check_config() {
  local cfg_path
  cfg_path="${CHEERER_DATA_DIR}/config.sh"

  # Re-invoke the safe loader to populate CONFIG_LOAD_STATUS
  config_load_file "$cfg_path"

  case "${CONFIG_LOAD_STATUS:-missing}" in
    missing)
      _doctor_record "PASS" "config file not present; defaults apply"
      ;;
    accepted)
      _doctor_record "PASS" "config file loaded from ${cfg_path}"
      ;;
    ignored)
      _doctor_record "WARN" "config file present but failed safety checks; defaults apply"
      ;;
    *)
      _doctor_record "WARN" "config load status unknown: ${CONFIG_LOAD_STATUS}"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# doctor_check_runtime() — resolve effective output mode and report it
# ---------------------------------------------------------------------------
doctor_check_runtime() {
  local effective_mode
  local dumb="${CHEERER_DUMB:-auto}"
  local mode="${CHEERER_MODE:-auto}"

  # Resolve dumb terminal flag if still auto
  if [[ "$dumb" == "auto" ]]; then
    if [[ "${TERM:-}" == "dumb" ]] || [[ -z "${TERM:-}" ]]; then
      dumb="true"
    else
      dumb="false"
    fi
  fi

  # Resolve mode
  if [[ "$mode" == "auto" ]]; then
    if [[ "$dumb" == "true" ]]; then
      effective_mode="text"
    else
      effective_mode="full"
    fi
  else
    effective_mode="$mode"
  fi

  _doctor_record "PASS" "runtime mode resolved to ${effective_mode}"
}

# ---------------------------------------------------------------------------
# doctor_check_assets() — verify data dir, animations dir, configured
# animation script, and voice script.
# ---------------------------------------------------------------------------
doctor_check_assets() {
  local data_dir="${CHEERER_DATA_DIR:-}"
  local anim_dir="${ANIM_DIR:-}"
  local voice_dir="${VOICE_DIR:-}"
  local lang="${CHEERER_LANG:-en}"
  local anim="${CHEERER_ANIM:-random}"

  # Data directory writability (read-only check: test -w, no mkdir)
  if [[ -d "$data_dir" ]] && [[ -w "$data_dir" ]]; then
    _doctor_record "PASS" "plugin data directory writable"
  elif [[ ! -d "$data_dir" ]]; then
    _doctor_record "WARN" "plugin data directory does not exist: ${data_dir}"
  else
    _doctor_record "FAIL" "plugin data directory not writable: ${data_dir}"
  fi

  # Animations directory
  if [[ -d "$anim_dir" ]]; then
    _doctor_record "PASS" "animations directory found"
  else
    _doctor_record "FAIL" "animations directory missing: ${anim_dir}"
  fi

  # Configured animation (only checked when not random/epic)
  if [[ "$anim" != "random" ]] && [[ "$anim" != "epic" ]]; then
    local anim_script="${anim_dir}/${anim}.sh"
    if [[ -f "$anim_script" ]]; then
      _doctor_record "PASS" "configured animation '${anim}' found"
    else
      _doctor_record "FAIL" "configured animation '${anim}' missing script"
    fi
  fi

  # Voice script (WARN only — optional feature)
  local voice_script="${voice_dir}/cheer_${lang}.sh"
  if [[ -f "$voice_script" ]]; then
    _doctor_record "PASS" "voice script exists for lang=${lang}"
  else
    _doctor_record "WARN" "voice script missing for lang=${lang}"
  fi
}

# ---------------------------------------------------------------------------
# doctor_check_catalog() — validate the message catalog for CHEERER_LANG
# ---------------------------------------------------------------------------
doctor_check_catalog() {
  local lang="${CHEERER_LANG:-en}"

  # Temporarily point CHEERER_ROOT so catalog_path_for_lang resolves correctly
  local saved_root="${CHEERER_ROOT:-}"
  if catalog_validate_lang "$lang" 2>/dev/null; then
    _doctor_record "PASS" "catalog coverage valid for ${lang}"
  else
    _doctor_record "FAIL" "catalog coverage invalid for ${lang}"
  fi
  CHEERER_ROOT="$saved_root"
}

# ---------------------------------------------------------------------------
# doctor_check_optional_files() — check for optional custom messages file
# ---------------------------------------------------------------------------
doctor_check_optional_files() {
  local data_dir="${CHEERER_DATA_DIR:-}"
  local custom_file="${data_dir}/custom-messages.txt"

  if [[ -f "$custom_file" ]]; then
    _doctor_record "PASS" "custom messages file found"
  else
    _doctor_record "WARN" "custom messages file not found"
  fi
}

# ---------------------------------------------------------------------------
# doctor_print_report() — print accumulated PASS/WARN/FAIL lines to stdout
# ---------------------------------------------------------------------------
doctor_print_report() {
  local i
  printf '\n  cheerer — Doctor\n\n'
  for ((i = 0; i < ${#_DOCTOR_LEVELS[@]}; i++)); do
    printf '%s %s\n' "${_DOCTOR_LEVELS[$i]}" "${_DOCTOR_MESSAGES[$i]}"
  done
}

# ---------------------------------------------------------------------------
# doctor_exit_code() — print 1 if any FAIL was recorded, else 0.
# Reads from the temp file so it works correctly even when the doctor
# check functions ran inside a subshell (e.g., output="$(run_...)" ).
# ---------------------------------------------------------------------------
doctor_exit_code() {
  if [[ -f "$_DOCTOR_FAIL_FILE" ]]; then
    local _code
    _code="$(cat "$_DOCTOR_FAIL_FILE")"
    printf '%s\n' "$_code"
  else
    printf '%d\n' "$_DOCTOR_HAS_FAIL"
  fi
}

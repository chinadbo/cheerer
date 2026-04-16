#!/bin/bash

catalog_path_for_lang() {
  local lang="$1"
  printf '%s/scripts/messages/catalog_%s.tsv' "${CHEERER_ROOT:-$PWD}" "$lang"
}

# Print the required tier|mood pairs, one per line.
catalog_required_pairs() {
  cat << 'EOF'
quick|gentle
quick|hype
quick|steady
quick|cozy
solid|steady
solid|rapid_fire
solid|cozy
solid|streak
solid|triumphant
big|triumphant
big|streak
big|hype
legendary|milestone
EOF
}

# Validate a single catalog file at the given path.
# Returns 0 on success; writes errors to stderr and returns 1 on any problem.
catalog_validate_file() {
  local path="$1"
  local errors=0
  local row_num=0
  local tier mood message_id message_text extra
  local seen_ids=""

  if [[ ! -f "$path" ]]; then
    printf 'catalog_validate_file: file not found: %s\n' "$path" >&2
    return 1
  fi

  while IFS='|' read -r tier mood message_id message_text extra; do
    row_num=$((row_num + 1))

    if [[ -z "$tier$mood$message_id$message_text${extra:-}" ]]; then
      continue
    fi

    if [[ -n "${extra:-}" ]] || [[ -z "$tier" ]] || [[ -z "$mood" ]] || [[ -z "$message_id" ]] || [[ -z "$message_text" ]]; then
      printf 'catalog_validate_file: malformed row %s in %s\n' "$row_num" "$path" >&2
      errors=$((errors + 1))
      continue
    fi

    if [[ "$seen_ids" == *"|${message_id}|"* ]]; then
      printf 'catalog_validate_file: duplicate message_id %s in %s\n' "$message_id" "$path" >&2
      errors=$((errors + 1))
    else
      seen_ids="${seen_ids}|${message_id}|"
    fi
  done < "$path"

  local pair
  while IFS= read -r pair; do
    [[ -z "$pair" ]] && continue
    local req_tier req_mood
    req_tier="${pair%%|*}"
    req_mood="${pair#*|}"
    if ! grep -qF "${req_tier}|${req_mood}|" "$path"; then
      printf 'catalog_validate_file: missing required pair %s in %s\n' "$pair" "$path" >&2
      errors=$((errors + 1))
    fi
  done <<< "$(catalog_required_pairs)"

  [[ "$errors" -eq 0 ]]
}

# Validate the catalog for a single language.
catalog_validate_lang() {
  local lang="$1"
  local path
  path="$(catalog_path_for_lang "$lang")"
  catalog_validate_file "$path"
}

# Validate all shipped locale catalogs.
catalog_validate_all() {
  local lang
  local errors=0
  for lang in en es ja ko zh; do
    if ! catalog_validate_lang "$lang"; then
      errors=$((errors + 1))
    fi
  done
  [[ "$errors" -eq 0 ]]
}

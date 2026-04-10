#!/bin/bash
set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0

pass() {
  printf 'PASS: %s\n' "$1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  printf 'FAIL: %s\n' "$1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  if [[ "$expected" != "$actual" ]]; then
    printf 'expected [%s] got [%s]\n' "$expected" "$actual"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  printf '%s' "$haystack" | grep -F "$needle" >/dev/null 2>&1
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if printf '%s' "$haystack" | grep -F "$needle" >/dev/null 2>&1; then
    printf 'did not expect to find [%s]\n' "$needle"
    return 1
  fi
}

run_test() {
  local name="$1"
  shift
  if "$@"; then
    pass "$name"
  else
    fail "$name"
  fi
}

make_tmp_dir() {
  mktemp -d "${TMPDIR:-/tmp}/cheerer-tests.XXXXXX"
}

finish_tests() {
  printf '\n%d passed, %d failed\n' "$PASS_COUNT" "$FAIL_COUNT"
  [[ "$FAIL_COUNT" -eq 0 ]]
}

#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$ROOT_DIR/tests/test_lib.sh"

test_ci_workflow_runs_full_suite() {
  local workflow
  workflow="$(< "$ROOT_DIR/.github/workflows/ci.yml")"
  assert_contains "$workflow" "bash tests/run.sh all"
}

test_ci_workflow_shellchecks_shared_libs_and_tests() {
  local workflow
  workflow="$(< "$ROOT_DIR/.github/workflows/ci.yml")"
  assert_contains "$workflow" "scripts/lib/*.sh"
  assert_contains "$workflow" "tests/*.sh"
}

test_run_sh_all_includes_hardening_suites() {
  local runner
  runner="$(< "$ROOT_DIR/tests/run.sh")"
  assert_contains "$runner" "bash tests/config_test.sh"
  assert_contains "$runner" "bash tests/context_test.sh"
  assert_contains "$runner" "bash tests/catalog_test.sh"
  assert_contains "$runner" "bash tests/doctor_test.sh"
  assert_contains "$runner" "bash tests/explain_test.sh"
  assert_contains "$runner" "bash tests/ci_test.sh"
}

test_run_sh_supports_named_hardening_suites() {
  local runner
  runner="$(< "$ROOT_DIR/tests/run.sh")"
  assert_contains "$runner" "config)"
  assert_contains "$runner" "context)"
  assert_contains "$runner" "catalog)"
  assert_contains "$runner" "doctor)"
  assert_contains "$runner" "explain)"
  assert_contains "$runner" "ci)"
}

test_cheer_script_does_not_redefault_anim_duration_after_config() {
  local cheer_script
  cheer_script="$(< "$ROOT_DIR/scripts/cheer.sh")"
  assert_contains "$cheer_script" 'export CHEERER_ANIM_DURATION'
  assert_not_contains "$cheer_script" 'export CHEERER_ANIM_DURATION="${CHEERER_ANIM_DURATION:-}"'
}

run_test "ci_workflow_runs_full_suite" test_ci_workflow_runs_full_suite
run_test "ci_workflow_shellchecks_shared_libs_and_tests" test_ci_workflow_shellchecks_shared_libs_and_tests
run_test "run_sh_all_includes_hardening_suites" test_run_sh_all_includes_hardening_suites
run_test "run_sh_supports_named_hardening_suites" test_run_sh_supports_named_hardening_suites
run_test "cheer_script_does_not_redefault_anim_duration_after_config" test_cheer_script_does_not_redefault_anim_duration_after_config
finish_tests

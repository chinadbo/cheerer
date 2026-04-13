#!/bin/bash
set -euo pipefail

. tests/test_lib.sh

test_ci_workflow_runs_full_suite() {
  local workflow
  workflow="$(< .github/workflows/ci.yml)"
  assert_contains "$workflow" "bash tests/run.sh all"
}

test_ci_workflow_shellchecks_shared_libs_and_tests() {
  local workflow
  workflow="$(< .github/workflows/ci.yml)"
  assert_contains "$workflow" "scripts/lib/*.sh"
  assert_contains "$workflow" "tests/*.sh"
}

test_run_sh_all_includes_hardening_suites() {
  local runner
  runner="$(< tests/run.sh)"
  assert_contains "$runner" "bash tests/config_test.sh"
  assert_contains "$runner" "bash tests/context_test.sh"
  assert_contains "$runner" "bash tests/ci_test.sh"
}

test_run_sh_supports_named_hardening_suites() {
  local runner
  runner="$(< tests/run.sh)"
  assert_contains "$runner" "config)"
  assert_contains "$runner" "context)"
  assert_contains "$runner" "ci)"
}

run_test "ci_workflow_runs_full_suite" test_ci_workflow_runs_full_suite
run_test "ci_workflow_shellchecks_shared_libs_and_tests" test_ci_workflow_shellchecks_shared_libs_and_tests
run_test "run_sh_all_includes_hardening_suites" test_run_sh_all_includes_hardening_suites
run_test "run_sh_supports_named_hardening_suites" test_run_sh_supports_named_hardening_suites
finish_tests

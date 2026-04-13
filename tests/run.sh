#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

case "${1:-all}" in
  state)
    bash tests/state_test.sh
    ;;
  policy)
    bash tests/policy_test.sh
    ;;
  render)
    bash tests/render_test.sh
    ;;
  integration)
    bash tests/integration_test.sh
    ;;
  config)
    bash tests/config_test.sh
    ;;
  context)
    bash tests/context_test.sh
    ;;
  ci)
    bash tests/ci_test.sh
    ;;
  all)
    bash tests/state_test.sh
    bash tests/policy_test.sh
    bash tests/render_test.sh
    bash tests/integration_test.sh
    bash tests/config_test.sh
    bash tests/context_test.sh
    bash tests/ci_test.sh
    ;;
  *)
    echo "usage: bash tests/run.sh [state|policy|render|integration|config|context|ci|all]"
    exit 1
    ;;
esac


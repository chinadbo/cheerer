#!/bin/bash
# install-hooks.sh — install git hooks for cheerer development
# Run once after cloning: bash scripts/install-hooks.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.git/hooks"

if [[ ! -d "$HOOKS_DIR" ]]; then
  echo "Error: .git/hooks not found. Are you inside the git repo?" >&2
  exit 1
fi

cat > "$HOOKS_DIR/pre-commit" << 'HOOK'
#!/bin/bash
# pre-commit: run shellcheck + secrets scan before every commit
set -e
REPO_ROOT="$(git rev-parse --show-toplevel)"

echo "→ Running shellcheck..."
shellcheck --severity=error \
  "$REPO_ROOT/scripts/cheer.sh" \
  "$REPO_ROOT/scripts/animations/"*.sh \
  "$REPO_ROOT/scripts/voices/"*.sh \
  "$REPO_ROOT/bin/cheer"

echo "→ Scanning for secrets..."
bash "$REPO_ROOT/scripts/check-secrets.sh"
HOOK

chmod +x "$HOOKS_DIR/pre-commit"
echo "✓ pre-commit hook installed at $HOOKS_DIR/pre-commit"
echo "  Runs: shellcheck + secrets scan before every commit"

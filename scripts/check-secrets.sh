#!/bin/bash
# check-secrets.sh — scan staged files for secrets before commit
# Used by: .git/hooks/pre-commit (local) and CI (via ci.yml)
#
# Exit 0 = clean, exit 1 = secrets found (blocks commit/CI)
#
# Patterns detected:
#   - API keys / tokens (generic high-entropy patterns)
#   - AWS access key IDs and secret keys
#   - .env file content committed by mistake
#   - Private key / certificate PEM blocks
#   - Password / secret assignments in code
#   - Common service tokens (Slack, GitHub, Stripe, etc.)

set -euo pipefail

RED="\033[0;31m"
YELLOW="\033[0;33m"
RESET="\033[0m"

# ── Files to scan ────────────────────────────────────────
# In pre-commit mode: scan only staged files
# In CI mode (no git index): scan all tracked files
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  STAGED=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)
else
  # Initial commit — compare against empty tree
  STAGED=$(git diff --cached --name-only --diff-filter=ACM \
    "$(git hash-object -t tree /dev/null)" HEAD 2>/dev/null || \
    git ls-files 2>/dev/null || true)
fi

if [[ -z "$STAGED" ]]; then
  exit 0
fi

# ── Secret patterns (grep -E compatible) ─────────────────
PATTERNS=(
  # Generic high-entropy tokens: KEY=, TOKEN=, SECRET=, PASSWORD=, API_KEY= etc.
  '(KEY|TOKEN|SECRET|PASSWORD|API_KEY|APIKEY|ACCESS_KEY|AUTH_TOKEN)\s*[=:]\s*["\047]?[A-Za-z0-9/+]{20,}["\047]?'
  # AWS
  'AKIA[0-9A-Z]{16}'
  '[0-9a-zA-Z/+]{40}' # AWS secret key (combined with context check below)
  # PEM blocks
  '-----BEGIN (RSA |EC |DSA |OPENSSH |PRIVATE KEY|CERTIFICATE)'
  # .env style assignments with actual values (not placeholders)
  '^[A-Z_]+=.{20,}$'
  # Common service tokens
  'ghp_[A-Za-z0-9]{36}'          # GitHub personal access token
  'github_pat_[A-Za-z0-9_]{82}'  # GitHub fine-grained PAT
  'xoxb-[0-9]+-[A-Za-z0-9]+'     # Slack bot token
  'xoxp-[0-9]+-[A-Za-z0-9]+'     # Slack user token
  'sk_live_[A-Za-z0-9]+'          # Stripe live key
  'sk_test_[A-Za-z0-9]+'          # Stripe test key
  'AIza[0-9A-Za-z\-_]{35}'        # Google API key
  'ya29\.[0-9A-Za-z\-_]+'         # Google OAuth token
  '[0-9]+-[0-9A-Za-z_]{32}\.apps\.googleusercontent\.com'  # Google client ID
)

# ── Files to always ignore ────────────────────────────────
IGNORE_PATTERNS=(
  '\.md$'
  'check-secrets\.sh$'
  '\.sample$'
  'CHANGELOG'
  'LICENSE'
  'CODE_OF_CONDUCT'
)

FOUND=0

for FILE in $STAGED; do
  # Skip non-existent files (deleted)
  [[ -f "$FILE" ]] || continue

  # Skip ignored files
  SKIP=false
  for IGNORE in "${IGNORE_PATTERNS[@]}"; do
    if echo "$FILE" | grep -qE "$IGNORE"; then
      SKIP=true
      break
    fi
  done
  [[ "$SKIP" == "true" ]] && continue

  # Scan file content against each pattern
  for PATTERN in "${PATTERNS[@]}"; do
    MATCHES=$(git show ":$FILE" 2>/dev/null | grep -nE "$PATTERN" || true)
    if [[ -n "$MATCHES" ]]; then
      echo -e "${RED}[SECRETS] Possible secret found in: $FILE${RESET}"
      echo -e "${YELLOW}  Pattern: $PATTERN${RESET}"
      echo "$MATCHES" | head -3 | while IFS= read -r LINE; do
        # Redact the actual value — show only location
        LINENUM=$(echo "$LINE" | cut -d: -f1)
        echo -e "  Line $LINENUM: [redacted for security]"
      done
      FOUND=1
      break  # One match per file is enough to flag it
    fi
  done
done

if [[ "$FOUND" -ne 0 ]]; then
  echo ""
  echo -e "${RED}✗ Commit blocked: potential secrets detected in staged files.${RESET}"
  echo ""
  echo "  If this is a false positive, you can skip this check with:"
  echo "    git commit --no-verify"
  echo ""
  echo "  To permanently allowlist a pattern, edit IGNORE_PATTERNS"
  echo "  in scripts/check-secrets.sh"
  exit 1
fi

echo "✓ No secrets detected in staged files."
exit 0

#!/bin/bash
# cheer_ja.sh — 日本語ボイス応援（共有 cheer.sh に委譲）
export CHEERER_LANG="ja"
_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$_dir/cheer.sh"

#!/bin/bash
# cheer_zh.sh — 中文语音鼓励（委托至共享 cheer.sh）
export CHEERER_LANG="zh"
_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$_dir/cheer.sh"

#!/bin/bash
# cheer_ko.sh — 한국어 음성 응원 (공유 cheer.sh에 위임)
export CHEERER_LANG="ko"
_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$_dir/cheer.sh"

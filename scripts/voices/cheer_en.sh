#!/bin/bash
# cheer_en.sh — English voice cheers (delegates to shared cheer.sh)
export CHEERER_LANG="en"
_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$_dir/cheer.sh"

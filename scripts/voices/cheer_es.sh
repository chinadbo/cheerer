#!/bin/bash
# cheer_es.sh — Voces de ánimo en español (delega a cheer.sh compartido)
export CHEERER_LANG="es"
_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$_dir/cheer.sh"

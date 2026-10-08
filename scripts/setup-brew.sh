#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_platform
require_commands brew

case "${1:-}" in
  '') export HOMEBREW_BUNDLE_NO_UPGRADE=1 ;;
  --upgrade) unset HOMEBREW_BUNDLE_NO_UPGRADE ;;
  *) printf 'Usage: %s [--upgrade]\n' "$0" >&2; exit 2 ;;
esac
if [[ $# -gt 1 ]]; then
  printf 'Usage: %s [--upgrade]\n' "$0" >&2
  exit 2
fi

# No dump/cleanup: preserve the curated list and all unmanaged applications.
unset HOMEBREW_BUNDLE_INSTALL_CLEANUP HOMEBREW_BUNDLE_FORCE_INSTALL_CLEANUP
export HOMEBREW_NO_INSTALL_CLEANUP=1
brew bundle install --file="$DOTFILES_ROOT/Brewfile"

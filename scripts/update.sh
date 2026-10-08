#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_platform
require_commands brew nix

# Update declared applications; runtime pins and flake.lock stay intact.
bash "$DOTFILES_ROOT/scripts/setup-brew.sh" --upgrade
apply_home_manager
bash "$DOTFILES_ROOT/scripts/setup-mise.sh"
printf '%s\n' 'Update complete. Runtime versions still match programs/mise/config.toml.'

#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_platform
require_commands brew nix

# Install applications before rendering settings which refer to their binaries.
bash "$DOTFILES_ROOT/scripts/setup-brew.sh"
apply_home_manager
bash "$DOTFILES_ROOT/scripts/setup-mise.sh"
printf '%s\n' 'Setup complete. Start a new login shell: exec zsh -l'

#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_platform
require_commands brew
MISE_BIN="$(brew --prefix)/bin/mise"
if [[ ! -x "$MISE_BIN" ]]; then
  printf '%s\n' 'Install mise with scripts/setup-brew.sh first.' >&2
  exit 1
fi

# Use the checked-in defaults even before Home Manager is applied.
# Run outside the caller's project so its tools/hooks cannot affect setup.
export MISE_GLOBAL_CONFIG_FILE="$DOTFILES_ROOT/programs/mise/config.toml"
"$MISE_BIN" --cd "$DOTFILES_ROOT" install
"$MISE_BIN" --cd "$DOTFILES_ROOT" reshim

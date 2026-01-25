#!/usr/bin/env bash

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ ${NC}$1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }

echo "Updating dotfiles..."

cd "$HOME/dotfiles"

# Git pull
log_info "Pulling latest changes from remote..."
git pull

# Flakeの更新
log_info "Updating Nix flake inputs..."
nix flake update

# Home Managerの再適用
log_info "Applying Home Manager configuration..."
home-manager switch --flake .

# mise toolsの更新
log_info "Updating mise tools..."
mise upgrade

log_success "Update complete!"

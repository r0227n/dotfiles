#!/usr/bin/env bash

set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() { echo -e "${BLUE}ℹ ${NC}$1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# エラーハンドリング
trap 'log_error "Installation failed at line $LINENO"' ERR

echo "
╔═══════════════════════════════════════╗
║   Dotfiles Installation Script        ║
║   Nix + Home Manager + mise           ║
╚═══════════════════════════════════════╝
"

# Nixのインストールチェック
if ! command -v nix &> /dev/null; then
    log_info "Installing Nix..."
    sh <(curl -L https://nixos.org/nix/install) --daemon

    log_info "Enabling Nix Flakes..."
    mkdir -p ~/.config/nix
    cat > ~/.config/nix/nix.conf << EOF
experimental-features = nix-command flakes
EOF

    log_success "Nix installed successfully"
    log_warning "Please restart your shell and run this script again"
    exit 0
fi

log_success "Nix is already installed"

# Nix Flakesの有効化確認
if [ ! -f ~/.config/nix/nix.conf ] || ! grep -q "experimental-features.*nix-command.*flakes" ~/.config/nix/nix.conf 2>/dev/null; then
    log_info "Enabling Nix Flakes..."
    mkdir -p ~/.config/nix
    cat > ~/.config/nix/nix.conf << EOF
experimental-features = nix-command flakes
EOF
    log_success "Nix Flakes enabled"
fi

# dotfilesのクローン
DOTFILES_DIR="$HOME/dotfiles"

if [ ! -d "$DOTFILES_DIR" ]; then
    log_info "Cloning dotfiles repository..."

    # GitHubのユーザー名を入力
    read -p "Enter your GitHub username: " GITHUB_USER

    git clone "https://github.com/$GITHUB_USER/dotfiles.git" "$DOTFILES_DIR"
    log_success "Dotfiles cloned successfully"
else
    log_warning "Dotfiles directory already exists"
fi

cd "$DOTFILES_DIR"

# flake.nixの確認
if [ ! -f "flake.nix" ]; then
    log_error "flake.nix not found in $DOTFILES_DIR"
    exit 1
fi

# Gitでファイルをステージング（Nix flakesに必要）
log_info "Staging files for Nix flakes..."
git add -A

# Home Managerのインストールと適用
log_info "Installing and applying Home Manager configuration..."
nix --extra-experimental-features "nix-command flakes" run home-manager/master -- switch --flake .

log_success "Home Manager applied successfully"

# miseのセットアップ
log_info "Setting up mise..."
bash "$DOTFILES_DIR/scripts/setup-mise.sh"

echo "
╔═══════════════════════════════════════╗
║   Installation Complete!              ║
╚═══════════════════════════════════════╝

Next steps:
1. Restart your shell: exec zsh
2. Navigate to a project directory
3. Run 'mise install' to install project tools
4. Enjoy your new development environment!
"

log_info "Please restart your shell: exec zsh"

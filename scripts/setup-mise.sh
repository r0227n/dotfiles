#!/usr/bin/env bash

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ ${NC}$1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }

log_info "Setting up mise..."

# 設定ディレクトリの作成
mkdir -p ~/.config/mise

# プラグインのインストール（必要に応じて）
log_info "Installing mise plugins..."

# よく使うツールのプラグインを追加
mise plugin install flutter https://github.com/oae/asdf-flutter.git || true
mise plugin install rust https://github.com/code-lever/asdf-rust.git || true
mise plugin install nodejs https://github.com/asdf-vm/asdf-nodejs.git || true

log_success "mise setup complete"

echo "
Available tools for installation:
  mise install flutter@latest
  mise install rust@latest
  mise install node@latest

Or navigate to a project with .mise.toml and run:
  mise install
"

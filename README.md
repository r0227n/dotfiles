# dotfiles

Nix + Home Manager + mise を使った宣言的な開発環境管理

## 概要

```
┌─────────────────────────────────────────────┐
│              Nix + Home Manager             │
│  ・システムレベルのツール                      │
│  ・エディタ、ターミナル、Git等                 │
│  ・mise本体のインストール                     │
└─────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────┐
│                   mise                      │
│  ・Flutter のバージョン管理                   │
│  ・Rust のバージョン管理                      │
│  ・Node.js のバージョン管理                   │
│  ・プロジェクトごとの環境切り替え              │
└─────────────────────────────────────────────┘
```

## 構成

```
~/dotfiles/
├── flake.nix              # Flakes設定（エントリーポイント）
├── home.nix               # Home Managerメイン設定
├── modules/
│   ├── common.nix         # 共通設定（XDG, direnv）
│   ├── darwin.nix         # macOS専用設定
│   └── fonts.nix          # Nerd Fonts
├── programs/
│   ├── neovim/            # Neovim + AstroVim
│   ├── wezterm/           # WezTerm設定
│   ├── shell/             # Zsh + Starship
│   ├── git/               # Git設定
│   ├── mise/              # mise設定
│   └── claude/            # Claude Code設定
├── scripts/
│   ├── install.sh         # 初回セットアップ
│   ├── update.sh          # 更新スクリプト
│   └── setup-mise.sh      # mise初期設定
└── README.md
```

## セットアップ

### 事前準備

```bash
# Nix インストール（未インストールの場合）
sh <(curl -L https://nixos.org/nix/install) --daemon

# Flakes 有効化
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

# シェル再起動
exec zsh
```

### インストール

```bash
# スクリプトで自動セットアップ
cd ~/dotfiles
./scripts/install.sh

# または手動で
nix run home-manager/master -- switch --flake .
```

### WezTerm（別途インストール）

```bash
brew install --cask wezterm
```

## 日常の使い方

### 設定の更新

```bash
# エイリアスを使用
nixup

# または
cd ~/dotfiles && home-manager switch --flake .
```

### flake の更新

```bash
cd ~/dotfiles
nix flake update
home-manager switch --flake .
```

### mise でツールを管理

```bash
# ツールのインストール
mise install flutter@latest
mise install rust@latest
mise install node@latest

# プロジェクトで使用するバージョンを指定
mise use flutter@3.19.0

# 現在のバージョン確認
mise current
```

## 便利なエイリアス

| エイリアス | コマンド |
|-----------|---------|
| `nixup` | Home Manager 設定を適用 |
| `nixclean` | Nix ガベージコレクション |
| `lg` | lazygit |
| `v` | nvim |
| `mi` | mise |
| `mii` | mise install |
| `mil` | mise list |

## API キーの設定

```bash
# ~/.zshrc.local を作成（gitignore対象）
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.zshrc.local
```

## トラブルシューティング

### ロールバック

```bash
# 前の世代を確認
home-manager generations

# ロールバック
home-manager switch --rollback
```

### キャッシュクリア

```bash
# Nix
nix-collect-garbage -d

# mise
rm -rf ~/.local/share/mise/downloads/*
```

## 参考リンク

- [Nix](https://nixos.org/)
- [Home Manager](https://nix-community.github.io/home-manager/)
- [mise](https://mise.jdx.dev/)

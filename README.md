# dotfiles

Apple Silicon macOS 向け。**ランタイムは mise、アプリ・一般 CLI は Homebrew、設定ファイルは Home Manager** で管理します。

## 管理する場所

| 対象 | 定義 |
| --- | --- |
| Flutter / Bun / Node.js / Rust / Python のバージョン | `programs/mise/config.toml` |
| アプリ、一般 CLI、mise 本体、エディタ、フォント | `Brewfile` |
| Xcode / Apple Developer（任意） | `Brewfile.mas` |
| Zsh / Git / Neovim / WezTerm / Claude などの設定 | `home.nix`、`programs/`、`modules/` |
| Home Manager と Nix 依存関係の固定 | `flake.lock` |

Homebrew にない `nil`（Nix LSP）と `nix-direnv` は Nix に残しています。macOS 標準の Zsh を使用します。
Brewfile は導入対象を宣言するファイルで、Homebrew の全バージョンを固定するロックファイルではありません。

## 管理対象外

- Hermes / hermes-agent（常駐処理を含む）
- Appium
- Deno
- idb-companion
- CuaDriver
- HHKB キーマップ変更ツール
- Raycast
- lazygit（設定・独自エイリアス・独自キーバインドを含む）
- lua-language-server / typescript-language-server / vscode-langservers-extracted
- block-goose-cli / opencode
- Tuist（tuist/tuist Tap を含む）/ xcodegen
- 1password-cli
- Zig

これらの導入・設定・削除は自動化しません。除外した LSP は LazyVim の既定設定からも起動しないようにしています。セットアップや更新は `brew bundle cleanup` を実行しません。
他ツールの依存として Homebrew が Node.js・Python・Deno などを導入する場合はあります。利用するランタイムは mise の shims を優先します。

## セットアップ

1. Xcode Command Line Tools、[Homebrew](https://brew.sh/)、[Nix](https://nixos.org/download/) を導入してください。
2. ログインシェルを開き、`brew` と `nix` が PATH 上にあることを確認してください。
3. このリポジトリを clone し、以下を実行します。

```bash
bash scripts/install.sh
exec zsh -l
```

スクリプトは自身の場所からリポジトリを特定するため、別ディレクトリから絶対パスで実行することもできます。
`flake.nix` のユーザー名は `r0227n`、アーキテクチャは `aarch64-darwin` です。
別ユーザー向けには、適用前に `flake.nix` のユーザー名を変更してください。

実行順序は以下です。

1. Brewfile の不足パッケージを導入（初回セットアップでは既存パッケージの更新を抑制）。
2. `flake.lock` で指定した Home Manager から設定を適用。
3. mise で指定バージョンのランタイムを導入し、shims を更新。

既存の未管理設定ファイルと衝突した場合、Home Manager は `before-dotfiles-日時` を付けてバックアップします。
アプリへのサインイン、macOS の権限承認、既存アプリの管理元移行については [setup.md](setup.md) を参照してください。

Mac App Store のアプリは、サインイン後に任意で追加します。

```bash
brew bundle --file=Brewfile.mas
```

## 更新

```bash
# 必要に応じて、先にリポジトリの変更を取り込む
# git pull --ff-only
bash scripts/update.sh
```

Brewfile の対象を更新し、Home Manager と mise の設定を再適用します。
`mise upgrade` や `nix flake update`、自動コミット・ステージングは実行しません。

ランタイムを更新するときは `programs/mise/config.toml` を編集してから、次を実行します。

```bash
bash scripts/setup-mise.sh
home-manager switch --flake .
```

`mise use --global` は Home Manager 管理下のファイルを書き換えるため使用せず、リポジトリ側を編集します。
各プロジェクトの `mise.toml` / `.mise.toml` でバージョンを上書きできます。
Nix の依存関係を更新するときは `nix flake update` を別途実行し、`flake.lock` の差分を確認してください。

## 個別の適用・確認

```bash
bash scripts/setup-brew.sh           # 不足分だけ導入
bash scripts/setup-brew.sh --upgrade # Brewfile の対象を更新
bash scripts/setup-mise.sh           # 指定したランタイムを導入
brew bundle list --file=Brewfile
brew bundle check --file=Brewfile
mise current
```

セットアップは、管理対象外のアプリや旧インストールを削除しません。既存 mise の追加ツールも残ります。
旧インストールの shim が Brewfile の CLI を隠す場合の確認方法は [setup.md](setup.md) に記載しています。

## 検証（実機への適用なし）

```bash
python3 -B -m unittest discover -s tests -v
for script in scripts/*.sh; do bash -n "$script"; done
zsh -n programs/shell/zshrc
zsh -n programs/shell/zprofile
ruby -c Brewfile
ruby -c Brewfile.mas
nix build --no-link --no-write-lock-file .#homeConfigurations.r0227n.activationPackage
```

テストは brew / nix / mise をモックし、実行順序、失敗時の停止、除外対象、バージョン指定の維持を確認します。
最後のコマンドは設定をビルドしますが、ホームディレクトリへの適用は行いません。

## 秘密情報

API キーなどは `~/.zshrc.local` や秘密情報管理ツールで扱います。
認証トークン、ブラウザプロファイル、会話履歴、DB、キャッシュはこのリポジトリへコピーしません。

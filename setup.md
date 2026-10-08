# 既存 Mac からの移行メモ

通常のセットアップは [README.md](README.md) を参照してください。

## 管理元

- ランタイム: `programs/mise/config.toml` に明示したバージョンを mise で導入。
- アプリ・一般 CLI・フォント: `Brewfile` に記載。
- 設定: Home Manager で生成・リンク。Neovim は既存の LazyVim 設定を配置。
- Nix の例外: Home Manager 自身、`nil`、`nix-direnv`、設定生成に必要な依存。

今回の変更は導入一覧と、すでにリポジトリにある設定の管理元を整理するものです。
実機の VS Code / Cursor / Codex / Docker のユーザー設定・拡張機能・認証情報は自動で取り込みません。

## 適用前

```bash
git status --short
brew bundle list --file=Brewfile
command -v brew nix mise node bun flutter
```

`brew bundle check --file=Brewfile` は不足パッケージがあると非ゼロで終了します。確認コマンドであり、インストールは行いません。

以前の導入方法が残っている場合は、次の点を確認してください。

- Nix がなくなってもよいという意味ではありません。設定の適用に引き続き使用します。
- `brew bundle` は、手動で入れたアプリと同じ場所へ導入しようとして停止する場合があります。対象アプリのデータを確認し、公式の移行・再導入方法で Homebrew 管理へ移してください。スクリプトは `--force` で既存アプリを置き換えません。
- Homebrew へ移す CLI が過去の mise 設定にもある場合、プロジェクトの `mise.toml` / `.tool-versions` や追加グローバル設定も確認してください。宣言から外れたツールや古い shim は自動で削除しません。
- 新しいログインシェルで `type -a node bun flutter git nvim claude cursor-agent` を確認してください。ランタイムは mise の shims、一般 CLI は `/opt/homebrew/bin` が基本です。
- ホーム直下の `.gitconfig` は Git が読み込むため、リポジトリの Git 設定を上書きすることがあります。必要な差分を確認してから整理してください。
- シェル設定は `~/.config/zsh/` に配置します。ホーム直下の既存 `.zshrc` / `.zprofile` の独自設定が必要なら、内容を確認して `~/.zshrc.local` などへ移してください。

Home Manager の既存ファイルへのバックアップ接尾辞は `before-dotfiles-YYYYMMDDhhmmss` です。
同名バックアップがある場合は適用が停止するので、バックアップを確認してから再実行してください。

## 別途行う作業

| 対象 | 扱い |
| --- | --- |
| Xcode / Apple Developer | App Store にサインイン後、`brew bundle --file=Brewfile.mas` |
| Android SDK / NDK / AVD | Android Studio で導入。プロジェクトに必要な SDK 構成とライセンス確認は別作業 |
| KensingtonWorks | メーカー配布版を使用。権限承認・デバイス設定は端末側で実施 |
| Dart グローバルツール（melos / flutterfire / patrol / marionette など） | プロジェクトごとのバージョン・導入手順で管理。Brewfile には含めない |
| npm / Cargo / Python の追加ツール、ローカル開発の agent-mobile / Pencil / Marionette Agent | Homebrew 対応分以外は既存状態を維持。必要なプロジェクトのセットアップで管理 |
| cargo-watch | Homebrew 側で無効化済みのため Brewfile へ追加しない。既存インストールは維持 |
| GitHub / Google Cloud / AI ツールなどの認証 | 各ツールで再ログイン。認証ファイルは Git 管理しない |
| Docker ボリューム / シミュレータの実データ / 会話履歴 | dotfiles とは別にバックアップ |
| macOS の画面収録・アクセシビリティなど | システム設定で個別に承認 |

管理対象外の一覧は [README.md](README.md#管理対象外) を参照してください。
これらが残っていても正常です。`brew bundle cleanup` で一覧外のアプリを削除しないでください。

## 更新とロールバック

`update.sh` は Brewfile の更新と設定の再適用のみ行います。mise のピンと flake.lock は変更しません。
ランタイムは TOML、Nix は flake.lock を Git で戻してから再適用できます。
Homebrew の更新は Home Manager の世代切り替えでは戻らないため、必要なバージョンへの復旧は Homebrew 側で行います。

## 参照

- [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile)
- [mise configuration](https://mise.jdx.dev/configuration.html)
- [Home Manager](https://nix-community.github.io/home-manager/)

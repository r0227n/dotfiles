{ config, pkgs, ... }:

{
  # Claude Code is installed by Brewfile (cask "claude-code").
  # Claude Code設定ファイル
  home.file.".claude/config.json".text = builtins.toJSON {
    # API設定
    api = {
      baseUrl = "https://api.anthropic.com";
      # API keyは環境変数で設定: export ANTHROPIC_API_KEY="your-key"
    };

    # エディタ設定
    editor = "nvim";

    # プロンプトキャッシング
    promptCaching = {
      enabled = true;
      maxCacheSize = 100;
    };

    # MCP (Model Context Protocol) サーバー設定
    mcpServers = {
      # ファイルシステムアクセス
      filesystem = {
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-filesystem" "/Users/${config.home.username}" ];
      };

      # GitHub統合（オプション）
      # github = {
      #   command = "npx";
      #   args = [ "-y" "@modelcontextprotocol/server-github" ];
      #   env = {
      #     GITHUB_PERSONAL_ACCESS_TOKEN = ""; # 環境変数で設定
      #   };
      # };
    };

    # デフォルトモデル
    defaultModel = "claude-sonnet-4-5-20250929";

    # ログレベル
    logLevel = "info";

    # セッション履歴
    maxHistorySize = 1000;
  };

  # Pre-commit hook の例（コミット前にコードチェック）
  home.file.".claude/hooks/pre-commit.sh" = {
    text = ''
      #!/usr/bin/env bash

      # コミット前にlintチェックを実行
      if [ -f "package.json" ]; then
        npm run lint 2>/dev/null || true
      fi

      if [ -f "Cargo.toml" ]; then
        cargo clippy 2>/dev/null || true
      fi

      exit 0
    '';
    executable = true;
  };

  # Post-command hook の例（コマンド実行後の通知）
  home.file.".claude/hooks/post-command.sh" = {
    text = ''
      #!/usr/bin/env bash

      # 長時間実行されたコマンドを通知（オプション）
      # macOSの通知センター使用例
      # osascript -e "display notification \"Command completed\" with title \"Claude Code\""

      exit 0
    '';
    executable = true;
  };

  # Claude Code用の環境変数
  home.sessionVariables = {
    # ANTHROPIC_API_KEY は .zshrc.local などで設定することを推奨
    # ANTHROPIC_API_KEY = "sk-ant-..."; # ここには書かない！

    # Claude Code設定ディレクトリ
    CLAUDE_CONFIG_DIR = "${config.home.homeDirectory}/.claude";
  };

  # Zsh統合（エイリアス）
  home.shellAliases = {
    # Claude Code エイリアス
    "claude-code" = "claude";
    cc = "claude";
    ccc = "claude";
    ccr = "claude --resume";
  };
}

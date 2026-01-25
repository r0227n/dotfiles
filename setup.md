# Nix + mise を使った dotfiles 環境構築ガイド

## 概要

このガイドでは、Nix（システム設定・CLIツール管理）と mise（言語バージョン管理）を組み合わせた、最適なdotfiles環境を構築します。

### アーキテクチャ

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

### なぜこの構成？

| ツール | 役割 | 理由 |
|--------|------|------|
| **Nix** | システムツール・設定管理 | 再現性、宣言的管理、ロールバック可能 |
| **mise** | 言語バージョン管理 | Flutter/Rust/Node.jsの柔軟な切り替え、プロジェクト単位管理 |

---

## ディレクトリ構成

```
~/dotfiles/
├── flake.nix                           # Flakes設定（エントリーポイント）
├── flake.lock                          # 依存関係ロック
├── home.nix                            # Home Managerメイン設定
│
├── modules/
│   ├── common.nix                      # 共通設定
│   ├── darwin.nix                      # macOS専用設定
│   └── fonts.nix                       # フォント設定
│
├── programs/
│   ├── neovim/
│   │   ├── default.nix                 # Neovim設定
│   │   └── lua/
│   │       └── user/                   # AstroVim用カスタム設定
│   │           ├── init.lua
│   │           └── plugins/
│   ├── wezterm/
│   │   └── default.nix                 # WezTerm設定
│   ├── shell/
│   │   └── default.nix                 # Zsh + Starship
│   ├── git/
│   │   └── default.nix                 # Git設定
│   ├── mise/
│   │   └── default.nix                 # mise設定
│   ├── claude/
│   │   └── default.nix                 # Claude Code設定
│   └── tmux/
│       └── default.nix                 # tmux設定（オプション）
│
├── config/
│   ├── mise/
│   │   ├── config.toml                 # miseグローバル設定
│   │   └── .tool-versions.example      # プロジェクト用サンプル
│   └── claude/
│       ├── config.json                 # Claude Code設定
│       └── hooks/                      # Claude Code hooks
│
├── scripts/
│   ├── install.sh                      # 初回セットアップスクリプト
│   ├── update.sh                       # 更新スクリプト
│   └── setup-mise.sh                   # mise初期設定スクリプト
│
└── README.md                           # このファイル
```

---

## 設定ファイル詳細

### flake.nix

```nix
{
  description = "Personal dotfiles with Nix Flakes + mise";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS専用（必要な場合）
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      # 使用しているシステムを指定
      system = "aarch64-darwin";  # Apple Silicon
      # system = "x86_64-darwin";  # Intel Mac
      # system = "x86_64-linux";   # Linux
      
      pkgs = nixpkgs.legacyPackages.${system};
      
      username = "YOUR_USERNAME";  # ここを変更
    in
    {
      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        
        modules = [ ./home.nix ];
        
        extraSpecialArgs = {
          inherit inputs system username;
        };
      };
    };
}
```

### home.nix

```nix
{ config, pkgs, username, ... }:

{
  # Home Managerの基本設定
  programs.home-manager.enable = true;
  
  home = {
    username = username;
    homeDirectory = "/Users/${username}";  # macOS
    # homeDirectory = "/home/${username}";  # Linux
    stateVersion = "24.05";

    # グローバル環境変数
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      LANG = "ja_JP.UTF-8";
      LC_ALL = "ja_JP.UTF-8";
    };
  };

  # 基本CLIツール（mise管理外）
  home.packages = with pkgs; [
    # コアツール
    curl
    wget
    git
    
    # モダンCLIツール
    ripgrep       # grep代替 (rg)
    fd            # find代替
    bat           # cat代替
    eza           # ls代替
    fzf           # ファジーファインダー
    zoxide        # cd代替 (z)
    delta         # Git diff viewer
    
    # ファイル操作
    tree
    jq            # JSON processor
    yq-go         # YAML processor
    
    # システムモニタリング
    htop
    btop
    
    # Git関連
    gh            # GitHub CLI
    lazygit       # Git TUI
    
    # 開発補助ツール
    direnv        # プロジェクト環境変数管理
    
    # その他
    tldr          # コマンド例集
  ];

  # モジュールのインポート
  imports = [
    ./modules/common.nix
    ./modules/darwin.nix
    ./modules/fonts.nix
    ./programs/neovim
    ./programs/wezterm
    ./programs/shell
    ./programs/git
    ./programs/mise
    ./programs/claude
    # ./programs/tmux  # 必要に応じて
  ];
}
```

### modules/common.nix

```nix
{ config, pkgs, ... }:

{
  # XDG Base Directory設定
  xdg = {
    enable = true;
    
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    cacheHome = "${config.home.homeDirectory}/.cache";
    stateHome = "${config.home.homeDirectory}/.local/state";
  };

  # direnv統合
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };
}
```

### modules/darwin.nix

```nix
{ config, pkgs, lib, ... }:

{
  # macOS特有のパッケージ
  home.packages = lib.mkIf pkgs.stdenv.isDarwin (with pkgs; [
    mas           # Mac App Store CLI
    m-cli         # macOS管理ツール
  ]);

  # macOS専用の環境変数
  home.sessionVariables = lib.mkIf pkgs.stdenv.isDarwin {
    # Homebrewパス（必要な場合）
    # PATH = "$PATH:/opt/homebrew/bin";
  };
}
```

### modules/fonts.nix

```nix
{ config, pkgs, ... }:

{
  fonts.fontconfig.enable = true;
  
  home.packages = with pkgs; [
    # Nerd Fonts
    (nerdfonts.override { 
      fonts = [ 
        "JetBrainsMono"
        "FiraCode"
        "Hack"
        "Meslo"
      ]; 
    })
  ];
}
```

### programs/mise/default.nix

```nix
{ config, pkgs, ... }:

{
  # mise本体のインストール
  home.packages = with pkgs; [
    mise
  ];

  # mise設定ファイル
  home.file.".config/mise/config.toml".text = ''
    [tools]
    # グローバルバージョン（プロジェクトで上書き可能）
    # ここでは指定せず、プロジェクトごとに管理することを推奨

    [settings]
    experimental = true
    verbose = false
    
    # プラグイン自動インストール
    plugin_autoupdate_last_check_duration = "7d"
    
    # ショートハンド有効化
    shorthands_file = "~/.config/mise/shorthands.toml"
  '';

  # ショートハンド設定（オプション）
  home.file.".config/mise/shorthands.toml".text = ''
    # カスタムショートハンドをここに追加
  '';

  # シェル統合
  programs.zsh.initExtra = ''
    # mise初期化
    eval "$(mise activate zsh)"
    
    # mise補完
    eval "$(mise completion zsh)"
  '';

  # direnvとの統合
  home.file.".config/direnv/direnvrc".text = ''
    # miseとdirenvの統合
    use_mise() {
      eval "$(mise direnv exec)"
    }
  '';
}
```

### programs/shell/default.nix

```nix
{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # 履歴設定
    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    # エイリアス
    shellAliases = {
      # モダンツール
      ls = "eza --icons";
      ll = "eza -l --icons --git";
      la = "eza -la --icons --git";
      lt = "eza --tree --icons --level=2";
      cat = "bat";
      
      # Git
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph --all --decorate";
      gd = "git diff";
      lg = "lazygit";
      
      # Neovim
      v = "nvim";
      vim = "nvim";
      vi = "nvim";
      
      # dotfiles管理
      dotfiles = "cd ~/dotfiles";
      nixup = "cd ~/dotfiles && home-manager switch --flake .";
      nixclean = "nix-collect-garbage -d";
      
      # mise
      mi = "mise";
      mii = "mise install";
      mil = "mise list";
      miu = "mise use";
      
      # その他
      c = "clear";
      h = "history";
      t = "tree";
    };

    # 追加設定
    initExtra = ''
      # fzf統合
      source <(fzf --zsh)

      # zoxide統合
      eval "$(zoxide init zsh)"

      # 補完設定
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

      # キーバインド
      bindkey "^[[A" history-search-backward
      bindkey "^[[B" history-search-forward

      # ローカル設定の読み込み（API key等）
      [ -f ~/.zshrc.local ] && source ~/.zshrc.local

      # 便利な関数

      # プロジェクトディレクトリに移動してmiseを確認
      function pd() {
        z "$1" && mise current
      }

      # mise環境のクリーンインストール
      function mise-reinstall() {
        mise uninstall "$1"
        mise install "$1"
      }
    '';
  };

  # Starship（プロンプト）
  programs.starship = {
    enable = true;
    
    settings = {
      add_newline = true;
      
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_status"
        "$nodejs"
        "$rust"
        "$flutter"
        "$cmd_duration"
        "$line_break"
        "$character"
      ];
      
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
      
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
        style = "bold cyan";
      };
      
      git_branch = {
        symbol = " ";
        format = "on [$symbol$branch]($style) ";
      };
      
      git_status = {
        ahead = "⇡\${count}";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
        behind = "⇣\${count}";
        conflicted = "🏳";
        untracked = "🤷";
        stashed = "📦";
        modified = "📝";
        staged = "[++\($count\)](green)";
        renamed = "👅";
        deleted = "🗑";
      };
      
      # mise管理の言語バージョン表示
      nodejs = {
        format = "via [$symbol($version )]($style)";
        symbol = " ";
      };
      
      rust = {
        format = "via [$symbol($version )]($style)";
        symbol = "🦀 ";
      };
      
      flutter = {
        format = "via [$symbol($version )]($style)";
        symbol = " ";
      };
      
      cmd_duration = {
        min_time = 500;
        format = "took [$duration]($style) ";
      };
    };
  };

  # fzf設定
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--inline-info"
    ];
    
    changeDirWidgetCommand = "fd --type d --hidden --exclude .git";
    changeDirWidgetOptions = [
      "--preview 'tree -C {} | head -200'"
    ];
    
    fileWidgetCommand = "fd --type f --hidden --exclude .git";
    fileWidgetOptions = [
      "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
    ];
  };

  # zoxide設定
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd"
    ];
  };

  # bat設定
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      style = "numbers,changes,header";
    };
  };
}
```

### programs/git/default.nix

```nix
{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "Your Name";  # 変更してください
    userEmail = "your.email@example.com";  # 変更してください
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      fetch.prune = true;
      core.editor = "nvim";
      core.autocrlf = "input";
      
      # Delta設定
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      
      delta = {
        navigate = true;
        light = false;
        side-by-side = true;
        line-numbers = true;
        syntax-theme = "Nord";
      };
      
      merge = {
        conflictstyle = "diff3";
        tool = "nvimdiff";
      };
      
      diff = {
        colorMoved = "default";
        algorithm = "histogram";
      };
      
      # rerere（コンフリクト解決を記憶）
      rerere.enabled = true;
    };

    ignores = [
      # macOS
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"

      # エディタ
      "*.swp"
      "*.swo"
      "*~"
      ".vscode/"
      ".idea/"

      # Node.js
      "node_modules/"
      "npm-debug.log"
      "yarn-error.log"

      # 環境変数
      ".env"
      ".env.local"
      ".env.*.local"
      ".claude.env"

      # シェル設定（ローカル）
      ".zshrc.local"

      # ログ
      "*.log"

      # mise
      ".mise.local.toml"

      # その他
      ".direnv/"
    ];
    
    aliases = {
      st = "status -sb";
      co = "checkout";
      cob = "checkout -b";
      br = "branch";
      ci = "commit";
      cm = "commit -m";
      ca = "commit --amend";
      unstage = "reset HEAD --";
      last = "log -1 HEAD --stat";
      visual = "log --graph --all --oneline --decorate";
      ll = "log --oneline --graph --all --decorate";
      contributors = "shortlog --summary --numbered";
    };
  };

  # GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nvim";
      prompt = "enabled";
      pager = "delta";
    };
  };

  # lazygit設定
  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        theme = {
          selectedLineBgColor = [ "reverse" ];
          selectedRangeBgColor = [ "reverse" ];
        };
        nerdFontsVersion = "3";
      };
      git = {
        paging = {
          colorArg = "always";
          pager = "delta --dark --paging=never";
        };
      };
    };
  };
}
```

### programs/neovim/default.nix

```nix
{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    
    # Neovimに必要なパッケージ
    extraPackages = with pkgs; [
      # LSP servers（mise管理の言語用）
      lua-language-server       # Lua
      nil                       # Nix
      # Node.js, Rust, Flutterは mise で管理するため除外
      
      # Formatters
      stylua                    # Lua
      nixpkgs-fmt              # Nix
      # prettier, rustfmtなどはmiseで管理
      
      # Linters
      shellcheck
      
      # 必須ツール
      tree-sitter
      ripgrep
      fd
      lazygit
      gcc                       # treesitterコンパイル用
    ];
  };

  # AstroVimのインストール
  home.activation.installAstroNvim = ''
    NVIM_DIR="${config.home.homeDirectory}/.config/nvim"
    
    if [ ! -d "$NVIM_DIR/lua/astronvim" ]; then
      $DRY_RUN_CMD rm -rf "$NVIM_DIR"
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone --depth 1 \
        https://github.com/AstroNvim/AstroNvim "$NVIM_DIR"
    fi
  '';

  # AstroVimユーザー設定
  home.file.".config/nvim/lua/user/init.lua".text = ''
    return {
      -- カラースキーム
      colorscheme = "astrodark",
      
      -- UI設定
      options = {
        opt = {
          relativenumber = true,
          number = true,
          spell = false,
          signcolumn = "yes",
          wrap = false,
        },
      },
      
      -- LSP設定
      lsp = {
        setup_handlers = {
          -- miseで管理される言語のLSP設定
          rust_analyzer = function(_, opts)
            -- Rustプロジェクトではmiseのrust-analyzerを使用
            require("astronvim.utils.lsp").setup("rust_analyzer", opts)
          end,
          tsserver = function(_, opts)
            -- Node.jsプロジェクトではmiseのtsserverを使用
            require("astronvim.utils.lsp").setup("tsserver", opts)
          end,
        },
        
        config = {
          lua_ls = {
            settings = {
              Lua = {
                diagnostics = {
                  globals = { "vim" },
                },
              },
            },
          },
        },
      },
      
      -- プラグイン追加
      plugins = {
        -- mise統合
        {
          "williamboman/mason.nvim",
          opts = function(_, opts)
            -- Masonを無効化してmiseを使用
            opts.ensure_installed = opts.ensure_installed or {}
            -- LSPはmiseで管理するため、Masonでインストールしない
          end,
        },
      },
    }
  '';
}
```

### programs/wezterm/default.nix

```nix
{ config, pkgs, ... }:

{
  programs.wezterm = {
    enable = true;
    
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()

      -- カラースキーム
      config.color_scheme = 'Tokyo Night'

      -- フォント
      config.font = wezterm.font('JetBrainsMono Nerd Font', { weight = 'Medium' })
      config.font_size = 14.0

      -- ウィンドウ設定
      config.window_background_opacity = 0.95
      config.macos_window_background_blur = 20
      config.window_decorations = "RESIZE"
      config.hide_tab_bar_if_only_one_tab = true
      
      config.window_padding = {
        left = 20,
        right = 20,
        top = 20,
        bottom = 20,
      }

      -- タブバー
      config.use_fancy_tab_bar = false
      config.tab_bar_at_bottom = true
      config.show_new_tab_button_in_tab_bar = false

      -- カーソル
      config.default_cursor_style = 'BlinkingBar'
      config.cursor_blink_rate = 500

      -- キーバインド
      config.keys = {
        -- タブ操作
        { key = 't', mods = 'CMD', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
        { key = 'w', mods = 'CMD', action = wezterm.action.CloseCurrentTab { confirm = true } },
        { key = 'LeftArrow', mods = 'CMD', action = wezterm.action.ActivateTabRelative(-1) },
        { key = 'RightArrow', mods = 'CMD', action = wezterm.action.ActivateTabRelative(1) },
        { key = '1', mods = 'CMD', action = wezterm.action.ActivateTab(0) },
        { key = '2', mods = 'CMD', action = wezterm.action.ActivateTab(1) },
        { key = '3', mods = 'CMD', action = wezterm.action.ActivateTab(2) },
        { key = '4', mods = 'CMD', action = wezterm.action.ActivateTab(3) },
        { key = '5', mods = 'CMD', action = wezterm.action.ActivateTab(4) },
        
        -- ペイン分割
        { key = 'd', mods = 'CMD', action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' } },
        { key = 'd', mods = 'CMD|SHIFT', action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' } },
        
        -- ペイン移動
        { key = 'h', mods = 'CMD|SHIFT', action = wezterm.action.ActivatePaneDirection 'Left' },
        { key = 'l', mods = 'CMD|SHIFT', action = wezterm.action.ActivatePaneDirection 'Right' },
        { key = 'k', mods = 'CMD|SHIFT', action = wezterm.action.ActivatePaneDirection 'Up' },
        { key = 'j', mods = 'CMD|SHIFT', action = wezterm.action.ActivatePaneDirection 'Down' },
        
        -- ペイン閉じる
        { key = 'w', mods = 'CMD|SHIFT', action = wezterm.action.CloseCurrentPane { confirm = true } },
        
        -- フォントサイズ
        { key = '+', mods = 'CMD', action = wezterm.action.IncreaseFontSize },
        { key = '-', mods = 'CMD', action = wezterm.action.DecreaseFontSize },
        { key = '0', mods = 'CMD', action = wezterm.action.ResetFontSize },
      }

      return config
    '';
  };
}
```

### programs/claude/default.nix

```nix
{ config, pkgs, ... }:

{
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
  programs.zsh.shellAliases = {
    # Claude Code エイリアス
    claude = "claude-code";
    cc = "claude-code";
    ccc = "claude-code chat";
    ccr = "claude-code --resume";
  };

  # direnv統合（プロジェクト固有のAPI key管理）
  home.file.".config/direnv/direnvrc".text = ''
    # miseとdirenvの統合
    use_mise() {
      eval "$(mise direnv exec)"
    }

    # Claude API key読み込み（.envrc内で使用）
    use_claude() {
      if [ -f ".claude.env" ]; then
        source_env ".claude.env"
      fi
    }
  '';
}
```

---

## mise 設定詳細

### グローバル設定（~/.config/mise/config.toml）

Home Managerで自動生成されます。手動で変更したい場合：

```toml
[tools]
# グローバルバージョン（推奨しない - プロジェクトごとに管理）
# node = "20.11.0"
# rust = "1.75.0"

[settings]
experimental = true
verbose = false

# 並列ダウンロード
jobs = 4

# プラグイン自動更新
plugin_autoupdate_last_check_duration = "7d"

[aliases]
# カスタムエイリアス
node = "nodejs"
```

### プロジェクトごとの設定（.mise.toml）

各プロジェクトのルートに配置：

```toml
# Flutter プロジェクトの例
[tools]
flutter = "3.19.0"
java = "17"

[env]
FLUTTER_ROOT = "{{env.HOME}}/.local/share/mise/installs/flutter/3.19.0"
ANDROID_HOME = "{{env.HOME}}/Library/Android/sdk"
```

```toml
# Rust プロジェクトの例
[tools]
rust = "1.75.0"

[env]
RUST_BACKTRACE = "1"
```

```toml
# Node.js プロジェクトの例
[tools]
node = "20.11.0"

[env]
NODE_ENV = "development"
```

### .tool-versionsファイル（asdfフォーマット）

asdfからの移行用。miseも互換性あり：

```
flutter 3.19.0
rust 1.75.0
nodejs 20.11.0
```

---

## スクリプト詳細

### scripts/install.sh

```bash
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

# Home Managerのインストールと適用
log_info "Installing and applying Home Manager configuration..."
nix run home-manager/master -- switch --flake .

log_success "Home Manager applied successfully"

# miseのセットアップ
log_info "Setting up mise..."
bash "$DOTFILES_DIR/scripts/setup-mise.sh"

echo "
╔═══════════════════════════════════════╗
║   Installation Complete! 🎉           ║
╚═══════════════════════════════════════╝

Next steps:
1. Restart your shell: exec zsh
2. Navigate to a project directory
3. Run 'mise install' to install project tools
4. Enjoy your new development environment!
"

log_info "Please restart your shell: exec zsh"
```

### scripts/update.sh

```bash
#!/usr/bin/env bash

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ ${NC}$1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }

echo "🔄 Updating dotfiles..."

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
```

### scripts/setup-mise.sh

```bash
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
```

---

## 日常的な使い方

### プロジェクト開始時

```bash
# 新しいFlutterプロジェクト
cd ~/projects/my-flutter-app

# .mise.tomlを作成
cat > .mise.toml << EOF
[tools]
flutter = "3.19.0"
java = "17"
EOF

# ツールをインストール
mise install

# 自動的にバージョンが切り替わる
flutter --version
```

### バージョン切り替え

```bash
# プロジェクトのバージョンを変更
mise use flutter@3.16.0

# 確認
mise current

# 別のプロジェクトに移動すると自動的に切り替わる
cd ~/projects/another-project
mise current  # 別のバージョンが表示される
```

### dotfiles更新

```bash
# 設定を変更
cd ~/dotfiles
nvim programs/neovim/default.nix

# 変更をコミット
git add .
git commit -m "Update neovim config"
git push

# 設定を適用
home-manager switch --flake .
```

### パッケージ管理

```bash
# Nixパッケージの追加
# home.nixを編集して home.packages に追加
cd ~/dotfiles
nvim home.nix

# 適用
home-manager switch --flake .

# miseツールの追加
mise install node@20.11.0
mise use node@20.11.0
```

---

## トラブルシューティング

### mise関連

#### miseでツールがインストールできない

```bash
# プラグインを再インストール
mise plugin uninstall flutter
mise plugin install flutter

# キャッシュクリア
rm -rf ~/.local/share/mise/downloads/*
mise install flutter@3.19.0
```

#### バージョンが切り替わらない

```bash
# mise環境の確認
mise doctor

# シェルの初期化確認
echo $PATH
which flutter

# シェル設定を再読み込み
exec zsh
```

### Nix関連

#### ビルドエラーが出る場合

```bash
# Nixストアのガベージコレクション
nix-collect-garbage -d

# 詳細なエラーログを表示
home-manager switch --flake . --show-trace
```

#### 設定を元に戻す

```bash
# 前の世代を確認
home-manager generations

# ロールバック
home-manager switch --rollback
```

### ディスク容量が足りない

```bash
# Nixストアのクリーンアップ
nix-collect-garbage -d

# miseのキャッシュクリア
rm -rf ~/.local/share/mise/downloads/*
rm -rf ~/.local/share/mise/installs/*/src

# 古い世代を削除
nix-env --delete-generations old
nix-collect-garbage -d
```

---

## 便利なコマンド一覧

### Nix / Home Manager

```bash
# 設定を適用
home-manager switch --flake .

# 設定の差分を確認
home-manager switch --flake . --dry-run

# 世代の確認
home-manager generations

# ロールバック
home-manager switch --rollback

# ガベージコレクション
nix-collect-garbage -d
```

### mise

```bash
# インストール済みツール一覧
mise list

# 現在のバージョン確認
mise current

# ツールのインストール
mise install flutter@3.19.0

# ツールの使用（プロジェクト）
mise use flutter@3.19.0

# ツールの使用（グローバル）
mise use -g flutter@3.19.0

# 利用可能なバージョン一覧
mise ls-remote flutter

# ツールのアップグレード
mise upgrade flutter

# 全ツールのアップグレード
mise upgrade

# 環境変数の確認
mise env

# 診断
mise doctor
```

### Git

```bash
# dotfilesの状態確認
cd ~/dotfiles && git status

# 変更をコミット
git add . && git commit -m "Update config"

# プッシュ
git push

# プル
git pull
```

---

## ベストプラクティス

### 1. 言語バージョンの管理

- **グローバルバージョンは設定しない** - プロジェクトごとに`.mise.toml`で管理
- **チーム開発では`.mise.toml`をコミット** - 全員が同じ環境で開発
- **定期的にバージョンを更新** - セキュリティパッチを適用

### 2. dotfilesの運用

- **小さな変更を頻繁にコミット** - 問題があってもロールバックしやすい
- **コミットメッセージは明確に** - 後で見返したときに分かりやすく
- **プライベート情報を含めない** - `.env`ファイルは`.gitignore`に追加

### 3. 新しいマシンへの移行

1. `scripts/install.sh`を実行
2. SSH鍵を設定
3. `mise install`で開発環境を構築
4. プロジェクトをクローン

### 4. 定期メンテナンス

```bash
# 週1回実行推奨
cd ~/dotfiles
nix flake update
home-manager switch --flake .
mise upgrade
nix-collect-garbage -d
```

---

## 参考リンク

- [Nix公式ドキュメント](https://nixos.org/manual/nix/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [mise Documentation](https://mise.jdx.dev/)
- [Claude Code Documentation](https://github.com/anthropics/claude-code)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)
- [AstroVim Documentation](https://docs.astronvim.com/)
- [WezTerm Documentation](https://wezfurlong.org/wezterm/)

---

## Claude Code の設定と使い方

### API キーの設定

```bash
# .zshrc.local を作成（gitignoreに含める）
cat > ~/.zshrc.local << EOF
export ANTHROPIC_API_KEY="sk-ant-your-api-key-here"
EOF

# .zshrc から読み込む（programs/shell/default.nix に追加）
# initExtra に以下を追加:
# [ -f ~/.zshrc.local ] && source ~/.zshrc.local
```

### プロジェクトごとのAPI key管理

```bash
# プロジェクトルートに .claude.env を作成
cd ~/projects/my-project

cat > .claude.env << EOF
export ANTHROPIC_API_KEY="sk-ant-project-specific-key"
EOF

# .envrc で Claude環境を有効化
cat > .envrc << EOF
use_claude
EOF

# direnvを許可
direnv allow

# .gitignore に追加
echo ".claude.env" >> .gitignore
```

### Claude Code Hooks の活用

#### Pre-commit hook（コミット前チェック）

```bash
# ~/.claude/hooks/pre-commit.sh
#!/usr/bin/env bash

# ステージングされたファイルのlintチェック
if command -v eslint &> /dev/null; then
  git diff --cached --name-only --diff-filter=ACM | grep '\.js$\|\.ts$' | xargs eslint
fi

# Rustプロジェクトのフォーマットチェック
if [ -f "Cargo.toml" ]; then
  cargo fmt --check
  cargo clippy -- -D warnings
fi

exit 0
```

#### Post-command hook（コマンド実行後）

```bash
# ~/.claude/hooks/post-command.sh
#!/usr/bin/env bash

# 長時間実行の通知（macOS）
if command -v osascript &> /dev/null; then
  osascript -e 'display notification "Claude command completed" with title "Claude Code"'
fi

exit 0
```

### MCP サーバーの追加設定

#### Brave Search MCP（Web検索）

```nix
# programs/claude/default.nix の mcpServers に追加
brave-search = {
  command = "npx";
  args = [ "-y" "@modelcontextprotocol/server-brave-search" ];
  env = {
    BRAVE_API_KEY = ""; # 環境変数 BRAVE_API_KEY で設定
  };
};
```

#### Postgres MCP（データベース）

```nix
postgres = {
  command = "npx";
  args = [ "-y" "@modelcontextprotocol/server-postgres" "postgresql://localhost/mydb" ];
};
```

### よく使うコマンド

```bash
# Claude Code でチャット開始
claude-code chat

# 前回のセッションを再開
claude-code --resume

# 特定のファイルについて質問
claude-code "このファイルの機能を説明して" src/main.rs

# プロジェクト全体の分析
claude-code "このプロジェクトの構造を説明して"

# コード生成
claude-code "Rust でHTTPサーバーを実装して"

# エイリアス使用（zshrcに設定済み）
cc chat                  # claude-code chat
ccr                      # claude-code --resume
```

### トラブルシューティング

#### API key エラー

```bash
# 環境変数が設定されているか確認
echo $ANTHROPIC_API_KEY

# 手動で設定
export ANTHROPIC_API_KEY="sk-ant-..."

# .zshrc.local を再読み込み
source ~/.zshrc.local
```

#### MCP サーバーが起動しない

```bash
# Node.js のバージョン確認（mise管理）
node --version

# npx キャッシュをクリア
npx clear-npx-cache

# MCP サーバーを手動でインストール
npm install -g @modelcontextprotocol/server-filesystem
```

#### Hooks が実行されない

```bash
# 実行権限を確認
ls -la ~/.claude/hooks/

# 権限を付与
chmod +x ~/.claude/hooks/*.sh

# Hook を手動テスト
bash ~/.claude/hooks/pre-commit.sh
```

---

## カスタマイズのヒント

### 独自のツールを追加

`home.nix`の`home.packages`に追加：

```nix
home.packages = with pkgs; [
  # 既存のパッケージ
  # ...
  
  # 追加したいツール
  docker
  docker-compose
  postgresql
  redis
];
```

### 環境変数の追加

`home.nix`の`home.sessionVariables`に追加：

```nix
home.sessionVariables = {
  EDITOR = "nvim";
  # 追加の環境変数
  MYVAR = "value";
};
```

### エイリアスの追加

`programs/shell/default.nix`の`shellAliases`に追加：

```nix
shellAliases = {
  # 既存のエイリアス
  # ...
  
  # 新しいエイリアス
  myalias = "echo 'Hello'";
};
```

これで完璧な dotfiles 環境が構築できます！
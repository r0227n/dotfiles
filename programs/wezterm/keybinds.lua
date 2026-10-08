local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

M.keys = {
  -- ペイン分割
  -- cmd+shift+d: 左右にペイン分割
  {
    key = "d",
    mods = "CMD|SHIFT",
    action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
  },
  -- cmd+shift+s: 上下にペイン分割
  {
    key = "s",
    mods = "CMD|SHIFT",
    action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },

  -- ペイン移動 (Vimスタイル)
  -- cmd+h: 左のペインに移動
  {
    key = "h",
    mods = "CMD",
    action = act.ActivatePaneDirection("Left"),
  },
  -- cmd+l: 右のペインに移動
  {
    key = "l",
    mods = "CMD",
    action = act.ActivatePaneDirection("Right"),
  },
  -- cmd+k: 上のペインに移動
  {
    key = "k",
    mods = "CMD",
    action = act.ActivatePaneDirection("Up"),
  },
  -- cmd+j: 下のペインに移動
  {
    key = "j",
    mods = "CMD",
    action = act.ActivatePaneDirection("Down"),
  },

  -- ペインズーム
  {
    key = "z",
    mods = "CMD|SHIFT",
    action = act.TogglePaneZoomState,
  },

  -- ペイン選択モード
  {
    key = "p",
    mods = "CMD|SHIFT",
    action = act.PaneSelect,
  },

  -- ペインリサイズ (Vimスタイル)
  {
    key = "h",
    mods = "CMD|SHIFT",
    action = act.AdjustPaneSize({ "Left", 1 }),
  },
  {
    key = "j",
    mods = "CMD|SHIFT",
    action = act.AdjustPaneSize({ "Down", 1 }),
  },
  {
    key = "k",
    mods = "CMD|SHIFT",
    action = act.AdjustPaneSize({ "Up", 1 }),
  },
  {
    key = "l",
    mods = "CMD|SHIFT",
    action = act.AdjustPaneSize({ "Right", 1 }),
  },

  -- その他の基本的なキーバインド
  -- 新しいタブを開く
  {
    key = "t",
    mods = "CMD",
    action = act.SpawnTab("CurrentPaneDomain"),
  },
  -- タブを閉じる
  {
    key = "w",
    mods = "CMD",
    action = act.CloseCurrentTab({ confirm = true }),
  },
  -- ペインを閉じる
  {
    key = "w",
    mods = "CMD|SHIFT",
    action = act.CloseCurrentPane({ confirm = true }),
  },
  -- コピー
  {
    key = "c",
    mods = "CMD",
    action = act.CopyTo("Clipboard"),
  },
  -- ペースト
  {
    key = "v",
    mods = "CMD",
    action = act.PasteFrom("Clipboard"),
  },
  -- 検索
  {
    key = "f",
    mods = "CMD",
    action = act.Search("CurrentSelectionOrEmptyString"),
  },
  -- タブ切り替え (次のタブ)
  {
    key = "Tab",
    mods = "CTRL",
    action = act.ActivateTabRelative(1),
  },
  -- タブ切り替え (前のタブ)
  {
    key = "Tab",
    mods = "CTRL|SHIFT",
    action = act.ActivateTabRelative(-1),
  },
  -- 設定再読み込み（home-manager switchも実行）
  {
    key = "r",
    mods = "CMD|SHIFT",
    action = wezterm.action_callback(function(window, pane)
      -- home-manager switchを実行（完了を待つ）
      local success, stdout, stderr = wezterm.run_child_process({
        "sh", "-c",
        "cd " .. os.getenv("HOME") .. "/dotfiles && home-manager switch --flake ."
      })
      if success then
        -- 成功したら設定を再読み込み
        window:perform_action(act.ReloadConfiguration, pane)
        window:toast_notification("WezTerm", "Configuration reloaded successfully", nil, 3000)
      else
        -- エラーを表示
        window:toast_notification("WezTerm", "Failed to reload config:\n" .. stderr, nil, 5000)
      end
    end),
  },
}

M.key_tables = {}

return M

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Appearance
config.color_scheme = "Catppuccin Frappe"
config.window_background_opacity = 1
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"

-- Font
config.font = wezterm.font("JetBrains Mono")
config.font_size = 12.0
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }

-- Window
config.initial_cols = 120
config.initial_rows = 30
config.window_padding = {
	left = 24,
	right = 24,
	top = 24,
	bottom = 24,
}

-- Pane borders
config.pane_border_size = 4
config.pane_border_color = "#414559"

-- Tab bar
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true

-- Cursor
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500

-- Scrollback
config.scrollback_lines = 100000

-- Mouse
config.hide_mouse_cursor_when_typing = true

-- Keybindings
local act = wezterm.action
config.keys = {
	{ key = "d", mods = "CMD", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "d", mods = "CMD|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "w", mods = "CMD", action = act.CloseCurrentPane({ confirm = true }) },

	-- Pane navigation
	{ key = "[", mods = "CMD", action = act.ActivatePaneDirection("Prev") },
	{ key = "]", mods = "CMD", action = act.ActivatePaneDirection("Next") },
	{ key = "LeftArrow", mods = "CMD|ALT", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "CMD|ALT", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "CMD|ALT", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "CMD|ALT", action = act.ActivatePaneDirection("Down") },

	-- Pane resizing
	{ key = "LeftArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "RightArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },
	{ key = "UpArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "DownArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },

	-- Scrollback
	{ key = "k", mods = "CMD", action = act.ClearScrollback("ScrollbackAndViewport") },

	-- Copy mode
	{ key = "x", mods = "CMD|SHIFT", action = act.ActivateCopyMode },
}

return config

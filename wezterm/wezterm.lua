local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Appearance
config.color_scheme = "Catppuccin Frappe"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"

-- Font
config.font = wezterm.font("FiraCode Nerd Font")
config.font_size = 12.0
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }

-- Window
config.initial_cols = 120
config.initial_rows = 30
config.window_padding = {
	left = 8,
	right = 8,
	top = 8,
	bottom = 8,
}

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

return config

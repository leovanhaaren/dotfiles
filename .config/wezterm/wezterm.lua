local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Appearance
config.color_scheme = "Catppuccin Frappe"
config.window_background_opacity = 0.95
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"

-- Font
config.font = wezterm.font("JetBrains Mono")
config.font_size = 12.0
config.line_height = 1.1
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }

-- Window
config.initial_cols = 120
config.initial_rows = 30
config.window_padding = {
	left = 16,
	right = 16,
	top = 16,
	bottom = 16,
}

-- Pane borders
-- config.pane_border_size = 4
-- config.pane_border_color = "#414559"

-- Tab bar
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 32
config.window_frame = {
	font = wezterm.font({ family = "JetBrains Mono", weight = "Regular" }),
	font_size = 14.0,
	active_titlebar_bg = "#292c3c",
	inactive_titlebar_bg = "#292c3c",
	border_left_width = "1px",
	border_right_width = "1px",
	border_top_height = "1px",
	border_bottom_height = "1px",
	border_left_color = "#51576d",
	border_right_color = "#51576d",
	border_top_color = "#51576d",
	border_bottom_color = "#51576d",
}
config.colors = {
	tab_bar = {
		background = "#292c3c",
		active_tab = {
			bg_color = "#303446",
			fg_color = "#c6d0f5",
			intensity = "Bold",
		},
		inactive_tab = {
			bg_color = "#292c3c",
			fg_color = "#737994",
		},
		inactive_tab_hover = {
			bg_color = "#414559",
			fg_color = "#c6d0f5",
		},
		new_tab = {
			bg_color = "#292c3c",
			fg_color = "#737994",
		},
		new_tab_hover = {
			bg_color = "#414559",
			fg_color = "#c6d0f5",
		},
	},
}

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

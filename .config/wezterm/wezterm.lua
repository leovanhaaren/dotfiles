local wezterm = require("wezterm")
local config = wezterm.config_builder()


-- Appearance
config.color_scheme = "Catppuccin Frappe"
config.window_background_opacity = 0.8
config.macos_window_background_blur = 50
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


-- Dim unfocused windows so the focused one is obvious at a glance.
local UNFOCUSED_FOREGROUND_TEXT_HSB = { hue = 1.0, saturation = 0.25, brightness = 0.45 }
local UNFOCUSED_WINDOW_BACKGROUND_OPACITY = 0.62

-- get_config_overrides() hands back a copy, so the current value is never the
-- same table we last stored; compare the fields instead of the identity.
local function same_text_hsb(actual, expected)
	if actual == nil or expected == nil then
		return actual == expected
	end
	return actual.hue == expected.hue
		and actual.saturation == expected.saturation
		and actual.brightness == expected.brightness
end

wezterm.on("window-focus-changed", function(window)
	local overrides = window:get_config_overrides() or {}
	local text_hsb, opacity
	if not window:is_focused() then
		text_hsb = UNFOCUSED_FOREGROUND_TEXT_HSB
		opacity = UNFOCUSED_WINDOW_BACKGROUND_OPACITY
	end

	-- Only write when one of the two values we own actually changes; a redundant
	-- set_config_overrides() call would trigger another config reload.
	if same_text_hsb(overrides.foreground_text_hsb, text_hsb) and overrides.window_background_opacity == opacity then
		return
	end

	overrides.foreground_text_hsb = text_hsb
	overrides.window_background_opacity = opacity
	window:set_config_overrides(overrides)
end)

return config

-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
-- config.color_scheme = 'Tokyo Night'
-- config.color_scheme = 'Catppuccin Mocha'
config.color_scheme = "Scarlet Protocol"

config.font = wezterm.font("UbuntuMono Nerd Font")
config.font_size = 20
config.hide_tab_bar_if_only_one_tab = true

config.default_cwd = "C:\\Users\\Manuel.Parra\\OneDrive - Aston Technologies\\Documents\\aston\\Greenlit\\03-Palo-Alto"

-- and finally, return the configuration to wezterm
return config

-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Portable muscle-memory bindings from the previous Hyprland setup.
o.bind("SUPER + E", "File manager", { omarchy = "nautilus" })
o.bind("SUPER + M", "Exit Hyprland", hl.dsp.exit())
o.bind("SUPER + SHIFT + R", "Record / GIF", "~/.config/hypr/record-gif.sh")

-- Replace Omarchy's X web-app shortcut with screen locking.
hl.unbind("SUPER + SHIFT + X")
o.bind("SUPER + SHIFT + X", "Lock system", "omarchy-system-lock")

-- Move close-window from Super+W to Super+Q.
hl.unbind("SUPER + W")
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())

-- Open Omarchy's keyboard shortcuts help.
o.bind("SUPER + SHIFT + K", "Keyboard help", "omarchy-menu-keybindings")

-- Use Tensaku's interactive annotation capture for Print Screen.
hl.unbind("PRINT")
o.bind(
  "PRINT",
  "Screenshot annotation",
  "tensaku --capture --copy-command wl-copy --output-filename '~/Pictures/screenshot-%Y-%m-%d_%H-%M-%S.png' --actions-on-enter save-to-clipboard --actions-on-escape exit --early-exit"
)

-- Restore muscle-memory window navigation.
hl.unbind("SUPER + H")
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
o.bind("SUPER + H", "Focus left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus below window", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus above window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus right window", hl.dsp.focus({ direction = "r" }))

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

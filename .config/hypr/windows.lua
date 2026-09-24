-- Portable window placement and rendering workarounds migrated from Ubuntu.
-- Hyprland's current Lua window-rule fields are documented at:
-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/

local workspaceRules = {
  { class = "rviz", workspace = "8", no_initial_focus = true },
  { class = "tablet", workspace = "8" },
  { class = "SwRI Console", workspace = "10", no_initial_focus = true },
  { class = "Tablet", workspace = "10", no_initial_focus = true },
  -- Match both the old Ubuntu snap classes and the native package classes.
  { class = "^(firefox|firefox_firefox)$", workspace = "2", no_initial_focus = true },
  { class = "^(org.telegram.desktop|telegram-desktop_telegram-desktop)$", workspace = "3", no_initial_focus = true },
  { class = "^(Mattermost.Desktop|mattermost-desktop)$", workspace = "4", no_initial_focus = true },
  { class = "^(google-chrome|google-chrome-stable)$", workspace = "5", no_initial_focus = true },
  { class = "org.remmina.Remmina", workspace = "6", no_initial_focus = true },
  { class = "chatgpt", workspace = "9", no_initial_focus = true },
  { class = "^(herdr|Herdr)$", workspace = "1", no_initial_focus = true },
}

for _, rule in ipairs(workspaceRules) do
  o.window({ class = rule.class }, {
    workspace = rule.workspace,
    no_initial_focus = rule.no_initial_focus,
  })
end

-- Preserve the Ubuntu workaround for NVIDIA/Xwayland repaint glitches.
local flickerClasses = {
  "org-openstreetmap-josm-gui-MainApplication",
  "org.openstreetmap.josm",
  "onlyoffice-desktopeditors",
  "ONLYOFFICE Desktop Editors",
  "libreoffice.*",
}

for index, class in ipairs(flickerClasses) do
  o.window({ class = class }, {
    name = "flicker-workaround-" .. index,
    no_anim = true,
    no_blur = true,
  })
end

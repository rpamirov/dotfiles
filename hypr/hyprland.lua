-- Hyprland 0.55+ Lua configuration.
-- https://wiki.hypr.land/Configuring/Start/

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
    -- Keep adaptive sync disabled. Variable refresh rate can present as brightness
    -- flicker on NVIDIA, especially when an application changes its frame rate.
    vrr = 0,
})

local terminal = "/home/rpamirov/.local/kitty.app/bin/kitty"
local fileManager = "nautilus"
local menu = "wofi --show drun"

-- Environment ---------------------------------------------------------------

hl.env("HYPRCURSOR_THEME", "Nordzy-hyprcursors")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_SIZE", "24")
hl.env("GTK_THEME", "Nordic")
hl.env("GTK_APPLICATION_PREFER_DARK_THEME", "1")

-- Prefer native Wayland backends, with an X11 fallback where the toolkit
-- supports one. The semicolon in QT_QPA_PLATFORM is intentional.
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- LibreOffice's GTK3 VCL plugin follows GDK_BACKEND and therefore uses native
-- Wayland. This avoids the Xwayland presentation path on NVIDIA.
hl.env("SAL_USE_VCLPLUGIN", "gtk3")

-- Java AWT is still X11-only in the JRE used by JOSM. This is the correctly
-- spelled non-reparenting hint; do not globally force XToolkit via _JAVA_OPTIONS.
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")

-- Current NVIDIA variables recommended by the Hyprland documentation.
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- Keep the custom interactive PATH from the previous configuration.
hl.env("PATH", "/home/rpamirov/.cargo/bin:/usr/local/cuda-12.6/bin:/usr/local/go/bin:/home/rpamirov/.local/share/../bin:/home/rpamirov/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/home/rpamirov/.local/kitty.app/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")

hl.config({
    xwayland = {
        enabled = true,
    },

    general = {
        gaps_in = 5,
        gaps_out = 5,
        border_size = 1,
        col = {
            active_border = {
                colors = { "rgba(33ccffee)", "rgba(00ff99ee)" },
                angle = 45,
            },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = true,
        layout = "dwindle",
        allow_tearing = false,
    },

    decoration = {
        rounding = 10,
        rounding_power = 2,
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo = false,
        vrr = 0,
    },

    -- NVIDIA anti-flicker remains enabled, while direct scanout is disabled to
    -- keep fullscreen applications on Hyprland's synchronized composition path.
    opengl = {
        nvidia_anti_flicker = true,
    },
    render = {
        direct_scanout = 0,
    },
    cursor = {
        no_hardware_cursors = false,
    },

    input = {
        kb_layout = "us,ru",
        kb_options = "caps:escape,grp:alt_shift_toggle",
        kb_variant = "",
        kb_model = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Curves and animations -----------------------------------------------------

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

-- Keybindings ---------------------------------------------------------------

local mainMod = "SUPER"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exec_cmd("hyprlock"))

local regionScreenshot = [=[grim -g "$(slurp)" /tmp/satty-region.png && /home/rpamirov/.cargo/bin/satty --filename /tmp/satty-region.png --fullscreen --copy-command wl-copy --action-on-enter save-to-clipboard --early-exit]=]
local fullScreenshot = [=[grim /tmp/satty-full.png && /home/rpamirov/.cargo/bin/satty --filename /tmp/satty-full.png --fullscreen --copy-command wl-copy --action-on-enter save-to-clipboard --early-exit]=]

hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd(regionScreenshot))
hl.bind("PRINT", hl.dsp.exec_cmd(regionScreenshot))
hl.bind("CTRL + PRINT", hl.dsp.exec_cmd(fullScreenshot))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("/home/rpamirov/repos/dotfiles/hypr/wf-toggle-record.sh"))
hl.bind("CTRL + ALT + C", hl.dsp.exec_cmd("~/.config/hypr/report_template.sh ~/Workspace/qa_tools/host_scripts/.jira_report"))

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Window rules --------------------------------------------------------------

local workspaceRules = {
    { name = "rviz", class = "rviz", workspace = "8", no_initial_focus = true },
    { name = "tablet-8", class = "tablet", workspace = "8" },
    { name = "swri-console", class = "SwRI Console", workspace = "10", no_initial_focus = true },
    { name = "tablet-10", class = "Tablet", workspace = "10", no_initial_focus = true },
    { name = "firefox", class = "firefox_firefox", workspace = "2", no_initial_focus = true },
    { name = "telegram", class = "telegram-desktop_telegram-desktop", workspace = "3", no_initial_focus = true },
    { name = "mattermost", class = "Mattermost.Desktop", workspace = "4", no_initial_focus = true },
    { name = "google-chrome", class = "google-chrome", workspace = "5", no_initial_focus = true },
    { name = "remmina", class = "org.remmina.Remmina", workspace = "6", no_initial_focus = true },
    { name = "chatgpt", class = "chatgpt", workspace = "9", no_initial_focus = true },
}

for _, rule in ipairs(workspaceRules) do
    hl.window_rule({
        name = rule.name,
        match = { class = rule.class },
        workspace = rule.workspace,
        no_initial_focus = rule.no_initial_focus,
    })
end

-- Avoid compositor transitions and blur sampling around applications known to
-- expose NVIDIA/Xwayland repaint glitches. Native Wayland remains the primary fix.
local flickerClasses = {
    "org-openstreetmap-josm-gui-MainApplication",
    "org.openstreetmap.josm",
    "onlyoffice-desktopeditors",
    "ONLYOFFICE Desktop Editors",
    "libreoffice.*",
}

for i, class in ipairs(flickerClasses) do
    hl.window_rule({
        name = "flicker-workaround-" .. i,
        match = { class = class },
        no_anim = true,
        no_blur = true,
    })
end

-- Autostart -----------------------------------------------------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
    hl.exec_cmd("swaync")
    hl.exec_cmd("waybar")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("xbindkeys")
    hl.exec_cmd("snap run telegram-desktop")
    hl.exec_cmd("mattermost-desktop --enable-features=UseOzonePlatform,WaylandLinuxDrmSyncobj --ozone-platform=wayland")
    hl.exec_cmd("snap run firefox")
    hl.exec_cmd("google-chrome --enable-features=UseOzonePlatform,WaylandLinuxDrmSyncobj --ozone-platform=wayland")
    hl.exec_cmd("snap run remmina")
    hl.exec_cmd("chatgpt --ozone-platform=wayland --enable-features=WaylandLinuxDrmSyncobj")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("/home/rpamirov/.nix-profile/bin/blueman-applet")
    hl.exec_cmd("/home/rpamirov/repos/dotfiles/hypr/launch-ideco.sh")
end)

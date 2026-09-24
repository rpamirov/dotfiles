-- User applications migrated from the Ubuntu Hyprland session.
-- Omarchy already owns its shell, idle, wallpaper, and power-profile startup.

local function launch_if_present(command, executable)
  if o.cmd_present(executable or command:match("^[^ ]+")) then
    o.launch_on_start(command)
  end
end

-- Native package commands replace the old Ubuntu snap invocations.
launch_if_present("telegram-desktop")
launch_if_present("mattermost-desktop --enable-features=UseOzonePlatform,WaylandLinuxDrmSyncobj --ozone-platform=wayland")
launch_if_present("firefox")
launch_if_present("google-chrome --enable-features=UseOzonePlatform,WaylandLinuxDrmSyncobj --ozone-platform=wayland")
launch_if_present("remmina")
launch_if_present("chatgpt --ozone-platform=wayland --enable-features=WaylandLinuxDrmSyncobj")
launch_if_present("herdr")

-- Tray utilities are optional on this machine and should not create startup
-- errors when their packages are not installed.
launch_if_present("nm-applet")
launch_if_present("blueman-applet")
launch_if_present("xbindkeys")

-- Start the user service after the graphical session comes up.  The service
-- reads Ideco's persisted auto-connect state and owns the VPN process.
if o.cmd_present("systemctl") then
  o.launch_on_start("systemctl --user start ideco-session.service")
  o.launch_on_start("systemctl --user start wayvnc.service")
end

-- Leave startup on the working workspace after autostart applications have
-- had time to open on their assigned workspaces.
if o.cmd_present("sh") then
  o.launch_on_start("sh -c 'sleep 8; hyprctl dispatch workspace 8'")
end

require("hypr.windows")

-- Host-specific overrides for the shared Hyprland configuration.
-- Keep the base config portable; add a profile here only when hardware or
-- installed software genuinely differs between machines.

local hostname = os.getenv("HOSTNAME") or ""

local profiles = {
    desktop = {
        nvidia = true,
    },
    thinkpad = {
        nvidia = false,
    },
}

local profile = profiles[hostname] or profiles.thinkpad
profile.hostname = hostname

return profile

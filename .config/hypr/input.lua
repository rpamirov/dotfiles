-- Portable Omarchy keyboard override.
-- Keep English first so Omarchy's Super-key bindings use Latin keysyms.
hl.config({
  input = {
    kb_layout = "us,ru",
    kb_options = "caps:escape,grp:alt_shift_toggle",
  },
})

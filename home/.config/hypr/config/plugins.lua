-- Local Hyprland plugins.
--
-- Hypredging moves a window to the neighbouring workspace when it is dragged
-- to the left or right screen edge and held there. It is not packaged for this
-- Hyprland version, so the binary is built against the installed ABI and kept
-- under ~/.local/lib/hyprland.
--
-- Declarative on purpose: `hl.plugin.load` records the path, Hyprland loads it
-- after the first config pass and reloads the config, and only then are the
-- plugin's config keys valid. The same file also runs on that second pass, so
-- this stays in sync with a plain `hyprctl reload`.
--
-- At session start, autostart.lua additionally runs ~/.local/bin/hypr-plugins,
-- which loads the library with `hyprctl plugin load` if the declarative path
-- did not (and re-applies the options at runtime).
hl.plugin.load("/home/zxx/.local/lib/hyprland/hypredging.so")

hl.config({
    plugin = {
        hypredging = {
            -- How long a dragged window must sit at the edge before the
            -- workspace switches: 350 ms is long enough that a quick drag
            -- across the screen never triggers, short enough that holding the
            -- window there feels deliberate instead of laggy.
            edge_delay_ms = 350,
            -- Cooldown before the same edge can fire again, so one long hold
            -- moves exactly one workspace.
            rearm_delay_ms = 350,
        },
    },
})

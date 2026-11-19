-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	-- Start whichever desktop shell was selected last (Noctalia or Ukishima).
	-- Toggle at runtime with Super+Shift+U, or run: shell-switch toggle
	hl.exec_cmd("/home/zxx/.local/bin/shell-switch autostart")
	-- Watchdog: even if a shell is launched directly from a menu, never let
	-- Noctalia and Ukishima both stay alive. Only the saved selection survives.
	hl.exec_cmd("setsid -f /home/zxx/.local/bin/shell-switch guard >> /home/zxx/.cache/shell-switch-guard.log 2>&1")
	-- Hypredging: drag a window to the left/right screen edge and hold to move
	-- it to the previous/next workspace. Loaded here because a runtime config
	-- load cannot pull in a new library.
	hl.exec_cmd("/home/zxx/.local/bin/hypr-plugins")
	-- Idle ladder: 10 min to a shell-aware lock (media playback postpones it),
	-- then 5 min to suspend. hypridle is unpackaged for this Hyprland build, so
	-- it runs from ~/.local/bin with a user config.
	hl.exec_cmd(
		"sh -c 'pgrep -x hypridle >/dev/null || setsid -f /home/zxx/.local/bin/hypridle -c /home/zxx/.config/hypr/hypridle.conf >> /home/zxx/.cache/hypridle.log 2>&1'"
	)
	-- Keep app colors in sync with the current wallpaper (also watches changes).
	hl.exec_cmd(
		"setsid -f sh -c '/home/zxx/.local/bin/wallpaper-theme watch >> /home/zxx/.cache/wallpaper-theme/watch.log 2>&1'"
	)
	hl.exec_cmd("xhost +SI:localuser:root")
	hl.exec_cmd("localsend")
	hl.exec_cmd("viber")
	hl.exec_cmd("keepassxc")
	hl.exec_cmd("syncthing serve")
end)

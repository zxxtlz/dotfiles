-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    -- Start whichever desktop shell was selected last (Noctalia or Ukishima).
    -- Toggle at runtime with Super+Shift+U, or run: shell-switch toggle
    hl.exec_cmd("/home/zxx/.local/bin/shell-switch autostart")
    -- Keep app colors in sync with the current wallpaper (also watches changes).
    hl.exec_cmd("setsid -f sh -c '/home/zxx/.local/bin/wallpaper-theme watch >> /home/zxx/.cache/wallpaper-theme/watch.log 2>&1'")
    hl.exec_cmd("xhost +SI:localuser:root")
    hl.exec_cmd("localsend")
    hl.exec_cmd("viber")
    hl.exec_cmd("syncthing serve")
end)

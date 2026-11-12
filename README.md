# dotfiles

My personal Linux desktop setup — **CachyOS + Hyprland (Wayland)**.

The repo mirrors my home directory under [`home/`](home/), and `install.sh`
symlinks everything into place. Existing files are backed up, never deleted.

## What's inside

| Area | Files |
| --- | --- |
| **Shell** | `~/.bashrc`, `~/.bash_profile`, `~/.bash_logout`, `~/.zshrc`, `~/.config/fish/config.fish` |
| **Window manager** | `~/.config/hypr/` — Lua-based Hyprland config: binds, animations, monitors, window rules, workspaces, autostart |
| **Terminals** | `~/.config/kitty/`, `~/.config/alacritty/` (incl. Noctalia/wallpaper themes) |
| **Editor** | `~/.vimrc`, `~/.config/nvim/` (LazyVim), `~/.config/micro/` |
| **Desktop theme** | `~/.config/gtk-3.0/`, `~/.config/gtk-4.0/`, `~/.config/qt5ct/`, `~/.config/qt6ct/`, `kdeglobals`, `xsettingsd`, `mimeapps.list` |
| **Bars & widgets** | `~/.config/noctalia/`, `~/.config/rofi/`, `~/.config/btop/`, `~/.config/cava/` |
| **Session / audio** | `~/.config/uwsm/`, `~/.config/wireplumber/`, `~/.config/systemd/user/cliphist-store.service` |
| **Scripts** | `~/.local/bin/` — screenshot, shell-switch, wallpaper-theme, update-all, rofi-shortcuts, … |

## Install

```bash
git clone https://github.com/zxxtlz/dotfiles.git ~/dotfiles
cd ~/dotfiles

./install.sh --dry-run   # preview what will happen
./install.sh             # symlink everything into $HOME
```

Then log out and back in (or restart Hyprland) so the session picks up the
new config.

### Options

| Command | Effect |
| --- | --- |
| `./install.sh` | Symlink dotfiles into `$HOME` (default) |
| `./install.sh --copy` | Copy files instead of symlinking |
| `./install.sh --dry-run` | Print actions, change nothing |
| `./install.sh --backup-dir DIR` | Put replaced files in `DIR` |
| `./install.sh --help` | Show usage |

### How it works

- Files in `home/` are linked to the same path in your home directory.
- Directories that must be shared with other apps (`~/.config`, `~/.local/bin`)
  are **merged**: each child is linked individually, so your existing
  `~/.config` is not replaced by a single symlink.
- Anything already at a destination is moved to
  `~/.local/state/dotfiles-backups/<timestamp>/` first.
- Re-running the script is safe; links that are already correct are skipped.

### Uninstall

```bash
./uninstall.sh
```

This only removes symlinks that point into this repo. It leaves real files
alone. Restore anything you need from the backup directory printed by the
installer (`~/.local/state/dotfiles-backups/`).

## Dependencies

The configs assume a Wayland/Hyprland desktop. On Arch/CachyOS:

```bash
sudo pacman -S --needed git fish kitty alacritty neovim vim micro btop cava \
  rofi wl-clipboard cliphist slurp grim jq python qt5ct qt6ct gtk3 gtk4 \
  wireplumber uwsm
```

Also installed separately on my machine:

- **Hyprland** (with Lua config support) and `xdg-desktop-portal-hyprland`
- **Noctalia** shell (`~/.config/noctalia/`)
- **Bibata-Modern-Ice** cursor theme (referenced by `uwsm/env`)
- `swash`, `librepods`, Lunar Client, Viber (autostart entries — delete them
  if you don't use those apps)
- `sourcekit-lsp` for the Swift Neovim plugin

## Notes

- **No secrets are committed.** Credentials, SSH keys, browser profiles,
  keyrings, clipboard history and app state are excluded (see `.gitignore`).
- Fish's `fish_variables` is intentionally not tracked — it contains
  machine-specific absolute paths. Recreate universal variables with
  `fish_config` if needed.
- Some configs contain absolute `/home/zxx` paths. If your username differs,
  adjust them after cloning.
- Neovim uses [LazyVim](https://lazyvim.github.io/); plugins install
  automatically on first launch.

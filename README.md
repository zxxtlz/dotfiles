# dotfiles

My personal Linux desktop setup — **CachyOS + Hyprland (Wayland)**.

> **Read this first:** these are my real configs, not a portable distro.
> `install.sh` only symlinks files — it does **not** install packages.
> Get the prerequisites below in place, or the setup will look/behave
> differently (or not start at all).

The repo mirrors my home directory under [`home/`](home/), and `install.sh`
symlinks everything into place. Existing files are backed up, never deleted.

## Requirements

### OS and session

- **CachyOS Linux** (Arch-based) — what this setup is built and tested on.
  Plain **Arch Linux** works too with the same packages; other distros
  (Fedora, Debian, …) can work, but package names and Hyprland versions
  differ and you'll need to adapt things yourself.
- **Wayland session** running **Hyprland 0.57+**. This config is
  **Lua-based** (`~/.config/hypr/hyprland.lua`), not the classic
  `hyprland.conf`, so it needs a Hyprland build with Lua config support.
- **UWSM** for session startup (`~/.config/uwsm/env`) and a working systemd
  user session (used by the cliphist clipboard service).
- **Noctalia** desktop shell — provides the bar, panels and wallpaper layer.
  My config is included; the shell itself is a package.
- **MesloLGS Nerd Font Mono** (`ttf-meslo-nerd`) — used by kitty, alacritty,
  btop, rofi and Neovim icons. Without it, everything falls back to a plain
  monospace font.
- **Bibata-Modern-Ice** cursor theme — referenced by `uwsm/env`, GTK and
  xsettingsd. Not bundled here (the files are ~28 MB); install it separately.

### Packages

Core packages on CachyOS/Arch:

```bash
sudo pacman -S --needed \
  hyprland uwsm xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  kitty alacritty fish zsh bash neovim vim micro \
  btop cava rofi wl-clipboard cliphist slurp grim jq python python-pillow \
  gtk3 gtk4 adw-gtk-theme qt5ct qt6ct wireplumber \
  dolphin librewolf noctalia swash hyprmon-bin awww \
  ttf-meslo-nerd ttf-fantasque-nerd
```

CachyOS also ships defaults that my configs source/assume:

```bash
sudo pacman -S --needed cachyos-fish-config cachyos-zsh-config \
  cachyos-alacritty-config cachyos-micro-settings cachyos-hypr-noctalia
```

Some packages (`noctalia`, `swash`, `hyprmon-bin`, `awww`) may come from the
CachyOS repos or the AUR — use `paru -S …` / `yay -S …` if `pacman` can't
find them. On non-Arch distros, install the equivalents and adjust the
`source /usr/share/cachyos-*` lines in the shell configs.

Optional but assumed by parts of the setup:

- `fish-pure-prompt`, `fish-autopair`, `fisher` — fish prompt and UX
- `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`,
  `zsh-history-substring-search`, `zsh-theme-powerlevel10k` — zsh setup
- Swift toolchain + `sourcekit-lsp` — Neovim Swift support
- `syncthing`, `localsend`, `viber`, `librepods`, Lunar Client — autostart
  entries in `~/.config/hypr/config/autostart.lua`; delete them if unused

`install.sh` will link configs even for apps you don't have — those configs
simply do nothing until the app is installed.

### Not included

- **Wallpapers and Noctalia's wallpaper state.** The palette generated from
  my current wallpaper is committed (kitty/alacritty/GTK/Qt themes and
  `hypr/config/wallpaper-colors.lua`), so colors match out of the box — but
  the wallpaper image itself is not here, and `wallpaper-theme watch` will
  re-derive colors from whatever wallpaper you use.
- **Cursor theme files** (Bibata) — install the theme package yourself.
- **Ukishima** shell — the alternative shell that `shell-switch` can toggle
  to. Noctalia is the default.
- **Secrets and app state** — SSH/GPG keys, credentials, browser profiles,
  clipboard history, `fish_variables`, Steam/Viber/Lunar data, etc.

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

## Notes

- **No secrets are committed.** Credentials, SSH keys, browser profiles,
  keyrings, clipboard history and app state are excluded (see `.gitignore`).
- Fish's `fish_variables` is intentionally not tracked — it contains
  machine-specific absolute paths. Recreate universal variables with
  `fish_config` if needed.
- Some configs contain absolute `/home/zxx` paths. If your username differs,
  adjust them after cloning (notably `hypr/config/autostart.lua`,
  `hypr/config/binds.lua`, `noctalia/config.toml` and `local/bin/rofi-shortcuts`).
- Neovim uses [LazyVim](https://lazyvim.github.io/); plugins install
  automatically on first launch.

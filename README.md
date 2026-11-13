# dotfiles

My personal Linux desktop setup — **CachyOS + Hyprland (Wayland)**.

> **Read this first:** these are my real configs, not a portable distro.
> On CachyOS/Arch, `install.sh` installs the required packages and then
> symlinks the configs. On other distros it can only link files
> (`--no-packages`), so install the equivalents yourself first.

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
  xsettingsd. Not bundled here (the files are ~28 MB); `install.sh` installs
  it from the AUR.

### Packages

The installer can install everything below automatically on Arch-based
distros — `pacman` for repo packages and `paru`/`yay` for the two AUR
packages. To install the core set manually instead:

```bash
sudo pacman -S --needed \
  hyprland uwsm xdg-desktop-portal-hyprland xdg-desktop-portal-gtk \
  kitty alacritty fish zsh neovim vim micro \
  noctalia swash awww rofi btop cava \
  wl-clipboard cliphist slurp grim jq python python-pillow \
  gtk3 gtk4 adw-gtk-theme qt5ct qt6ct wireplumber dolphin \
  ttf-meslo-nerd ttf-fantasque-nerd

# AUR (or let install.sh do it through paru/yay)
paru -S --needed hyprmon-bin bibata-cursor-theme
```

CachyOS also ships defaults that my configs source/assume:

```bash
sudo pacman -S --needed cachyos-fish-config cachyos-zsh-config \
  cachyos-alacritty-config cachyos-micro-settings cachyos-hypr-noctalia
```

The installer adds those only when they exist in your configured repos, so
plain Arch simply skips them. On non-Arch distros, install equivalents and
adjust the `source /usr/share/cachyos-*` lines in the shell configs.

Optional extras (installed with `./install.sh --optional`):

- `fish-pure-prompt`, `fish-autopair`, `fisher` — fish prompt and UX
- `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions`,
  `zsh-history-substring-search`, `zsh-theme-powerlevel10k` — zsh setup
- `librewolf` — my default browser
- `syncthing` — started from Hyprland autostart
- Swift toolchain + `sourcekit-lsp` — Neovim Swift support (not packaged here)
- `localsend`, `viber`, `librepods`, Lunar Client — autostart entries in
  `~/.config/hypr/config/autostart.lua`; delete them if unused

`install.sh` will link configs even for apps you don't have — those configs
simply do nothing until the app is installed.

### Not included

- **Wallpapers and Noctalia's wallpaper state.** The palette generated from
  my current wallpaper is committed (kitty/alacritty/GTK/Qt themes and
  `hypr/config/wallpaper-colors.lua`), so colors match out of the box — but
  the wallpaper image itself is not here, and `wallpaper-theme watch` will
  re-derive colors from whatever wallpaper you use.
- **Cursor theme files** (Bibata) — installed from the AUR by `install.sh`;
  with `--no-packages`, install `bibata-cursor-theme` yourself.
- **Ukishima** shell — the alternative shell that `shell-switch` can toggle
  to. Noctalia is the default.
- **Secrets and app state** — SSH/GPG keys, credentials, browser profiles,
  clipboard history, `fish_variables`, Steam/Viber/Lunar data, etc.

## Install

```bash
git clone https://github.com/zxxtlz/dotfiles.git ~/dotfiles
cd ~/dotfiles

./install.sh --dry-run   # show packages + link changes
./install.sh             # install packages, then symlink
```

`install.sh` will:

1. detect your distro and split packages into repo vs. AUR,
2. show the list and ask for confirmation,
3. install with `pacman` (and `paru`/`yay` for AUR packages),
4. back up existing dotfiles and symlink mine into `$HOME`,
5. enable `cliphist-store.service` when a systemd user session is available.

Then log out and back in (or restart Hyprland) so the session picks up the
new config.

### Options

| Command | Effect |
| --- | --- |
| `./install.sh` | Install required packages, then symlink dotfiles |
| `./install.sh --no-packages` | Skip packages; only symlink (use on non-Arch) |
| `./install.sh --packages-only` | Install packages, skip linking |
| `./install.sh --optional` | Also install optional extras (plugins, browser, …) |
| `./install.sh --no-aur` | Never use paru/yay for AUR packages |
| `./install.sh --yes`, `-y` | Assume yes for prompts (non-interactive) |
| `./install.sh --copy` | Copy files instead of symlinking |
| `./install.sh --dry-run` | Print actions, change nothing |
| `./install.sh --backup-dir DIR` | Put replaced files in `DIR` |
| `./install.sh --help` | Show usage |

If `paru`/`yay` is not installed, the two AUR packages (`hyprmon-bin`,
`bibata-cursor-theme`) are listed with a manual install command instead of
being installed automatically.

### How it works

- Required packages are installed from your configured repos with `pacman`;
  AUR-only packages go through `paru`/`yay` when available.
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
| **Desktop theme** | `~/.config/gtk-3.0/`, `~/.config/gtk-4.0/`, `~/.config/qt5ct/`, `~/.config/qt6ct/`, `~/.config/nwg-look/`, `kdeglobals`, `xsettingsd`, `mimeapps.list` |
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

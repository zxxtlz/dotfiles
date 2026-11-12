#!/usr/bin/env bash
#
# install.sh — install required packages, then link this repo's dotfiles.
#
# Designed for CachyOS/Arch-based systems. On other distros use
# --no-packages to only create the symlinks.
#
# Usage:
#   ./install.sh              install packages, then symlink dotfiles
#   ./install.sh --no-packages    skip packages, only symlink
#   ./install.sh --packages-only  install packages, skip linking
#   ./install.sh --dry-run        show everything, change nothing
#   ./install.sh --help
#
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$REPO_DIR/home"
HOME_DIR="${HOME:?HOME is not set}"

# Directories whose *children* are linked individually, so they merge with
# whatever is already in $HOME (e.g. ~/.config must not become one big symlink).
MERGE_DIRS=(
  ".config"
  ".local/bin"
)

# ---------------------------------------------------------------------------
# Packages
# ---------------------------------------------------------------------------

# Everything strictly needed for the desktop to look and work as intended.
REQUIRED_PACKAGES=(
  # Hyprland session
  hyprland
  uwsm
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  # Terminals and shells
  kitty
  alacritty
  fish
  zsh
  neovim
  vim
  micro
  # Desktop shell, bar and widgets
  noctalia
  swash
  awww
  rofi
  btop
  cava
  # Clipboard, screenshots and scripting
  wl-clipboard
  cliphist
  slurp
  grim
  jq
  python
  python-pillow
  # Themes and appearance
  gtk3
  gtk4
  adw-gtk-theme
  qt5ct
  qt6ct
  wireplumber
  dolphin
  ttf-meslo-nerd
  ttf-fantasque-nerd
)

# Nice-to-have packages, installed with --optional.
OPTIONAL_PACKAGES=(
  librewolf
  fish-pure-prompt
  fish-autopair
  fisher
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  zsh-history-substring-search
  zsh-theme-powerlevel10k
  syncthing
)

# CachyOS-specific defaults that the shell/editor configs source. Only
# installed when they are available in the configured repos.
CACHYOS_PACKAGES=(
  cachyos-fish-config
  cachyos-zsh-config
  cachyos-alacritty-config
  cachyos-micro-settings
  cachyos-hypr-noctalia
  cachyos-wallpapers
)

# Packages that live in the AUR on Arch (and are installed by hand on this
# machine). Installed through paru/yay when available.
AUR_PACKAGES=(
  hyprmon-bin
  bibata-cursor-theme
)

# ---------------------------------------------------------------------------
# Options
# ---------------------------------------------------------------------------

MODE="link"          # link | copy
DRY_RUN=0
ASSUME_YES=0
INSTALL_PACKAGES=1
LINK_FILES=1
INSTALL_OPTIONAL=0
ALLOW_AUR=1
BACKUP_DIR=""

usage() {
  cat <<'EOF'
Full dotfiles installer: installs system packages, then links the configs.

Usage:
  ./install.sh [OPTIONS]

Options:
  --no-packages      Do not install packages; only link dotfiles.
  --packages-only    Install packages, but do not link dotfiles.
  --optional         Also install optional extras (fish/zsh plugins, browser).
  --no-aur           Do not use paru/yay for AUR-only packages.
  --yes, -y          Assume "yes" for all prompts (non-interactive).
  --copy             Copy files instead of creating symlinks.
  --dry-run          Print actions without changing anything.
  --backup-dir DIR   Where to move files that are being replaced.
                     Default: ~/.local/state/dotfiles-backups/<timestamp>
  -h, --help         Show this help.

Existing files are never deleted: they are moved into the backup directory
first. Symlinks that already point into this repo are left alone.

Supported systems: CachyOS and other Arch-based distros (pacman).
On other distros, run: ./install.sh --no-packages
EOF
}

while (($#)); do
  case "$1" in
    --no-packages) INSTALL_PACKAGES=0 ;;
    --packages-only) LINK_FILES=0 ;;
    --optional) INSTALL_OPTIONAL=1 ;;
    --no-aur) ALLOW_AUR=0 ;;
    --yes|-y) ASSUME_YES=1 ;;
    --copy) MODE="copy" ;;
    --dry-run) DRY_RUN=1 ;;
    --backup-dir)
      [[ $# -ge 2 ]] || { echo "error: --backup-dir needs a value" >&2; exit 1; }
      BACKUP_DIR="$2"
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

# Colors (only when stdout is a terminal)
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_DIM=$'\033[2m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'; C_RED=$'\033[31m'
else
  C_RESET=''; C_DIM=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_RED=''
fi

action() { printf '%s  %s%s\n' "$1" "$2" "$C_RESET"; }
section() { printf '\n%s== %s ==%s\n' "$C_BLUE" "$1" "$C_RESET"; }
die() { printf '%serror:%s %s\n' "$C_RED" "$C_RESET" "$1" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Package helpers
# ---------------------------------------------------------------------------

SUDO=()

pkg_installed() { pacman -Q "$1" >/dev/null 2>&1; }
pkg_available() { pacman -Si "$1" >/dev/null 2>&1; }

AUR_HELPER=""
detect_aur_helper() {
  local h
  for h in paru yay; do
    if command -v "$h" >/dev/null 2>&1; then
      AUR_HELPER="$h"
      return 0
    fi
  done
  return 1
}

confirm() {
  local prompt="$1"
  (( ASSUME_YES )) && return 0
  if [[ ! -t 0 ]]; then
    printf '%s\n' "Non-interactive shell: pass --yes to proceed." >&2
    return 1
  fi
  local reply
  read -r -p "$prompt [Y/n] " reply
  [[ -z "$reply" || "$reply" =~ ^[Yy]$ ]]
}

print_list() {
  local label="$1"; shift
  if (($# == 0)); then return; fi
  printf '%s (%d):\n' "$label" "$#"
  printf '  %s\n' "$*" | fold -s -w 100 | sed '2,$s/^/  /'
}

install_packages() {
  section "Packages"

  if ! command -v pacman >/dev/null 2>&1; then
    printf '%s\n' "${C_YELLOW}pacman not found — this is not an Arch-based distro.${C_RESET}"
    printf '%s\n' "Skipping package installation. Link files later with: ./install.sh --no-packages"
    return 0
  fi

  if (( EUID != 0 )); then
    if command -v sudo >/dev/null 2>&1; then
      SUDO=(sudo)
    else
      die "sudo is required to install packages (or run as root)."
    fi
  fi

  # Load distro name for the summary and CachyOS detection.
  local distro="unknown"
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    distro="${PRETTY_NAME:-${NAME:-unknown}}"
  fi

  local wanted=("${REQUIRED_PACKAGES[@]}")
  if (( INSTALL_OPTIONAL )); then
    wanted+=("${OPTIONAL_PACKAGES[@]}")
  fi

  # Split into: already installed, available in repos, missing entirely.
  local repo_pkgs=() installed_pkgs=() missing_pkgs=() cachyos_skipped=()
  local p
  for p in "${wanted[@]}"; do
    if pkg_installed "$p"; then
      installed_pkgs+=("$p")
    elif pkg_available "$p"; then
      repo_pkgs+=("$p")
    else
      missing_pkgs+=("$p")
    fi
  done

  for p in "${CACHYOS_PACKAGES[@]}"; do
    if pkg_installed "$p"; then
      installed_pkgs+=("$p")
    elif pkg_available "$p"; then
      repo_pkgs+=("$p")
    elif [[ "${ID:-}" == "cachyos" ]]; then
      missing_pkgs+=("$p")
    else
      cachyos_skipped+=("$p")
    fi
  done

  # AUR packages: skip ones that are already present.
  local aur_pkgs=()
  if (( ALLOW_AUR )); then
    detect_aur_helper || true
    for p in "${AUR_PACKAGES[@]}"; do
      pkg_installed "$p" || aur_pkgs+=("$p")
    done
    if ((${#aur_pkgs[@]})) && [[ -z "$AUR_HELPER" ]]; then
      missing_pkgs+=("${aur_pkgs[@]}")
      aur_pkgs=()
    fi
    if (( EUID == 0 )) && ((${#aur_pkgs[@]})); then
      printf '%s\n' "${C_YELLOW}AUR helper cannot run as root; install these manually:${C_RESET} ${aur_pkgs[*]}"
      aur_pkgs=()
    fi
  else
    for p in "${AUR_PACKAGES[@]}"; do
      pkg_installed "$p" || missing_pkgs+=("$p")
    done
  fi

  echo "  distro: $distro"

  if ((${#repo_pkgs[@]} == 0 && ${#aur_pkgs[@]} == 0)); then
    action "${C_GREEN}ok${C_RESET}" "nothing to install from the configured repos"
    if ((${#missing_pkgs[@]})); then
      print_list "Manual install needed" "${missing_pkgs[@]}"
    fi
    return 0
  fi

  print_list "Repo packages" "${repo_pkgs[@]}"
  if ((${#aur_pkgs[@]})); then
    print_list "AUR packages (via ${AUR_HELPER:-helper})" "${aur_pkgs[@]}"
  fi
  if ((${#missing_pkgs[@]})); then
    print_list "Not found in configured repos" "${missing_pkgs[@]}"
  fi
  if ((${#cachyos_skipped[@]})); then
    printf '%s\n' "${C_DIM}Skipping CachyOS-only packages: ${cachyos_skipped[*]}${C_RESET}"
  fi

  if (( DRY_RUN )); then
    echo
    echo "Dry run: would run the commands above and skip installation."
    return 0
  fi

  echo
  if ! confirm "Install these packages now?"; then
    echo "Package installation cancelled."
    return 1
  fi

  if ((${#repo_pkgs[@]})); then
    echo
    echo "Installing repo packages…"
    "${SUDO[@]}" pacman -S --needed --noconfirm "${repo_pkgs[@]}"
  fi

  if ((${#aur_pkgs[@]})); then
    echo
    echo "Installing AUR packages with $AUR_HELPER…"
    "$AUR_HELPER" -S --needed --noconfirm "${aur_pkgs[@]}"
  fi

  if ((${#missing_pkgs[@]})); then
    echo
    printf '%s\n' "${C_YELLOW}These packages were not installed automatically:${C_RESET}"
    printf '  %s\n' "${missing_pkgs[@]}"
    echo "Install them manually from the AUR or your distro's repos if needed."
  fi

  action "${C_GREEN}ok${C_RESET}" "package installation finished"
}

# ---------------------------------------------------------------------------
# Dotfile linking
# ---------------------------------------------------------------------------

if [[ ! -d "$SOURCE_DIR" ]]; then
  die "$SOURCE_DIR not found (run this script from the repo)"
fi

if [[ -z "$BACKUP_DIR" ]]; then
  BACKUP_DIR="${XDG_STATE_HOME:-$HOME_DIR/.local/state}/dotfiles-backups/$(date +%Y%m%d-%H%M%S)"
fi
BACKUP_DIR="${BACKUP_DIR/#\~/$HOME_DIR}"

install_entry() {
  local src="$1"
  local dst="$2"
  local rel="${dst#"$HOME_DIR"/}"

  # Already pointing at the right place? Nothing to do.
  if [[ -L "$dst" && "$(readlink -f -- "$dst")" == "$(readlink -f -- "$src")" ]]; then
    action "${C_DIM}ok${C_RESET}" "already linked  ~/$rel"
    return
  fi

  # Back up anything that is already there (files, dirs, or foreign symlinks).
  if [[ -e "$dst" || -L "$dst" ]]; then
    if (( DRY_RUN )); then
      action "${C_YELLOW}would back up${C_RESET}" "~/$rel -> $BACKUP_DIR/$rel"
    else
      mkdir -p -- "$(dirname -- "$BACKUP_DIR/$rel")"
      mv -- "$dst" "$BACKUP_DIR/$rel"
      action "${C_YELLOW}backed up${C_RESET}" "~/$rel -> $BACKUP_DIR/$rel"
    fi
  fi

  if (( DRY_RUN )); then
    if [[ "$MODE" == "copy" ]]; then
      action "${C_BLUE}would copy${C_RESET}" "$src -> ~/$rel"
    else
      action "${C_BLUE}would link${C_RESET}" "~/$rel -> $src"
    fi
    return
  fi

  mkdir -p -- "$(dirname -- "$dst")"
  if [[ "$MODE" == "copy" ]]; then
    cp -a -- "$src" "$dst"
    action "${C_GREEN}copied${C_RESET}" "~/$rel"
  else
    ln -s -- "$src" "$dst"
    action "${C_GREEN}linked${C_RESET}" "~/$rel"
  fi
}

link_dotfiles() {
  section "Dotfiles"
  echo "  repo:   $REPO_DIR"
  echo "  home:   $HOME_DIR"
  echo "  mode:   $MODE$([ "$DRY_RUN" -eq 1 ] && echo ' (dry run)')"
  echo "  backup: $BACKUP_DIR"
  echo

  if (( ! DRY_RUN )); then
    mkdir -p "$BACKUP_DIR"
  fi

  # 1. Merge directories: link each child individually.
  local merge src_root child name
  for merge in "${MERGE_DIRS[@]}"; do
    src_root="$SOURCE_DIR/$merge"
    [[ -d "$src_root" ]] || continue
    while IFS= read -r -d '' child; do
      install_entry "$child" "$HOME_DIR/$merge/$(basename -- "$child")"
    done < <(find "$src_root" -mindepth 1 -maxdepth 1 -print0 | sort -z)
  done

  # 2. Everything else in home/: link the entry itself.
  while IFS= read -r -d '' child; do
    name="$(basename -- "$child")"
    case "$name" in
      .config|.local) continue ;;   # handled above
    esac
    install_entry "$child" "$HOME_DIR/$name"
  done < <(find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -print0 | sort -z)

  # Enable the clipboard-history user service, if we are in a user session.
  if (( ! DRY_RUN )) && [[ -f "$HOME_DIR/.config/systemd/user/cliphist-store.service" ]]; then
    if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
      systemctl --user daemon-reload 2>/dev/null || true
      systemctl --user enable cliphist-store.service 2>/dev/null || true
      action "${C_GREEN}ok${C_RESET}" "enabled cliphist-store.service"
    else
      echo "note: enable the clipboard service after logging in with:"
      echo "      systemctl --user enable cliphist-store.service"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

echo
echo "${C_BLUE}Dotfiles installer${C_RESET}"

if (( INSTALL_PACKAGES )); then
  if ! install_packages; then
    echo "Stopping after package step."
    exit 1
  fi
fi

if (( LINK_FILES )); then
  link_dotfiles
fi

echo
if (( DRY_RUN )); then
  echo "Dry run complete. Nothing was changed."
else
  echo "Done. Log out and back in (or restart Hyprland) to pick up everything."
  echo "Replaced files (if any) are in: $BACKUP_DIR"
fi
echo

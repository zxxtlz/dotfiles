#!/usr/bin/env bash
#
# install.sh — symlink (or copy) this repo's dotfiles into $HOME.
#
# Usage:
#   ./install.sh              create symlinks (safe default)
#   ./install.sh --copy       copy files instead of symlinking
#   ./install.sh --dry-run    show what would happen, change nothing
#   ./install.sh --backup-dir DIR
#                             store replaced files in DIR instead of the default
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

MODE="link"          # link | copy
DRY_RUN=0
BACKUP_DIR=""

usage() {
  cat <<'EOF'
Install dotfiles by symlinking them into your home directory.

Usage:
  ./install.sh [OPTIONS]

Options:
  --copy             Copy files instead of creating symlinks.
  --dry-run          Print actions without changing anything.
  --backup-dir DIR   Where to move files that are being replaced.
                     Default: ~/.local/state/dotfiles-backups/<timestamp>
  -h, --help         Show this help.

Existing files are never deleted: they are moved into the backup directory
first. Symlinks that already point into this repo are left alone.
EOF
}

while (($#)); do
  case "$1" in
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
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
else
  C_RESET=''; C_DIM=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''
fi

action() { printf '%s  %s%s\n' "$1" "$2" "$C_RESET"; }

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "error: $SOURCE_DIR not found (run this script from the repo)" >&2
  exit 1
fi

if [[ -z "$BACKUP_DIR" ]]; then
  BACKUP_DIR="${XDG_STATE_HOME:-$HOME_DIR/.local/state}/dotfiles-backups/$(date +%Y%m%d-%H%M%S)"
fi
BACKUP_DIR="${BACKUP_DIR/#\~/$HOME_DIR}"

mkdir -p "$BACKUP_DIR"

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

echo
echo "${C_BLUE}Dotfiles installer${C_RESET}"
echo "  repo:   $REPO_DIR"
echo "  home:   $HOME_DIR"
echo "  mode:   $MODE$([ "$DRY_RUN" -eq 1 ] && echo ' (dry run)')"
echo "  backup: $BACKUP_DIR"
echo

# 1. Merge directories: link each child individually.
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

echo
if (( DRY_RUN )); then
  echo "Dry run complete. Nothing was changed."
else
  echo "Done. Log out and back in (or restart Hyprland) to pick up everything."
  echo "Replaced files (if any) are in: $BACKUP_DIR"
fi
echo

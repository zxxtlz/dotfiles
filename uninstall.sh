#!/usr/bin/env bash
#
# uninstall.sh — remove the symlinks created by install.sh.
#
# Only symlinks that point into this repository are removed. Real files and
# symlinks pointing elsewhere are never touched. Use --dry-run to preview.
#
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$REPO_DIR/home"
HOME_DIR="${HOME:?HOME is not set}"
MERGE_DIRS=(".config" ".local/bin")
DRY_RUN=0

usage() {
  cat <<'EOF'
Remove symlinks that point into this dotfiles repository.

Usage:
  ./uninstall.sh [--dry-run]

Options:
  --dry-run   Print what would be removed without changing anything.
  -h, --help  Show this help.

Files replaced during installation are not restored automatically; they live
in ~/.local/state/dotfiles-backups/<timestamp>/.
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

remove_entry() {
  local dst="$1"
  local rel="${dst#"$HOME_DIR"/}"

  if [[ -L "$dst" ]]; then
    local target
    target="$(readlink -- "$dst")"
    if [[ "$target" == "$REPO_DIR"/* ]]; then
      if (( DRY_RUN )); then
        echo "would remove  ~/$rel"
      else
        rm -- "$dst"
        echo "removed       ~/$rel"
      fi
      return
    fi
  fi
  echo "skipped       ~/$rel (not a link to this repo)"
}

for merge in "${MERGE_DIRS[@]}"; do
  src_root="$SOURCE_DIR/$merge"
  [[ -d "$src_root" ]] || continue
  while IFS= read -r -d '' child; do
    remove_entry "$HOME_DIR/$merge/$(basename -- "$child")"
  done < <(find "$src_root" -mindepth 1 -maxdepth 1 -print0 | sort -z)
done

while IFS= read -r -d '' child; do
  name="$(basename -- "$child")"
  case "$name" in
    .config|.local) continue ;;
  esac
  remove_entry "$HOME_DIR/$name"
done < <(find "$SOURCE_DIR" -mindepth 1 -maxdepth 1 -print0 | sort -z)

echo
if (( DRY_RUN )); then
  echo "Dry run complete. Nothing was changed."
else
  echo "Done. Backups (if any) are in ~/.local/state/dotfiles-backups/"
fi

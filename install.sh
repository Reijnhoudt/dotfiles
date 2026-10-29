#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mode="prompt"
case "${1:-}" in
  "")            ;;
  --overwrite)   mode="overwrite" ;;
  --backup)      mode="backup" ;;
  *)
    echo "Usage: $0 [--backup | --overwrite]" >&2
    exit 2
    ;;
esac

if [[ $# -gt 1 ]]; then
  echo "Usage: $0 [--backup | --overwrite]" >&2
  exit 2
fi

link() {
  local src="$1"
  local dest="$2"
  local action="$mode"
  local choice
  local stamp
  local backup
  local n

  mkdir -p "$(dirname "$dest")"

  if [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$src" ]]; then
    echo "Already linked: $dest"
    return
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$action" == "prompt" ]]; then
      while true; do
        if ! IFS= read -r -p "Found existing config: $dest — [A]bort all, [S]kip this config, [O]verwrite, or [B]ackup? " choice </dev/tty; then
          echo "No interactive terminal available; stopping." >&2
          return 1
        fi

        choice="$(printf '%s' "$choice" | tr '[:upper:]' '[:lower:]')"
        case "$choice" in
          a|abort)      echo "Aborted installation."; exit 1 ;;
          s|skip)       echo "Skipping: $dest"; return 0 ;;
          o|overwrite)  action="overwrite"; break ;;
          b|backup)     action="backup"; break ;;
          *)            echo "Enter Abort, Skip, Overwrite, or Backup (or A, S, O, or B)." >&2 ;;
        esac
      done
    fi

    case "$action" in
      overwrite)
        rm -rf "$dest"
        ;;
      backup)
        stamp="$(date +%Y%m%d-%H%M%S)"
        backup="${dest}.backup.${stamp}"
        n=1
        while [[ -e "$backup" || -L "$backup" ]]; do
          backup="${dest}.backup.${stamp}-$n"
          n=$((n + 1))
        done
        mv "$dest" "$backup"
        echo "Moved existing config to: $backup"
        ;;
    esac
  fi

  ln -s "$src" "$dest"
  echo "Linked: $dest"
}

link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
link "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"


#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"

  if [[ -L "$dest" ]]; then
    if [[ "$(readlink "$dest")" == "$src" ]]; then
      echo "Already linked: $dest"
      return
    fi
    echo "Refusing to replace a different symlink: $dest" >&2
    return 1
  elif [[ -e "$dest" ]]; then
    echo "Config already exists; move it aside first: $dest" >&2
    return 1
  fi

  ln -s "$src" "$dest"
  echo "Linked: $dest"
}

link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
link "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"


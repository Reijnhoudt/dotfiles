#!/usr/bin/env bash
set -euo pipefail
shopt -s nocasematch

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_NAMES=()
CONFIG_SRCS=()
CONFIG_DSTS=()

register_config() {
  CONFIG_NAMES+=("$1")
  CONFIG_SRCS+=("$2")
  CONFIG_DSTS+=("$3")
}

# Add future configs by adding another register_config line.
register_config "nvim" "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
register_config "tmux" "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

usage() {
  cat <<'HELP'
Usage:
  ./install_ui.sh
      Show the interactive menu.

  ./install_ui.sh --all
      Install all configurations without the menu.

  ./install_ui.sh --config NAME [--config NAME ...]
      Install selected configurations without the menu.

Options:
  --all                     Select all configurations.
  -c, --config NAME         Select a configuration; may be repeated.
  --on-conflict POLICY      Choose: abort, skip, overwrite, or backup.
                            In noninteractive mode, the default is abort.
  -h, --help                Show this help.

Examples:
  ./install_ui.sh --all --on-conflict backup
  ./install_ui.sh --config nvim --config tmux --on-conflict skip
HELP
}

config_is_installed() {
  local index="$1"
  local src="${CONFIG_SRCS[$index]}"
  local dest="${CONFIG_DSTS[$index]}"

  [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]
}

config_status() {
  local index="$1"
  local dest="${CONFIG_DSTS[$index]}"

  if config_is_installed "$index"; then
    printf 'Already installed'
  elif [[ -e "$dest" || -L "$dest" ]]; then
    printf 'Existing config'
  else
    printf 'Not installed'
  fi
}

display_target() {
  local path="$1"

  case "$path" in
    "$HOME"/*) printf '~/%s' "${path#"$HOME"/}" ;;
    *)         printf '%s' "$path" ;;
  esac
}

show_menu() {
  local name_width=13
  local index
  local status
  local target

  for index in "${!CONFIG_NAMES[@]}"; do
    if ((${#CONFIG_NAMES[$index]} > name_width)); then
      name_width="${#CONFIG_NAMES[$index]}"
    fi
  done

  printf '\nThe following configurations are available to install. Press A to install all.\n\n'
  printf '  %-3s  %-*s  %-20s  %s\n' \
    'No.' "$name_width" 'CONFIGURATION' 'STATUS' 'TARGET'

  for index in "${!CONFIG_NAMES[@]}"; do
    status="$(config_status "$index")"
    target="$(display_target "${CONFIG_DSTS[$index]}")"
    printf '  %-3s  %-*s  %-20s  %s\n' \
      "$((index + 1))" "$name_width" "${CONFIG_NAMES[$index]}" "$status" "$target"
  done
}

choose_configs() {
  local selection
  local choice
  local number
  local valid
  local index
  local -a choices

  while true; do
    for index in "${!CONFIG_NAMES[@]}"; do
      SELECTED[$index]=0
    done

    printf '\n  Enter a number, multiple numbers (for example: 1 2), A for all, or Q to quit.\n'
    IFS= read -r -p '  Selection: ' selection || exit 1

    case "$selection" in
      a)
        for index in "${!CONFIG_NAMES[@]}"; do
          SELECTED[$index]=1
        done
        return
        ;;
      q|quit)
        exit 0
        ;;
    esac

    choices=()
    IFS=', ' read -r -a choices <<< "$selection"
    valid=1

    if ((${#choices[@]} == 0)); then
      valid=0
    fi

    for choice in "${choices[@]}"; do
      if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
        valid=0
        break
      fi

      number=$((10#$choice))
      if ((number < 1 || number > ${#CONFIG_NAMES[@]})); then
        valid=0
        break
      fi
    done

    if ((valid)); then
      for choice in "${choices[@]}"; do
        number=$((10#$choice))
        SELECTED[$((number - 1))]=1
      done
      return
    fi

    printf '  Invalid selection. Choose a listed number, A, or Q.\n'
  done
}

install_config() {
  local index="$1"
  local name="${CONFIG_NAMES[$index]}"
  local src="${CONFIG_SRCS[$index]}"
  local dest="${CONFIG_DSTS[$index]}"
  local answer
  local action="$ON_CONFLICT"
  local backup
  local stamp
  local n

  if [[ ! -e "$src" ]]; then
    printf '  Source for %s was not found: %s\n' "$name" "$src" >&2
    return 1
  fi

  if config_is_installed "$index"; then
    printf '  Already installed: %s\n' "$name"
    return
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$action" == "prompt" ]]; then
      while true; do
        if ! IFS= read -r -p \
          "  Existing config for $name: [A]bort all, [S]kip, [O]verwrite, or [B]ackup? " \
          answer; then
          printf '\n  No input received; stopping.\n' >&2
          return 1
        fi

        case "$answer" in
          a|abort)     action="abort"; break ;;
          s|skip)      action="skip"; break ;;
          o|overwrite) action="overwrite"; break ;;
          b|backup)    action="backup"; break ;;
          *)           printf '  Enter Abort, Skip, Overwrite, or Backup (or A, S, O, or B).\n' ;;
        esac
      done
    fi

    case "$action" in
      abort)
        printf '  Conflict found at %s; aborting. Use --on-conflict to choose another action.\n' "$dest" >&2
        exit 1
        ;;
      skip)
        printf '  Skipping: %s\n' "$name"
        return
        ;;
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
        printf '  Backup saved as: %s\n' "$backup"
        ;;
    esac
  fi

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  printf '  Installed: %s\n' "$name"
}

CLI_SELECTION=0
SELECT_ALL=0
CLI_CONFIGS=()
ON_CONFLICT=""

while (($#)); do
  case "$1" in
    --all)
      CLI_SELECTION=1
      SELECT_ALL=1
      shift
      ;;
    -c|--config)
      if (($# < 2)); then
        printf 'Missing name after %s\n' "$1" >&2
        exit 2
      fi
      CLI_SELECTION=1
      CLI_CONFIGS+=("$2")
      shift 2
      ;;
    --config=*)
      CLI_SELECTION=1
      CLI_CONFIGS+=("${1#*=}")
      shift
      ;;
    --on-conflict)
      if (($# < 2)); then
        printf 'Missing policy after --on-conflict\n' >&2
        exit 2
      fi
      ON_CONFLICT="$2"
      shift 2
      ;;
    --on-conflict=*)
      ON_CONFLICT="${1#*=}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ((SELECT_ALL)) && ((${#CLI_CONFIGS[@]} > 0)); then
  printf 'Use --all or --config, not both.\n' >&2
  exit 2
fi

if [[ -n "$ON_CONFLICT" ]]; then
  case "$ON_CONFLICT" in
    abort|skip|overwrite|backup) ;;
    *)
      printf 'Invalid conflict policy: %s\n' "$ON_CONFLICT" >&2
      printf 'Choose abort, skip, overwrite, or backup.\n' >&2
      exit 2
      ;;
  esac
fi

SELECTED=()
for index in "${!CONFIG_NAMES[@]}"; do
  SELECTED[$index]=0
done

if ((CLI_SELECTION)); then
  if [[ -z "$ON_CONFLICT" ]]; then
    ON_CONFLICT="abort"
  fi

  if ((SELECT_ALL)); then
    for index in "${!CONFIG_NAMES[@]}"; do
      SELECTED[$index]=1
    done
  else
    for requested in "${CLI_CONFIGS[@]}"; do
      found=0
      for index in "${!CONFIG_NAMES[@]}"; do
        if [[ "${CONFIG_NAMES[$index]}" == "$requested" ]]; then
          SELECTED[$index]=1
          found=1
          break
        fi
      done

      if ((!found)); then
        printf 'Unknown configuration: %s\n' "$requested" >&2
        printf 'Available configurations: %s\n' "${CONFIG_NAMES[*]}" >&2
        exit 2
      fi
    done
  fi
else
  if [[ -z "$ON_CONFLICT" ]]; then
    ON_CONFLICT="prompt"
  fi
  show_menu
  choose_configs
fi

printf '\nProcessing selected configurations:\n'
for index in "${!CONFIG_NAMES[@]}"; do
  if ((SELECTED[$index])); then
    install_config "$index"
  fi
done

printf '\nDone.\n'

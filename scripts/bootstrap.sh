#!/usr/bin/env bash
#
# Bootstrap WSL/Linux dotfiles: symlink shell config and ~/.config/opencode
# from this repo into $HOME, then install oh-my-zsh if missing.
#
# Usage:
#   ./bootstrap.sh                  # uses $HOME/dotfiles
#   ./bootstrap.sh /path/to/repo    # explicit path
#

set -euo pipefail

DOTFILES_DIR="${1:-$HOME/dotfiles}"

green()  { printf '\033[32m%s\033[0m\n' "$*"; }
cyan()   { printf '\033[36m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
gray()   { printf '\033[90m%s\033[0m\n' "$*"; }

if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Dotfiles repo not found at: $DOTFILES_DIR" >&2
    exit 1
fi

WSL_DIR="$DOTFILES_DIR/wsl"
if [ ! -d "$WSL_DIR" ]; then
    echo "wsl/ folder not found at: $WSL_DIR" >&2
    exit 1
fi

stamp="$(date +%Y%m%d-%H%M%S)"

# Back up a real path then replace with a symlink to $2.
# Skips if already a symlink pointing to $2.
link_path() {
    local target="$1"
    local source="$2"

    if [ ! -e "$source" ] && [ ! -L "$source" ]; then
        yellow "  source missing, skipping: $source"
        return 0
    fi

    if [ -L "$target" ]; then
        local current
        current="$(readlink -f -- "$target")"
        local want
        want="$(readlink -f -- "$source")"
        if [ "$current" = "$want" ]; then
            gray "  already linked: $target"
            return 0
        fi
        yellow "  symlink exists but points elsewhere; removing"
        rm -- "$target"
    elif [ -e "$target" ]; then
        local backup="${target}.bak-${stamp}"
        yellow "  existing real path; moving to $backup"
        mv -- "$target" "$backup"
    fi

    mkdir -p "$(dirname -- "$target")"
    cyan "  linking $target -> $source"
    ln -s -- "$source" "$target"
    green "  linked $target"
}

cyan "==> Linking shell config files"
link_path "$HOME/.zshrc"    "$WSL_DIR/.zshrc"
link_path "$HOME/.bashrc"   "$WSL_DIR/.bashrc"
link_path "$HOME/.tmux.conf" "$WSL_DIR/.tmux.conf"
link_path "$HOME/.gitconfig" "$WSL_DIR/.gitconfig"

cyan "==> Linking ~/.config/opencode"
mkdir -p "$HOME/.config"
link_path "$HOME/.config/opencode" "$WSL_DIR/.config/opencode"

cyan "==> Checking oh-my-zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
    gray "  already installed at $HOME/.oh-my-zsh"
else
    yellow "  oh-my-zsh not found; installing (--keep-zshrc so the symlink survives)"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
    green "  oh-my-zsh installed"
fi

echo
green "Bootstrap complete."
echo "Start a new zsh session or run: source ~/.zshrc"

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

install_zsh() {
    cyan "  Installing zsh..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y zsh
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Syu --noconfirm zsh
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y zsh
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y zsh
    elif command -v apk >/dev/null 2>&1; then
        sudo apk add zsh
    elif command -v brew >/dev/null 2>&1; then
        brew install zsh
    else
        echo "  Could not find a supported package manager (apt-get, pacman, dnf, yum, apk, brew)." >&2
        echo "  Please install zsh manually." >&2
        exit 1
    fi
}

cyan "==> Checking zsh"
if ! command -v zsh >/dev/null 2>&1; then
    yellow "  Zsh is not installed."
    if read -p "  Would you like to install zsh? [y/N]: " -r response; then
        :
    else
        response="n"
    fi

    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        install_zsh
    else
        echo "  Zsh installation declined or script is non-interactive. Please install zsh manually." >&2
        exit 1
    fi
else
    gray "  zsh is already installed"
fi

cyan "==> Checking oh-my-zsh"
if [ -d "$HOME/.oh-my-zsh" ]; then
    gray "  already installed at $HOME/.oh-my-zsh"
else
    yellow "  oh-my-zsh not found; installing (--keep-zshrc so the symlink survives)"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
    green "  oh-my-zsh installed"
fi

cyan "==> Setting zsh as default shell"
ZSH_PATH="$(command -v zsh)"
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
    gray "  already set to $ZSH_PATH"
else
    yellow "  changing default shell from $CURRENT_SHELL to $ZSH_PATH"
    sudo chsh -s "$ZSH_PATH" "$USER"
    green "  default shell set to $ZSH_PATH"
fi

echo
green "Bootstrap complete."
echo "Start a new zsh session or run: exec zsh"

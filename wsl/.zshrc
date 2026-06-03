export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="awesomepanda"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# fnm
FNM_PATH="/root/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell bash)"
fi

# bun completions
[ -s "/root/.bun/_bun" ] && source "/root/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# source env vars
[ -f "$HOME/.env" ] && source "$HOME/.env"

# opencode
export PATH=/root/.opencode/bin:$PATH

conf() {
    # Detect the shell config file dynamically
    local config_file
    if [ -n "$BASH_VERSION" ]; then
        config_file="$HOME/.bashrc"
    elif [ -n "$ZSH_VERSION" ]; then
        config_file="$HOME/.zshrc"
    else
        config_file="$HOME/.profile"
    fi

    case "$1" in
        edit)
            zed "$config_file"
            ;;
        reload)
            # 'source' and '.' are identical in Bash/Zsh
            . "$config_file"
            echo "🔄 Configuration reloaded!"
            ;;
        *)
            if [ -z "$1" ]; then
                zed "$config_file"
            else
                echo "Usage: conf [edit|reload]"
            fi
            ;;
    esac
}
# pnpm
export PNPM_HOME="/root/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

# quick git add, commit, push
gx() {
    git add .
    git commit -m "x"
    git push
}

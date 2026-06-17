export home=/home/sjce
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

# fnm
FNM_PATH="/home/sjce/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi

# fnm
FNM_PATH="/root/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi

# Zed on WSL fails when cwd is under /root/ (but not /root itself).
zed() {
  local -a args
  args=("$@")
  if [ ${#args[@]} -eq 0 ]; then
    args=("$(pwd)")
  else
    local i
    for i in {1..$#args}; do
      if [ "${args[$i]}" = "." ]; then
        args[$i]="$(pwd)"
      fi
    done
  fi
  (cd ~ && command zed "${args[@]}")
}

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$(go env GOPATH)/bin

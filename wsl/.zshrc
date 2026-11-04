export PATH="$HOME/.local/bin:$PATH"

autoload -Uz compinit && compinit

# oh-my-posh, theme copied from C:\Users\sergi\atomic.omp.json
if command -v oh-my-posh >/dev/null 2>&1; then
   eval "$(oh-my-posh init zsh --config "$HOME/.config/oh-my-posh/atomic.omp.json")"
fi

# ---- ported from the Windows PowerShell profile ----

# gx: add everything, commit, push
gx() {
   if [ $# -eq 0 ]; then
      print -u2 "Usage: gx <commit message>"
      return 1
   fi
   git add . && git commit -m "$*" && git push
}

# killport: the Windows `fuser` helper, renamed so it does not shadow /usr/bin/fuser
killport() {
   local port=$1
   if [ -z "$port" ]; then
      print -u2 "Usage: killport <port>"
      return 1
   fi
   local pids
   pids=$(ss -lptnH "sport = :$port" 2>/dev/null | grep -oP 'pid=\K[0-9]+' | sort -u)
   if [ -z "$pids" ]; then
      print "No process listening on port $port."
      return 0
   fi
   for p in ${(f)pids}; do
      print "Killing $(ps -p $p -o comm= 2>/dev/null) (pid $p) on port $port..."
      kill -9 "$p" 2>/dev/null
   done
   print "Port $port is now free."
}

# bun completions
[ -s "/home/sergio/.bun/_bun" ] && source "/home/sergio/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Report the working directory as a plain file:// URI. oh-my-posh's own
# "pwd": "osc7" escape emits a Windows UNC path inside WSL
# (///wsl.localhost/<distro>/...), which WezTerm feeds back to wsl.exe as
# `--cd`; that path cannot be chdir'd into, so new tabs and splits failed
# with "chdir(...) failed" and started in /.
_wezterm_osc7() { printf '\033]7;file://%s\a' "${PWD// /%20}" }
autoload -Uz add-zsh-hook
add-zsh-hook precmd _wezterm_osc7

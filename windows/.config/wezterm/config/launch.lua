local platform = require('utils.platform')

---@type Config
local options = {
   launch_menu = {},
}

if platform.is_win then
   options.launch_menu = {
      {
         label = 'WSL Ubuntu (root)',
         domain = { DomainName = 'wsl:ubuntu' },
      },
      {
         label = 'PowerShell Desktop',
         domain = { DomainName = 'exec:powershell' },
      },
      {
         label = 'Command Prompt',
         domain = { DomainName = 'exec:cmd' },
      },
      {
         label = 'Git Bash',
         domain = { DomainName = 'exec:git-bash' },
      },
   }
elseif platform.is_mac then
   options.default_prog = { '/opt/homebrew/bin/fish', '-l' }
   options.launch_menu = {
      { label = 'Bash', args = { 'bash', '-l' } },
      { label = 'Fish', args = { '/opt/homebrew/bin/fish', '-l' } },
      { label = 'Nushell', args = { '/opt/homebrew/bin/nu', '-l' } },
      { label = 'Zsh', args = { 'zsh', '-l' } },
   }
elseif platform.is_linux then
   options.default_prog = { 'fish', '-l' }
   options.launch_menu = {
      { label = 'Bash', args = { 'bash', '-l' } },
      { label = 'Fish', args = { 'fish', '-l' } },
      { label = 'Zsh', args = { 'zsh', '-l' } },
   }
end

return options

local wezterm = require('wezterm')
local platform = require('utils.platform')

---@type Config
local options = {
   -- ref: https://wezfurlong.org/wezterm/config/lua/SshDomain.html
   ssh_domains = {},

   -- ref: https://wezfurlong.org/wezterm/multiplexing.html#unix-domains
   unix_domains = {},

   -- ref: https://wezfurlong.org/wezterm/config/lua/WslDomain.html
   wsl_domains = {},

   -- ref: https://wezfurlong.org/wezterm/config/lua/ExecDomain.html
   exec_domains = {},
}

if platform.is_win then
   local userprofile = os.getenv('USERPROFILE') or 'C:\\Users\\sergi'

   local function with_default_args(cmd, defaults)
      if not cmd.args or #cmd.args == 0 then
         cmd.args = defaults
      end
      return cmd
   end

   options.wsl_domains = {
      {
         name = 'wsl:ubuntu',
         distribution = 'Ubuntu',
         username = 'root',
         default_cwd = '/root',
         default_prog = { 'zsh', '-l' },
      },
   }

   options.default_domain = 'wsl:ubuntu'

   options.exec_domains = {
      wezterm.exec_domain('exec:powershell', function(cmd)
         return with_default_args(cmd, { 'powershell.exe', '-NoLogo' })
      end, 'PowerShell'),
      wezterm.exec_domain('exec:cmd', function(cmd)
         return with_default_args(cmd, { 'cmd.exe' })
      end, 'Command Prompt'),
      wezterm.exec_domain('exec:git-bash', function(cmd)
         return with_default_args(cmd, {
            userprofile .. '\\AppData\\Local\\Microsoft\\WindowsApps\\bash.exe',
         })
      end, 'Git Bash'),
   }
end

return options

# dotfiles

Synced configuration for two environments: **Windows 11** and **WSL (Ubuntu, run as root)**.

## Layout

```
.
├── windows/                  # configs for native Windows
│   └── .config/
│       ├── opencode/         # opencode config + plugins
│       └── wezterm/          # wezterm terminal config
├── wsl/                      # configs for WSL/Linux
│   ├── .config/opencode/     # opencode config + plugins
│   ├── .zshrc
│   ├── .bashrc
│   ├── .tmux.conf
│   └── .gitconfig
├── bootstrap.ps1              # Windows: create directory junctions
├── bootstrap-wsl.ps1          # Windows: pick a WSL distro and run bootstrap.sh inside it
├── bootstrap.sh               # WSL: create symlinks + install oh-my-zsh
├── .gitignore
├── LICENSE
└── README.md
```

## What's synced

| Platform | Path in repo | Maps to on disk |
|---|---|---|
| Windows | `windows/.config/opencode/` | `%USERPROFILE%\.config\opencode` (junction) |
| Windows | `windows/.config/wezterm/`  | `%USERPROFILE%\.config\wezterm` (junction) |
| WSL     | `wsl/.zshrc`        | `~/.zshrc` (symlink) |
| WSL     | `wsl/.bashrc`       | `~/.bashrc` (symlink) |
| WSL     | `wsl/.tmux.conf`    | `~/.tmux.conf` (symlink) |
| WSL     | `wsl/.gitconfig`    | `~/.gitconfig` (symlink) |
| WSL     | `wsl/.config/opencode/` | `~/.config/opencode` (symlink) |

`oh-my-zsh` is **not** vendored. The WSL bootstrap installs it from upstream
when missing, which keeps this repo small and always up-to-date.

## Prerequisites

### JetBrains Mono Nerd Font

The wezterm config (`windows/.config/wezterm/config/fonts.lua`) sets the
terminal font to **JetBrainsMono Nerd Font**. Without it, wezterm will fall
back to a default and many Nerd Font glyphs (used by powerline, ls-icons,
nerd-tree, etc.) will render as boxes or `?`.

#### Install on Windows (recommended — scoop)

```powershell
scoop bucket add nerd-fonts
scoop install JetBrainsMono-NF
```

If the font files are present under `~\scoop\apps\JetBrainsMono-NF\current\`
but Windows apps don't see them, scoop's post-install step didn't register
them with `C:\Windows\Fonts`. Re-run it explicitly:

```powershell
scoop install JetBrainsMono-NF --force
```

#### Install on Windows (manual)

Download `JetBrainsMono.zip` from
<https://www.nerdfonts.com/font-downloads>, extract, right-click each
`.ttf` → **Install for all users**.

#### WSL

Wezterm runs on Windows, so the Windows install above is enough. If you
also use GUI Linux apps and want JetBrainsMono Nerd Font there, install
the matching `.ttf` files into `/usr/local/share/fonts/` (or `~/.local/share/fonts/`)
and run `fc-cache -fv`.

## First-time setup

### Windows

From PowerShell, in this repo:

```powershell
.\bootstrap.ps1
```

Optional: pass a different repo path:

```powershell
.\bootstrap.ps1 -DotfilesDir D:\code\dotfiles
```

The script creates Windows **directory junctions** under `%USERPROFILE%\.config`.
Junctions behave like the real directory to every program but don't require
admin rights. Existing real directories at the target are moved to
`<name>.bak-<timestamp>` first.

### WSL

From PowerShell on the Windows host (recommended — picks the right distro):

```powershell
.\bootstrap-wsl.ps1
```

`bootstrap-wsl.ps1` calls `wsl -l -v`, decodes the (UTF-16) output, and
prompts you to pick a distro. The bash bootstrap is then invoked inside
the chosen distro.

The picker always shows (even with a single distro) so you can confirm or
override on any machine. Three ways to answer:

- **Press Enter** — use the WSL default distro (the one marked with `*`).
- **Type a number** — pick one of the listed distros.
- **Type any other text** — use that as a custom distro name (useful if a
  distro isn't in the `wsl -l -v` output, e.g. it was never registered).

Flags:

```powershell
.\bootstrap-wsl.ps1 -Distro Ubuntu        # skip the picker, use 'Ubuntu' explicitly
.\bootstrap-wsl.ps1 -NonInteractive      # use the WSL default, no prompt
```

Inside the bash bootstrap, shell config and `~/.config/opencode` are
symlinked from the repo, and `oh-my-zsh` is installed if it isn't already
present (using `--keep-zshrc` so the just-symlinked `.zshrc` is not
overwritten).

If you ever want to run `bootstrap.sh` directly from inside WSL:

```bash
bash /mnt/c/Users/ivann/dotfiles/bootstrap.sh /mnt/c/Users/ivann/dotfiles
```

## API keys

API keys are **stripped from committed configs** for safety. Before using
opencode, set the keys in the live config files:

- Windows: edit `windows/.config/opencode/opencode.jsonc`
- WSL:     edit `wsl/.config/opencode/opencode.jsonc`

The committed files contain placeholder empty strings with a `// Set your API
key here` comment. If you prefer not to keep keys in this private repo at
all, you can move them to a separate `.env` file (gitignored) and load them
into opencode via a wrapper.

## Adding a new config

1. Move the file/dir into the appropriate platform folder (`windows/` or
   `wsl/`), preserving its path under `.config` or `$HOME`.
2. If the file exists at the target on disk, the bootstrap will move it to
   a `.bak-<timestamp>` sibling the first time it runs.
3. Add the new link to the map at the top of the relevant bootstrap script
   (`bootstrap.ps1` or `bootstrap.sh`) so subsequent bootstraps pick it up.
4. Commit.

## Why junctions on Windows, symlinks on WSL?

- **Junctions** are universally supported on Windows, work across all
  applications, and don't require Developer Mode or admin rights. They only
  work for directories, which matches the Windows config (both targets are
  directories: `opencode` and `wezterm`).
- **Symlinks** on Linux are the natural primitive, work for files and
  directories, and are the default in every Unix tool's mental model.

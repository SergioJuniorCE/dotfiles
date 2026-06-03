<#
.SYNOPSIS
    Bootstrap Windows dotfiles: create directory junctions from $env:USERPROFILE
    into the windows/ folder of this dotfiles repo.

.DESCRIPTION
    For each config under windows/.config, the script creates a Windows directory
    junction at the corresponding path under $env:USERPROFILE. Junctions behave
    like the original directory to all programs but require no admin rights.

    If a real directory already exists at the target, it is moved aside to
    "<name>.bak-<timestamp>" before the junction is created.

.PARAMETER DotfilesDir
    Path to the dotfiles repo. Defaults to $env:USERPROFILE\dotfiles.

.EXAMPLE
    .\bootstrap.ps1
    .\bootstrap.ps1 -DotfilesDir D:\code\dotfiles
#>

param(
    [string]$DotfilesDir = (Join-Path $env:USERPROFILE 'dotfiles')
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "  [ok] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [warn] $msg" -ForegroundColor Yellow }
function Write-Skip($msg) { Write-Host "  [skip] $msg" -ForegroundColor DarkGray }

if (-not (Test-Path -LiteralPath $DotfilesDir)) {
    throw "Dotfiles repo not found at: $DotfilesDir"
}
$windowsDir = Join-Path $DotfilesDir 'windows'
if (-not (Test-Path -LiteralPath $windowsDir)) {
    throw "windows/ folder not found at: $windowsDir"
}

$configRoot = Join-Path $windowsDir '.config'
if (-not (Test-Path -LiteralPath $configRoot)) {
    throw "Expected .config folder at: $configRoot"
}

$userConfig = Join-Path $env:USERPROFILE '.config'
if (-not (Test-Path -LiteralPath $userConfig)) {
    Write-Step "Creating $userConfig"
    New-Item -ItemType Directory -Path $userConfig | Out-Null
}

# Map of source (relative to repo) -> target (relative to $env:USERPROFILE)
$links = @{
    '.config\opencode' = '.config\opencode'
    '.config\wezterm'  = '.config\wezterm'
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

foreach ($entry in $links.GetEnumerator()) {
    $sourceRel = $entry.Key
    $targetRel = $entry.Value

    $source = Join-Path $windowsDir $sourceRel
    $target = Join-Path $env:USERPROFILE $targetRel

    if (-not (Test-Path -LiteralPath $source)) {
        Write-Warn "Source missing, skipping: $source"
        continue
    }

    if (Test-Path -LiteralPath $target) {
        $item = Get-Item -LiteralPath $target -Force
        if ($item.LinkType -eq 'Junction') {
            $existingTarget = (Get-Item -LiteralPath $target -Force).Target
            if ($existingTarget -eq $source) {
                Write-Skip "Already linked: $target -> $source"
                continue
            } else {
                Write-Warn "Junction exists but points elsewhere; removing: $target -> $existingTarget"
                Remove-Item -LiteralPath $target -Force
            }
        } else {
            $backup = "$target.bak-$stamp"
            Write-Warn "Existing real path; backing up to $backup"
            # Mirror to backup then remove source. Robocopy handles read-only
            # files (e.g. the read-only .git/HEAD inside git submodules) that
            # PowerShell's Move-Item refuses to touch.
            & robocopy "$target" "$backup" /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
            if ($LASTEXITCODE -ge 8) {
                throw "robocopy failed backing up $target (exit $LASTEXITCODE)"
            }
            Remove-Item -LiteralPath $target -Recurse -Force
        }
    }

    $targetParent = [System.IO.Path]::GetDirectoryName($target)
    if (-not (Test-Path -LiteralPath $targetParent)) {
        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
    }

    Write-Step "Linking $target -> $source"
    New-Item -ItemType Junction -Path $target -Target $source | Out-Null
    Write-Ok "Linked $target"
}

Write-Host ""
Write-Host "Bootstrap complete." -ForegroundColor Green
Write-Host "Open a new terminal or run 'wezterm' to verify."

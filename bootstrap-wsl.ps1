<#
.SYNOPSIS
    Pick a WSL distro and run the bash bootstrap (bootstrap.sh) inside it.

.DESCRIPTION
    Lists installed WSL distros via 'wsl -l -v', lets the user choose which
    one to bootstrap, and invokes bootstrap.sh inside the chosen distro.

    Defaults to the WSL default distro when only one is installed, or when
    -NonInteractive is passed. With multiple distros and no flag, the user
    is prompted to pick.

    The bash script receives the dotfiles directory (translated to its WSL
    /mnt/c/... path) as its first argument, so it doesn't need to know where
    the repo lives.

.PARAMETER Distro
    Name of the WSL distro to use. Skips the picker.

.PARAMETER NonInteractive
    Use the default distro (marked with * by 'wsl -l -v') without prompting.

.EXAMPLE
    .\bootstrap-wsl.ps1
    .\bootstrap-wsl.ps1 -Distro Ubuntu2404
    .\bootstrap-wsl.ps1 -NonInteractive
#>

[CmdletBinding()]
param(
    [string]$Distro,
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'

# wsl.exe writes UTF-16 LE to stdout. PowerShell reads each pair of bytes as
# two separate chars (high byte at even index, low byte at odd index). Strip
# the high bytes to recover the original text.
function ConvertFrom-WslOutput {
    param([string[]]$Lines)
    foreach ($line in $Lines) {
        if ($null -eq $line) { continue }
        $chars = $line.ToCharArray()
        $sb = New-Object System.Text.StringBuilder
        for ($i = 1; $i -lt $chars.Length; $i += 2) {
            [void]$sb.Append($chars[$i])
        }
        $sb.ToString()
    }
}

# 'C:\foo\bar' -> '/mnt/c/foo/bar'
function ConvertTo-WslPath {
    param([string]$WindowsPath)
    if ($WindowsPath -match '^([A-Za-z]):(.*)$') {
        $drive = $Matches[1].ToLower()
        $rest = $Matches[2] -replace '\\', '/'
        return "/mnt/$drive$rest"
    }
    return $WindowsPath
}

# Locate bootstrap.sh next to this script.
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$bashScript = Join-Path $scriptDir 'bootstrap.sh'
if (-not (Test-Path -LiteralPath $bashScript)) {
    throw "bootstrap.sh not found at: $bashScript"
}

# Get and decode distro list.
$rawLines = & wsl.exe -l -v 2>&1
$lines = @(ConvertFrom-WslOutput -Lines $rawLines)

# First non-empty line is the header. Skip it. Parse the rest.
$distros = @()
$seenHeader = $false
foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if (-not $seenHeader) { $seenHeader = $true; continue }

    $trimmed = $line.TrimStart()
    $isDefault = $false
    if ($trimmed.StartsWith('*')) {
        $isDefault = $true
        $trimmed = $trimmed.Substring(1).TrimStart()
    }

    # Columns separated by 2+ spaces.
    $parts = $trimmed -split '\s{2,}'
    if ($parts.Count -lt 1 -or [string]::IsNullOrWhiteSpace($parts[0])) { continue }

    $distros += [PSCustomObject]@{
        Name    = $parts[0].Trim()
        State   = if ($parts.Count -ge 2) { $parts[1].Trim() } else { 'Unknown' }
        Default = $isDefault
    }
}

if ($distros.Count -eq 0) {
    throw "No WSL distros found. Run 'wsl --list' manually to debug."
}

# Resolve which distro to use.
$chosen = $null

if ($Distro) {
    $chosen = $distros | Where-Object { $_.Name -eq $Distro } | Select-Object -First 1
    if (-not $chosen) {
        $available = ($distros | ForEach-Object { $_.Name }) -join ', '
        throw "Distro '$Distro' not found. Available: $available"
    }
} elseif ($NonInteractive -or $distros.Count -eq 1) {
    $chosen = $distros | Where-Object { $_.Default } | Select-Object -First 1
    if (-not $chosen) { $chosen = $distros[0] }
    $reason = if ($NonInteractive) { '-NonInteractive' } else { 'only one available' }
    Write-Host "==> Auto-selected distro ($reason): $($chosen.Name)" -ForegroundColor Cyan
} else {
    Write-Host "==> Found $($distros.Count) WSL distros:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $distros.Count; $i++) {
        $marker = if ($distros[$i].Default) { ' (default)' } else { '' }
        Write-Host ("    {0}) {1} [{2}]{3}" -f ($i + 1), $distros[$i].Name, $distros[$i].State, $marker)
    }
    Write-Host ''
    $rawChoice = Read-Host "Pick a distro (1-$($distros.Count))"
    if ($rawChoice -notmatch '^\d+$') {
        throw "Invalid choice: $rawChoice"
    }
    $idx = [int]$rawChoice
    if ($idx -lt 1 -or $idx -gt $distros.Count) {
        throw "Invalid choice: $rawChoice (must be 1-$($distros.Count))"
    }
    $chosen = $distros[$idx - 1]
}

Write-Host "==> Using WSL distro: $($chosen.Name) [$($chosen.State)]" -ForegroundColor Green

# Translate paths and run the bash bootstrap inside the chosen distro.
$wslBashScript = ConvertTo-WslPath $bashScript
$wslDotfilesDir = ConvertTo-WslPath $scriptDir

Write-Host "==> Running bootstrap inside WSL..." -ForegroundColor Cyan
Write-Host "    bash script: $wslBashScript" -ForegroundColor DarkGray
Write-Host "    dotfiles:    $wslDotfilesDir" -ForegroundColor DarkGray

& wsl.exe -d $chosen.Name -- bash -c "bash '$wslBashScript' '$wslDotfilesDir'"
exit $LASTEXITCODE

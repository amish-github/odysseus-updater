#Requires -Version 5.1
<#
    Odysseus Updater (Windows)
    Pulls the latest commits for an Odysseus checkout and rebuilds the Docker
    stack only when upstream has actually changed.

    Usage:
      .\update-odysseus.ps1                          # uses the current directory
      .\update-odysseus.ps1 -RepoPath C:\path\to\odysseus
#>
param([string]$RepoPath = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
Set-Location $RepoPath

Write-Host 'Checking for upstream changes...'
git fetch origin main --quiet

$local  = (git rev-parse HEAD).Trim()
$remote = (git rev-parse origin/main).Trim()

if ($local -eq $remote) {
    Write-Host 'Already up to date.'
    exit 0
}

Write-Host "New commits found ($($local.Substring(0,7)) -> $($remote.Substring(0,7))). Pulling..."
git pull --ff-only origin main
if ($LASTEXITCODE -ne 0) { throw 'git pull --ff-only failed (branch diverged). Resolve manually.' }

Write-Host 'Rebuilding and restarting containers...'
docker compose up -d --build
if ($LASTEXITCODE -ne 0) { throw 'docker compose up --build failed.' }

docker image prune -f | Out-Null
Write-Host 'Update complete.'

#Requires -Version 5.1
# ============================================================
#  Odysseus Updater (Windows)
#
#  CONFIG: how often (in HOURS) to check for updates.
#  Default is 24. Change the number below to 12, 6, etc.
#  (Or pass -IntervalHours on the command line.)
# ============================================================
param(
    [int]$IntervalHours = 24,
    [string]$RepoPath = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

function Invoke-Update {
    Set-Location $RepoPath
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm')] Checking for upstream changes..."
    git fetch origin main --quiet

    $local  = (git rev-parse HEAD).Trim()
    $remote = (git rev-parse origin/main).Trim()

    if ($local -eq $remote) {
        Write-Host 'Already up to date.'
        return
    }

    Write-Host "New commits ($($local.Substring(0,7)) -> $($remote.Substring(0,7))). Pulling..."
    git pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) { throw 'git pull --ff-only failed (branch diverged). Resolve manually.' }

    Write-Host 'Rebuilding and restarting containers...'
    docker compose up -d --build
    if ($LASTEXITCODE -ne 0) { throw 'docker compose up --build failed.' }

    docker image prune -f | Out-Null
    Write-Host 'Update complete.'
}

Write-Host "Odysseus Updater running. Checking every $IntervalHours hour(s). Press Ctrl+C to stop."
while ($true) {
    try { Invoke-Update }
    catch { Write-Host "Update run failed: $($_.Exception.Message). Retrying next cycle." }
    Write-Host "Sleeping $IntervalHours hour(s)..."
    Start-Sleep -Seconds ($IntervalHours * 3600)
}

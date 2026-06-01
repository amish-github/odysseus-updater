#Requires -Version 5.1
# ============================================================
#  RUN THIS FIRST (as Administrator).
#
#  One-time installer. Registers a Windows scheduled task that
#  starts update-odysseus.ps1 in the background at every logon,
#  so updates keep happening without an open window.
#
#  The check interval lives in update-odysseus.ps1 (default 24h);
#  override it here with -IntervalHours.
#
#  Usage (Administrator PowerShell):
#    .\setup-task.ps1 -RepoPath C:\path\to\odysseus
#    .\setup-task.ps1 -RepoPath C:\path\to\odysseus -IntervalHours 12
#
#  Remove later:
#    Unregister-ScheduledTask -TaskName 'Odysseus Auto-Update' -Confirm:$false
# ============================================================
param(
    [Parameter(Mandatory)][string]$RepoPath,
    [int]$IntervalHours = 24
)

$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'Run this from an Administrator PowerShell window.' }

$worker = Join-Path $PSScriptRoot 'update-odysseus.ps1'
if (-not (Test-Path $worker)) { throw "Worker script not found: $worker" }

$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-NoProfile -WindowStyle Hidden -File `"$worker`" -RepoPath `"$RepoPath`" -IntervalHours $IntervalHours"

$trigger  = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit ([TimeSpan]::Zero)

Register-ScheduledTask -TaskName 'Odysseus Auto-Update' `
    -Action $action -Trigger $trigger -Settings $settings `
    -User "$env:USERDOMAIN\$env:USERNAME" -RunLevel Highest `
    -Description 'Keeps the Odysseus Docker stack updated from origin/main.' `
    -Force | Out-Null

Write-Host "Registered 'Odysseus Auto-Update'. It starts at logon and checks every $IntervalHours hour(s)."
Write-Host "To start it right now without logging out, run:"
Write-Host "  .\update-odysseus.ps1 -RepoPath `"$RepoPath`" -IntervalHours $IntervalHours"

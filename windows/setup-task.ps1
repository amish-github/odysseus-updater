#Requires -Version 5.1
<#
    One-time installer (run as Administrator).
    Registers a Windows scheduled task that runs update-odysseus.ps1 every hour
    and at logon, so the Odysseus checkout stays current automatically.

    Usage (Administrator PowerShell):
      .\setup-task.ps1 -RepoPath C:\path\to\odysseus

    Remove later:
      Unregister-ScheduledTask -TaskName 'Odysseus Auto-Update' -Confirm:$false
#>
param([Parameter(Mandatory)][string]$RepoPath)

$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { throw 'Run this from an Administrator PowerShell window.' }

$worker = Join-Path $PSScriptRoot 'update-odysseus.ps1'
if (-not (Test-Path $worker)) { throw "Worker script not found: $worker" }

$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-NoProfile -WindowStyle Hidden -File `"$worker`" -RepoPath `"$RepoPath`""

$triggerLogon  = New-ScheduledTaskTrigger -AtLogOn
$triggerHourly = New-ScheduledTaskTrigger -Once -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Hours 1)

$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1)

Register-ScheduledTask -TaskName 'Odysseus Auto-Update' `
    -Action $action -Trigger $triggerLogon, $triggerHourly `
    -Settings $settings `
    -User "$env:USERDOMAIN\$env:USERNAME" -RunLevel Highest `
    -Description 'Pulls origin/main and rebuilds the Odysseus Docker stack when upstream changes.' `
    -Force | Out-Null

Write-Host "Registered scheduled task 'Odysseus Auto-Update' (hourly + at logon)."

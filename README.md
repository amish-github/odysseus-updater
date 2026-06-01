# Odysseus Updater

Small cross-platform scripts that keep a local [Odysseus](https://github.com/pewdiepie-archdaemon/odysseus)
checkout current. Each script runs in a loop: every N hours it pulls the latest
`origin/main` and rebuilds the Docker stack — but **only when there are actually
new commits**, so idle checks finish instantly.

Pick the folder for your OS: [`windows/`](windows), [`mac/`](mac), [`linux/`](linux).

## Set the interval

At the **top of each script** there's a setting for how often (in hours) to check.
Default is **24**. Change it to whatever you want (e.g. `12`, `6`):

- Windows: `[int]$IntervalHours = 24`
- macOS / Linux: `INTERVAL_HOURS=24`

## Windows

Run the two scripts in numbered order.

**Step 1 — `1-setup-task.ps1`** (run as Administrator). Installs a background
task that auto-starts the updater at every logon:

```powershell
# Open PowerShell as Administrator, then:
.\windows\1-setup-task.ps1 -RepoPath C:\path\to\odysseus
```

**Step 2 — `2-update-odysseus.ps1`** is the worker the task runs. You don't have
to run it by hand, but you can start it immediately (without logging out):

```powershell
.\windows\2-update-odysseus.ps1 -RepoPath C:\path\to\odysseus
```

Remove the background task later:

```powershell
Unregister-ScheduledTask -TaskName 'Odysseus Auto-Update' -Confirm:$false
```

## macOS / Linux

```bash
chmod +x update-odysseus.sh
./update-odysseus.sh /path/to/odysseus
```

It keeps running and checks on the interval set at the top of the file. To keep
it alive after you close the terminal, run it in the background:

```bash
nohup ./update-odysseus.sh /path/to/odysseus >/dev/null 2>&1 &
```

## Requirements

- git
- Docker + Docker Compose v2 (`docker compose`)
- An Odysseus repo already cloned locally

## Notes

- Uses `--ff-only`: if your branch has diverged from upstream the script logs it
  and retries next cycle instead of forcing anything. Resolve by hand, then it
  picks back up.
- The rebuild needs the Docker daemon running when the script fires.

## License

MIT

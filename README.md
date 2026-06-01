# Odysseus Updater

Small cross-platform scripts that keep a local [Odysseus](https://github.com/pewdiepie-archdaemon/odysseus)
checkout current. They pull the latest `origin/main` and rebuild the Docker
stack — but **only when there are actually new commits**, so idle runs finish
instantly.

Pick the folder for your OS: [`windows/`](windows), [`mac/`](mac), [`linux/`](linux).

## What it does

1. `git fetch` and compare local `main` against `origin/main`.
2. If nothing changed, exit immediately.
3. Otherwise `git pull --ff-only` (never clobbers local work), then
   `docker compose up -d --build`, then prune old images.

## Windows

```powershell
# one-off
.\windows\update-odysseus.ps1 -RepoPath C:\path\to\odysseus
```

Run it automatically (hourly + at logon) from an **Administrator** PowerShell:

```powershell
.\windows\setup-task.ps1 -RepoPath C:\path\to\odysseus
```

Remove the schedule later:

```powershell
Unregister-ScheduledTask -TaskName 'Odysseus Auto-Update' -Confirm:$false
```

## macOS / Linux

```bash
chmod +x update-odysseus.sh
./update-odysseus.sh /path/to/odysseus
```

Run it automatically with cron — `crontab -e`, then add an hourly entry:

```
0 * * * * /path/to/odysseus-updater/linux/update-odysseus.sh /path/to/odysseus >/dev/null 2>&1
```

## Requirements

- git
- Docker + Docker Compose v2 (`docker compose`)
- An Odysseus repo already cloned locally

## Notes

- Uses `--ff-only`: if your branch has diverged from upstream the script stops
  rather than forcing anything. Resolve by hand, then re-run.
- The rebuild needs the Docker daemon running when the script fires.

## License

MIT

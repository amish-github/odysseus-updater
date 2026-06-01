#!/usr/bin/env bash
# ============================================================
#  Odysseus Updater (macOS)
#
#  CONFIG: how often (in HOURS) to check for updates.
#  Default is 24. Change the number below to 12, 6, etc.
# ============================================================
INTERVAL_HOURS=24
# ============================================================

set -uo pipefail
REPO="${1:-$(pwd)}"

run_update() {
    cd "$REPO" || { echo "Cannot cd to $REPO"; return 1; }
    echo "[$(date '+%Y-%m-%d %H:%M')] Checking for upstream changes..."
    git fetch origin main --quiet || { echo "git fetch failed"; return 1; }

    local_rev="$(git rev-parse HEAD)"
    remote_rev="$(git rev-parse origin/main)"

    if [ "$local_rev" = "$remote_rev" ]; then
        echo "Already up to date."
        return 0
    fi

    echo "New commits (${local_rev:0:7} -> ${remote_rev:0:7}). Pulling..."
    git pull --ff-only origin main || { echo "git pull --ff-only failed (branch diverged). Resolve manually."; return 1; }

    echo "Rebuilding and restarting containers..."
    docker compose up -d --build || { echo "docker compose up --build failed"; return 1; }

    docker image prune -f >/dev/null
    echo "Update complete."
}

echo "Odysseus Updater running. Checking every ${INTERVAL_HOURS}h. Press Ctrl+C to stop."
while true; do
    run_update || echo "Update run failed; retrying next cycle."
    echo "Sleeping ${INTERVAL_HOURS}h..."
    sleep "$(( INTERVAL_HOURS * 3600 ))"
done

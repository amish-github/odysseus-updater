#!/usr/bin/env bash
# Odysseus Updater (macOS)
# Pulls the latest commits for an Odysseus checkout and rebuilds the Docker
# stack only when upstream has actually changed.
#
# Usage:
#   ./update-odysseus.sh                  # uses the current directory
#   ./update-odysseus.sh /path/to/odysseus
set -euo pipefail

REPO="${1:-$(pwd)}"
cd "$REPO"

echo "Checking for upstream changes..."
git fetch origin main --quiet

local_rev="$(git rev-parse HEAD)"
remote_rev="$(git rev-parse origin/main)"

if [ "$local_rev" = "$remote_rev" ]; then
    echo "Already up to date."
    exit 0
fi

echo "New commits found (${local_rev:0:7} -> ${remote_rev:0:7}). Pulling..."
git pull --ff-only origin main

echo "Rebuilding and restarting containers..."
docker compose up -d --build

docker image prune -f >/dev/null
echo "Update complete."

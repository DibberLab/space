#!/usr/bin/env bash
# Server-side deploy for space.dibberlab.me.
#
# GitHub Actions runs this over SSH after every push to main. The deploy key in
# /root/.ssh/authorized_keys is locked to this one script.
#
# Install (once, on the droplet):
#   install -m 755 /var/www/space/deploy/space-deploy.sh /usr/local/bin/space-deploy
#
# The installed copy lives outside the repo on purpose: a push to main can't
# change what root runs here. Re-run the install line if you edit this file.
set -euo pipefail

APP_DIR=/var/www/space
cd "$APP_DIR"

before=$(git rev-parse HEAD)
git pull --ff-only origin main
after=$(git rev-parse HEAD)
echo ">>> $before -> $after"

if ! git diff --quiet "$before" "$after" -- deploy/space.nginx.conf; then
    echo "!!! deploy/space.nginx.conf changed. Install it by hand (nginx -t first)."
fi
if ! git diff --quiet "$before" "$after" -- scripts/update-tle.sh deploy/space-tle.cron; then
    echo "!!! orbit refresh changed. Re-run step 6b of deploy/setup-from-mac.sh."
fi

# Check nginx serves the page locally, bypassing Cloudflare.
code=$(curl -sk -o /dev/null -w '%{http_code}' \
    --resolve space.dibberlab.me:443:127.0.0.1 \
    https://space.dibberlab.me/ || true)
if [ "$code" = "200" ]; then
    echo ">>> space is up (HTTP $code) at $(git log -1 --format='%h %s')"
    exit 0
fi
echo "!!! space answered HTTP ${code:-none} locally"
exit 1

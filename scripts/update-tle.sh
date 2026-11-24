#!/usr/bin/env bash
# Refresh satellite orbits (TLEs) from CelesTrak.
#   scripts/update-tle.sh            -> writes site/data/visual.tle (local use)
#   space-update-tle /path/file.tle  -> writes that file (the droplet's cron)
# CelesTrak asks that the same data not be downloaded more than once every 2 hours.
set -euo pipefail
if [ $# -ge 1 ]; then out="$1"; else cd "$(dirname "$0")/.."; out="site/data/visual.tle"; fi
tmp="$(mktemp "$(dirname "$out")/.visual.tle.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
curl -fsSL --retry 3 --max-time 60 -A "siren-night-sky (https://space.dibberlab.me)" \
  "https://celestrak.org/NORAD/elements/gp.php?GROUP=visual&FORMAT=tle" -o "$tmp"
count="$(grep -c '^1 ' "$tmp" || true)"
if [ "${count:-0}" -lt 50 ]; then
  echo "Download had only ${count:-0} satellites; keeping the existing $out" >&2
  exit 1
fi
chmod 644 "$tmp"
mv "$tmp" "$out"
trap - EXIT
echo "Saved $count satellites to $out"

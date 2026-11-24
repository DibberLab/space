# Siren Night Sky (space.dibberlab.me)

An interactive night-sky explorer for Siren, Wisconsin. It's a **static site with no build step**: everything lives in `site/`. Live at **https://space.dibberlab.me**.

## Layout

```
site/                       the entire website (nginx's web root)
  index.html                the whole app: HTML, CSS, JS, star/deep-sky catalogs, inlined satellite.js
  data/visual.tle           fallback satellite orbits (TLEs) from CelesTrak, fetched by the page at load
  favicon.svg
scripts/update-tle.sh       refreshes orbits from CelesTrak (no arg: site/data/visual.tle; or a path)
deploy/space.nginx.conf     nginx site
deploy/space-deploy.sh      server-side deploy (installed as /usr/local/bin/space-deploy)
deploy/space-tle.cron       orbit refresh every 8 hours (installed as /etc/cron.d/space-tle)
deploy/setup-from-mac.sh    one-time server setup, run on Andrew's Mac
.github/workflows/deploy.yml  push to main -> SSH -> space-deploy
THIRD_PARTY.md
```

## How it works (things not to break)

- No bundler, no npm install. Don't add a build step unless asked.
- The page needs only Google Fonts from outside. It reads `data/visual.tle` by a **relative path**, so `site/` must stay the web root.
- Observer location and time zone are constants at the top of the main script in `index.html` (`LAT`, `LON`, `TZ`).
- Orbits go stale after 1–2 weeks. On the droplet, cron runs `space-update-tle` as www-data every 8 hours, writing `/var/lib/space/data/visual.tle` (outside the checkout, so `git pull` never conflicts). nginx serves that file at `/data/visual.tle`, falling back to the repo's `site/data/visual.tle`. If both are stale the page falls back to orbits embedded in `index.html` (Nov 23, 2026).
- CelesTrak policy: don't download the same group more than every 2 hours.

## Hosting

Same pattern as maps.dibberlab.me: DigitalOcean droplet (ssh alias `dibberlab-droplet`), nginx, behind Cloudflare (proxied; `*.dibberlab.me` wildcard DNS and origin cert). Checkout at `/var/www/space`.

## Working rules

- **Pushing to `main` deploys to production** (GitHub Actions -> `/usr/local/bin/space-deploy`, which pulls `main` and checks nginx serves the page).
- Work on a branch. Test locally (below), then **ask Andrew whether to deploy**. Only on a yes, fast-forward `main` and push, then check the Deploy run passed.
- nginx config, `space-deploy.sh`, `update-tle.sh` and the cron file are NOT applied by a deploy. Re-run the matching step of `deploy/setup-from-mac.sh` (it's safe to re-run all of it). The deploy log warns when they changed.
- Andrew isn't a developer; give him exact commands to paste when something must run on his Mac.
- Cloudflare caches static files. If a deploy doesn't show up, purge the cache for space.dibberlab.me.

## Test locally

```bash
python3 -m http.server 8080 -d site
```
Open http://localhost:8080 and check: the sky draws, search works (try "m31", "iss"), no console errors, and the side panel's "Satellite orbits: from <date>" matches `data/visual.tle`.

## After deploying, verify

- https://space.dibberlab.me loads with no console errors.
- https://space.dibberlab.me/data/visual.tle is plain text starting with a satellite name and `1 ` / `2 ` lines.
- The side panel's "Satellite orbits: from …" date is today or yesterday.
- Searching "iss" finds the International Space Station; tapping it shows height/speed and its next pass.

# Siren Night Sky (space.dibberlab.me)

An interactive night-sky explorer for Siren, Wisconsin. It's a **static site with no build step**: everything lives in `site/`. Live at **https://space.dibberlab.me**. Site name on the droplet: `space`.

## Layout

```
site/                         the entire website (nginx's web root)
  index.html                  the whole app: HTML, CSS, JS, star/deep-sky catalogs, inlined satellite.js
  data/visual.tle             fallback satellite orbits (TLEs); production serves a fresher copy (see below)
  favicon.svg, apple-touch-icon.png, icon-192.png, icon-512.png, manifest.webmanifest
                              "Add to Home Screen" app support
scripts/update-tle.sh         refreshes orbits from CelesTrak (no arg: site/data/visual.tle; or a target path)
scripts/build-from-artifact.py  regenerates site/index.html from the single-file claude.ai artifact version,
                              if Andrew hands you a newer one
deploy/space.nginx.conf       nginx site
deploy/space-tle.cron         orbit refresh every 8 hours (installed as /etc/cron.d/space-tle)
deploy/space-deploy.sh        server-side deploy (installed as /usr/local/bin/space-deploy)
deploy/setup-from-mac.sh      one-time server setup, run on Andrew's Mac
.github/workflows/deploy.yml  push to main -> SSH -> space-deploy
THIRD_PARTY.md
```

## How it works (things not to break)

- No bundler, no npm install. Don't add a build step unless asked.
- The page needs only Google Fonts from outside. It reads `data/visual.tle` by a **relative path**, so `site/` must stay the web root.
- Orbits go stale after 1–2 weeks. On the droplet, cron runs `/usr/local/bin/space-update-tle` as www-data every 8 hours, writing `/var/lib/space/data/visual.tle` (outside the checkout, so `git pull` never conflicts). nginx serves that file at `/data/visual.tle` and falls back to the repo's `site/data/visual.tle`. If both are stale the page falls back to orbits embedded in `index.html` (Nov 23, 2026).
- CelesTrak policy: don't download the same group more than every 2 hours.
- Mobile-first: on phones the sky fills the screen with a bottom sheet. **Sky mode** (point the phone at the sky) uses the device-orientation API, which needs HTTPS; iOS asks for motion permission when the button is tapped. Test it on a real phone after deploying.
- Observer location and time zone are constants at the top of the main script in `index.html` (`LAT`, `LON`, `TZ`).

## Hosting

DibberLab droplet (ssh alias `dibberlab-droplet`, reachable only from Andrew's Mac), nginx behind Cloudflare (proxied; `*.dibberlab.me` wildcard DNS and origin cert). Checkout at `/var/www/space`. Not GitHub Pages: don't enable Pages or touch DNS.

Deploys and DibberLab-wide rules: see `amcmorrow/dibberlab-infra` (its `CLAUDE.md` and `README.md`). This repo still uses its own deploy kit (`space-deploy.sh`, `setup-from-mac.sh`); dibberlab-infra's `docs/migrating.md` moves it to the shared `dibberlab-deploy`. After that migration, delete those two files and update this section.

## Working rules

- **Merging to `main` deploys to production** (about 15 s).
- Work on a branch and open a PR against `main`; never push straight to `main`. Andrew merges.
- nginx config, `space-deploy.sh`, `update-tle.sh` and the cron file are NOT applied by a deploy. They reach the droplet only from Andrew's Mac (re-run `deploy/setup-from-mac.sh`, which is safe to re-run; `nginx -t` gates the reload). The deploy log warns when they changed. Never run anything against the server from a chat.
- Andrew isn't a developer; give him exact commands to paste when something must run on his Mac.
- Cloudflare caches static files. If a deploy doesn't show up, purge the cache for space.dibberlab.me.

## Test locally

```bash
python3 -m http.server 8080 -d site
```
Open http://localhost:8080 at desktop and phone (390px) widths and check: the sky draws, search works (try "m31", "iss"), no console errors, and the side panel's "Satellite orbits: from <date>" matches `data/visual.tle`.

## After deploying, verify

- https://space.dibberlab.me loads with no console errors.
- https://space.dibberlab.me/data/visual.tle is plain text starting with a satellite name and `1 ` / `2 ` lines, and its date is within the last 8 hours or so.
- https://space.dibberlab.me/manifest.webmanifest returns 200 as `application/manifest+json`.
- The side panel's "Satellite orbits: from …" date is today or yesterday.
- On a phone, the bottom sheet opens and closes, the red-light button works, Sky mode follows the phone, and Add to Home Screen shows the moon icon.
- Searching "iss" finds the International Space Station; tapping it shows height/speed and its next pass.

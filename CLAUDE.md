# Siren Night Sky — deployment guide for Claude Code

An interactive night-sky explorer for Siren, Wisconsin. It's a **static site with no build step**: everything lives in `site/`. The goal is to serve it at **https://space.dibberlab.me**.

## Layout

```
site/                  ← the entire website (publish this folder, nothing else)
  index.html           ← the whole app: HTML, CSS, JS, star/deep-sky catalogs, inlined satellite.js
  data/visual.tle      ← satellite orbits (TLEs) from CelesTrak, fetched by the page at load
  favicon.svg, apple-touch-icon.png, icon-192.png, icon-512.png, manifest.webmanifest  ← "Add to Home Screen" app support
  CNAME                ← "space.dibberlab.me" (used by GitHub Pages)
scripts/update-tle.sh  ← refreshes site/data/visual.tle from CelesTrak
scripts/build-from-artifact.py ← regenerates site/index.html from the single-file claude.ai artifact version, if the user hands you a newer one
.github/workflows/deploy.yml ← GitHub Pages deploy + refresh orbits every 8 hours
THIRD_PARTY.md
```

## How it works (things not to break)

- No bundler, no npm install. Don't add a build step unless the user asks.
- The page needs only Google Fonts from outside. It reads `data/visual.tle` by a **relative path**, so `site/` must be served as the web root (or the path kept relative).
- Satellite orbits go stale after about 1–2 weeks. Production must re-run `scripts/update-tle.sh` regularly: the GitHub workflow does this every 8 hours. Any other host needs a cron job or a scheduled CI job. If the fetch fails, the page falls back to the orbits embedded in `index.html` (dated Nov 23, 2026).
- CelesTrak policy: don't download the same group more often than every 2 hours. Every 8 hours is fine.
- The page is built mobile-first: on phones the sky fills the screen with a bottom sheet. **Sky mode** (point the phone at the sky) uses the device-orientation API, which needs HTTPS. iOS asks for motion permission when the button is tapped. Test it on a real phone after deploying.
- Observer location and time zone are constants at the top of the main script in `index.html` (`LAT`, `LON`, `TZ`).

## Test locally first

```bash
python3 -m http.server 8080 -d site
# open http://localhost:8080 — check: sky draws, search works (try "m31", "iss"),
# the browser console has no errors, and the side panel's "Satellite orbits: from <date>" shows the date in data/visual.tle
```

## Deploy

**First, ask the user where dibberlab.me is hosted, and who manages its DNS**, unless the repo or environment already makes this obvious, e.g. an existing GitHub Pages, Cloudflare, Netlify or Vercel setup, or a VPS. Then follow the matching option. Option A is the default if they have no preference.

### Option A — GitHub Pages (recommended; the workflow is already written)

1. Create a repo and push. For example: `git init && git add -A && git commit -m "Siren Night Sky"`, then `gh repo create <owner>/siren-night-sky --public --source . --push`. Pages on a private repo needs a paid plan.
2. Enable Pages with GitHub Actions as the source:
   `gh api -X POST repos/<owner>/siren-night-sky/pages -f build_type=workflow`
   (If it already exists: `gh api -X PUT repos/<owner>/siren-night-sky/pages -f build_type=workflow`.)
3. Run the workflow: `gh workflow run deploy.yml`, then `gh run watch`.
4. Set the custom domain: `gh api -X PUT repos/<owner>/siren-night-sky/pages -f cname=space.dibberlab.me`
5. **DNS** (at whoever hosts dibberlab.me): add `CNAME  space  →  <owner>.github.io` (owner lowercase, no repo name). If DNS is on Cloudflare, set that record to **DNS only** (grey cloud) until GitHub issues the certificate.
6. When DNS resolves (`dig +short space.dibberlab.me`), turn on HTTPS:
   `gh api -X PUT repos/<owner>/siren-night-sky/pages -F https_enforced=true` (retry later if the certificate isn't ready).
7. Optional but recommended: verify `dibberlab.me` in the user's GitHub account settings, under Pages → verified domains, to prevent domain takeover.

### Option B — Cloudflare Pages / Netlify / Vercel

- No build command. Output/publish directory: `site`.
- Attach the custom domain `space.dibberlab.me` in that host's dashboard or CLI and add the DNS record it asks for.
- Orbit refresh: keep `.github/workflows/deploy.yml` but change it so it **commits** the refreshed `site/data/visual.tle` back to `main` (needs `contents: write`), which triggers the host's git deploy. Or use the host's own scheduled builds or deploy hooks to run `scripts/update-tle.sh` before publishing. Remove the Pages-specific steps if GitHub Pages isn't used.

### Option C — Own server (nginx/Caddy)

- Copy `site/` to the server, for example `/var/www/space.dibberlab.me`. Serve it as the document root over HTTPS (Caddy does certificates automatically; with nginx use certbot).
- Point DNS `A`/`AAAA` (or `CNAME`) for `space` at the server.
- Cron for orbits, e.g. `17 */8 * * * /path/to/repo/scripts/update-tle.sh && rsync -a /path/to/repo/site/data/ /var/www/space.dibberlab.me/data/`.
- Serve `.tle` files as `text/plain` and don't cache `data/` for long (`Cache-Control: max-age=600` is fine).

## After deploying, verify

- https://space.dibberlab.me loads over HTTPS with no console errors.
- `https://space.dibberlab.me/data/visual.tle` returns plain text starting with a satellite name and `1 ` / `2 ` lines.
- The side panel's "Satellite orbits: from …" date is today or yesterday.
- On a phone, the bottom sheet opens and closes, the red-light button works, Sky mode follows the phone, and Add to Home Screen shows the moon icon.
- Searching "iss" returns the International Space Station. Tapping it shows height/speed and its next pass.

## Things to confirm with the user rather than assume

- Which GitHub account or org should own the repo, and whether it should be public.
- Where dibberlab.me's DNS is managed. Never change existing records for other subdomains.

# space

Live at **https://space.dibberlab.me**. Static site: nginx serves `site/`
straight from a checkout at `/var/www/space` on the droplet, behind Cloudflare.

## Deploys

Every push to `main` deploys (`.github/workflows/deploy.yml` SSHes into the
droplet with a key locked to `/usr/local/bin/space-deploy`, which pulls `main`
and checks nginx serves the page). Redeploy by hand: GitHub → Actions → Deploy
→ Run workflow.

## One-time setup

On the Mac, from a clone of this repo: `bash deploy/setup-from-mac.sh`.
It clones to the droplet, links the `*.dibberlab.me` origin cert, installs the
nginx site, installs the deploy script and key, sets the repo secrets, and runs
a test deploy. Safe to re-run.

## Notes

- nginx config changes aren't auto-deployed: copy `deploy/space.nginx.conf` in
  and run `nginx -t` by hand.
- If you edit `deploy/space-deploy.sh`, re-run its `install` line (step 6).
- Cloudflare caches static files; purge the cache if a deploy doesn't show.

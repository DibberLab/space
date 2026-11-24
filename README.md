# Sedna

An interactive night sky for wherever you are. It opens on your own location (if your browser shares it; otherwise Siren, Wisconsin), and you can type any city and state or GPS coordinates to see the sky from there. Pick any date and time to see the stars, constellations, planets, the Moon, deep-sky objects and live satellites. You can search for anything in the catalog, and the Tonight panel lists planet viewing times and space-station passes.

Live at **https://space.dibberlab.me**.

- Static site, no build step: everything is in `site/`.
- Run locally: `python3 -m http.server 8080 -d site`, then open http://localhost:8080
- Pushing to `main` deploys to the droplet. Satellite orbits refresh on the droplet every 8 hours.

Deployment details are in `CLAUDE.md`. Credits are in `THIRD_PARTY.md`.

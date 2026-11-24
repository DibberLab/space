#!/usr/bin/env bash
# One-time setup for space.dibberlab.me. Run on Andrew's Mac (the only place
# with the droplet SSH key), from a clone of DibberLab/space:
#
#   bash deploy/setup-from-mac.sh
#
# Safe to re-run: every step checks before it changes anything.
# Needs: ssh alias dibberlab-droplet, gh logged in with admin on DibberLab/space.
set -euo pipefail

R=DibberLab/space
NAME=space.dibberlab.me
CERT=/etc/ssl/cloudflare/$NAME
H=$(ssh -G dibberlab-droplet | awk '/^hostname /{print $2}')   # never hard-code the IP: the site sits behind Cloudflare
KEY=~/.ssh/space-gh-deploy
d() { ssh dibberlab-droplet "$@"; }

echo "== 1. connection"
d 'hostname && uptime'

echo "== 2. checkout at /var/www/space"
d "test -d /var/www/space/.git || git clone https://github.com/$R.git /var/www/space"
d 'cd /var/www/space && git pull --ff-only origin main && git log -1 --oneline'

echo "== 3. origin certificate for $NAME"
d "set -e
   covers() { openssl x509 -in \"\$1\" -noout -ext subjectAltName 2>/dev/null | grep -Eq 'DNS:(\*\.dibberlab\.me|space\.dibberlab\.me)'; }
   if [ -f $CERT.pem ] && covers $CERT.pem; then echo 'cert ok'; exit 0; fi
   for pem in /etc/ssl/cloudflare/*.pem; do
     [ -f \"\$pem\" ] && [ -f \"\${pem%.pem}.key\" ] && covers \"\$pem\" || continue
     ln -sfn \"\$pem\" $CERT.pem; ln -sfn \"\${pem%.pem}.key\" $CERT.key
     echo \"linked \$pem (covers *.dibberlab.me)\"; exit 0
   done
   echo '!!! No cert covers $NAME.'
   echo '    Cloudflare > dibberlab.me > SSL/TLS > Origin Server > Create Certificate'
   echo '    for space.dibberlab.me (or *.dibberlab.me), then save it on the droplet as'
   echo '    $CERT.pem and $CERT.key (chmod 600 the key), and re-run this script.'
   exit 1"

echo "== 4. nginx site (nginx -t gates the reload; a bad config is rolled back)"
d 'set -e
   cp /var/www/space/deploy/space.nginx.conf /etc/nginx/sites-available/space
   ln -sfn /etc/nginx/sites-available/space /etc/nginx/sites-enabled/space
   if nginx -t; then systemctl reload nginx
   else rm -f /etc/nginx/sites-enabled/space; echo "nginx -t failed; site disabled again"; exit 1; fi'

echo "== 5. commit /etc/nginx (files staged by name)"
d "cd /etc/nginx && git add sites-available/space sites-enabled/space &&
   { git diff --cached --quiet || git commit -m 'add $NAME'; } && git push origin main"

echo "== 6. install the deploy script outside the repo"
d 'install -m 755 /var/www/space/deploy/space-deploy.sh /usr/local/bin/space-deploy && /usr/local/bin/space-deploy'

echo "== 6b. satellite-orbit refresh (cron, every 8 hours)"
d 'set -e
   install -d -o www-data -g www-data -m 755 /var/lib/space /var/lib/space/data
   install -m 755 /var/www/space/scripts/update-tle.sh /usr/local/bin/space-update-tle
   install -m 644 /var/www/space/deploy/space-tle.cron /etc/cron.d/space-tle
   sudo -u www-data /usr/local/bin/space-update-tle /var/lib/space/data/visual.tle || echo "CelesTrak fetch failed; the repo copy is served until the cron succeeds"'

echo "== 7. GitHub deploy key, locked to that script"
[ -f "$KEY" ] || ssh-keygen -t ed25519 -N "" -C "github-actions-space-deploy" -f "$KEY"
PUB=$(cat "$KEY.pub")
d "grep -qF '$PUB' /root/.ssh/authorized_keys || echo 'command=\"/usr/local/bin/space-deploy\",no-port-forwarding,no-agent-forwarding,no-X11-forwarding,no-pty $PUB' >> /root/.ssh/authorized_keys"

echo "== 8. repository secrets"
gh secret set DEPLOY_HOST -R "$R" -b "$H"
gh secret set DEPLOY_SSH_KEY -R "$R" < "$KEY"
ssh-keyscan -t ed25519 "$H" 2>/dev/null | gh secret set DEPLOY_KNOWN_HOSTS -R "$R"

echo "== 9. test run"
gh workflow run Deploy -R "$R"
sleep 5
gh run watch -R "$R" "$(gh run list -R "$R" -w Deploy -L 1 --json databaseId -q '.[0].databaseId')" --exit-status

echo "== 10. public check through Cloudflare"
code=$(curl -s -o /dev/null -w '%{http_code}' "https://$NAME/" || true)
if [ "$code" = "200" ]; then
    echo "https://$NAME is live."
else
    echo "!!! https://$NAME answered HTTP ${code:-none} from outside."
    echo "    No DNS answer: add a proxied A record 'space' -> $H in Cloudflare (dibberlab.me)."
    echo "    526: Cloudflare doesn't trust the origin cert; recheck step 3."
fi
echo "GitHub has its copy of the key; you can now: rm $KEY"

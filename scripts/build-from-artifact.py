#!/usr/bin/env python3
"""OUT OF DATE: site/index.html has since been renamed to Sedna and given a location picker.
Running this would undo both. Kept for reference only.

Turn the single-file artifact version (siren-sky.html) into site/index.html for hosting.

Adds site metadata, the web-app manifest/icons, and loading fresh orbits from data/visual.tle.
Usage: python3 scripts/build-from-artifact.py path/to/siren-sky.html
"""
import sys, pathlib
src = pathlib.Path(sys.argv[1]).read_text()
def rep(s, a, b):
    assert s.count(a) == 1, f"expected exactly one match for: {a[:70]}"
    return s.replace(a, b)
s = rep(src, '<title>Siren Night Sky</title>', '''<title>Siren Night Sky</title>
<meta name="description" content="An interactive night sky for Siren, Wisconsin: stars, planets, the Moon, deep-sky objects and live satellites for any date and time.">
<meta property="og:title" content="Siren Night Sky">
<meta property="og:description" content="Explore the sky over Siren, Wisconsin for any night, with live satellites.">
<meta property="og:url" content="https://space.dibberlab.me/">
<meta property="og:type" content="website">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="apple-mobile-web-app-title" content="Siren Sky">
<link rel="icon" href="favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="apple-touch-icon.png">
<link rel="manifest" href="manifest.webmanifest">''')
s = rep(s, "syncTime();markViews();requestAnimationFrame(loop);", """syncTime();markViews();requestAnimationFrame(loop);
// Fresh orbits published next to the page (refreshed by scripts/update-tle.sh / the deploy workflow)
fetch('data/visual.tle',{cache:'no-cache'}).then(r=>r.ok?r.text():Promise.reject(r.status)).then(txt=>{
  const l=parseTLE(txt);if(!l.length)return;
  const ep=l.reduce((m,s)=>Math.max(m,s.epoch),0);if(ep<SATEPOCH)return;
  setSats(l);addSatIdx();renderNight();infoKey=null;need=true;
}).catch(()=>{});""")
s = rep(s, "<p>Satellite orbits drift, so predictions get less accurate after a week or two. To refresh them,",
        "<p>Orbits refresh automatically on this site several times a day. If the date above looks old, you can paste fresh ones yourself:")
out = pathlib.Path(__file__).resolve().parent.parent / 'site' / 'index.html'
out.write_text(s)
print('wrote', out)

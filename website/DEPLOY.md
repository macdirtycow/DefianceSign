# Deploy defiancesign.com

Static site — no build step required.

## Quick deploy (Cloudflare Pages)

1. Push repo to GitHub
2. Cloudflare Dashboard → Pages → Create project → Connect Git
3. Build settings:
   - **Build command:** (leave empty)
   - **Build output directory:** `website`
4. Add custom domain `defiancesign.com`
5. Enable HTTPS (automatic)

## Qadbak (defiancesign.com) — website + bootstrap API

### One command (from your Mac, SSH to panel VPS)

```bash
cd ~/Projects/MapleSign
bash scripts/deploy-qadbak.sh
# Or: VPS=root@YOUR_VPS_IP DOMAIN=defiancesign.com bash scripts/deploy-qadbak.sh
```

This uploads:
- `website/` → `/home/<user>/public_html/` (includes `install.html`)
- Bootstrap signer API → systemd on port `8788`
- nginx proxy `/api` → local API (via Qadbak `proxies.json`)

Then open **https://defiancesign.com/install.html** in Safari on iPad.

### Manual website-only upload

Upload `packages/defiancesign-website.zip` to `public_html` if you only need the static pages first.

### After deploy

- Install page: https://defiancesign.com/install.html
- API (internal): `http://127.0.0.1:8788/health`
- Public API: `https://defiancesign.com/api/health`

## Manual upload (qadbak / public_html)

Upload everything in `website/` directly into `public_html` — not in a subfolder.
All paths are relative (`style.css`, `assets/logo.svg`) so they work from `public_html`.

```
public_html/
├── index.html
├── docs.html
├── style.css
└── assets/
    ├── logo.svg
    └── favicon.svg
```

Verify after upload:
- https://defiancesign.com/style.css — should show CSS text
- https://defiancesign.com/assets/logo.svg — should show the logo

## Manual upload (generic)

Upload everything in `website/` to your web root:

```
website/
├── index.html
├── docs.html
├── style.css
├── assets/
│   ├── logo.svg
│   └── favicon.svg
└── api/README.md
```

## DNS

Point `defiancesign.com` A/CNAME to your host. For Cloudflare Pages, use the provided CNAME target.

## Optional: API (bootstrap install + plist proxy)

The static site lives in `website/`. The **bootstrap signer API** is a separate service:

```bash
# From repo root
docker build -f services/bootstrap-signer/Dockerfile -t defiancesign-bootstrap .
```

Deploy to `api.defiancesign.com` with HTTPS. See `services/bootstrap-signer/README.md`.

`install.html` calls `https://api.defiancesign.com` by default.

## Optional: plist proxy only

See `api/README.md` for a Cloudflare Worker that hosts install manifests for Semi Local mode.

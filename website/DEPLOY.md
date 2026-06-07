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

## Optional: plist proxy

See `api/README.md` for a Cloudflare Worker that hosts install manifests for Semi Local mode.

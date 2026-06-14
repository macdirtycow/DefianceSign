# DefianceSign Bootstrap Signer

One-time web installer for **DefianceSign.ipa only**.

Users upload their own `.p12`, `.mobileprovision`, and password. The server signs the official DefianceSign IPA from GitHub releases, returns an `itms-services://` link, and **destroys certificate files immediately**. Signed IPAs expire after 10 minutes.

This is **not** a general signing service. Arbitrary IPAs cannot be signed.

## Security model

| Rule | Implementation |
|------|----------------|
| Only DefianceSign.ipa | IPA URL pinned to `macdirtycow/DefianceSign` GitHub releases |
| Bundle ID | Taken from your provisioning profile (wildcard profiles keep the official IPA ID) |
| No cert storage | `.p12` / `.mobileprovision` deleted right after `zsign` runs |
| Short-lived downloads | Signed IPA + manifest expire in 10 minutes |
| No passwords logged | Password only passed to `zsign` subprocess |

**Users still trust this server during the upload window.** Read the disclaimer on `install.html`.

## Requirements

- `zsign` binary on `PATH` (or set `ZSIGN_PATH`)
- Python 3.11+
- HTTPS in production (required for `itms-services://`)

## Local development

```bash
cd services/bootstrap-signer

# Build zsign (from repo root)
cd ../../Zsign && make && cd -

export ZSIGN_PATH=../../Zsign/bin/zsign
export BOOTSTRAP_PUBLIC_URL=http://127.0.0.1:8787
export BOOTSTRAP_CORS_ORIGINS=http://127.0.0.1:5500,http://127.0.0.1:8787

pip install -r requirements.txt
uvicorn main:app --reload --port 8787
```

Open `website/install.html` via a local static server and set the API URL in the page (or use defaults for localhost).

## Docker

From repository root:

```bash
docker build -f services/bootstrap-signer/Dockerfile -t defiancesign-bootstrap .
docker run --rm -p 8787:8787 \
  -e BOOTSTRAP_PUBLIC_URL=https://api.defiancesign.com \
  defiancesign-bootstrap
```

## Production deploy

1. Deploy API to `api.defiancesign.com` (VPS, Fly.io, Railway, etc.) with HTTPS
2. Upload static `website/` to `defiancesign.com`
3. In `install.html`, set `API_BASE` to `https://api.defiancesign.com`
4. Put nginx rate limiting in front (`limit_req`)

### Nginx example

```nginx
server {
    listen 443 ssl;
    server_name api.defiancesign.com;

    client_max_body_size 6m;

    location / {
        proxy_pass http://127.0.0.1:8787;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## API

### `POST /api/bootstrap/sign`

`multipart/form-data`:

| Field | Type |
|-------|------|
| `p12` | file |
| `mobileprovision` | file |
| `password` | string |
| `consent` | `true` |

Response:

```json
{
  "ok": true,
  "installUrl": "itms-services://?action=download-manifest&url=...",
  "expiresInSeconds": 600
}
```

Open `installUrl` in **Safari on iOS**.

### `GET /api/bootstrap/manifest/{token}`

Returns install plist XML.

### `GET /api/bootstrap/download/{token}`

Serves signed IPA (expires with token).

## After install

Import the same certificate into DefianceSign on device for signing other apps locally. Re-install DefianceSign after 7 days via this page again or AltStore/Sideloadly.

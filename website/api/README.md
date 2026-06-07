# DefianceSign plist proxy (optional)

DefianceSign's **Semi Local** install method uses an external HTTPS server to host the install manifest.

## Endpoint

```
GET https://defiancesign.com/api/genPlist?bundleid=...&name=...&version=...&fetchurl=...
```

Returns an `application/xml` plist for `itms-services://`.

## Deploy options (EU-friendly)

1. **Cloudflare Worker** — serverless, EU region configurable
2. **Small VPS** (e.g. Hetzner NL) with nginx proxy
3. **Temporary fallback**: DefianceSign uses local server mode (works without proxy)

## Privacy

The proxy only hosts install manifests. No certificates, no IPA files, no user data.

## Example Worker

```javascript
export default {
  async fetch(request) {
    const url = new URL(request.url);
    const target = `https://api.palera.in/genPlist?${url.searchParams}`;
    const res = await fetch(target);
    return new Response(await res.text(), {
      headers: { "Content-Type": "text/xml" },
    });
  },
};
```

Replace `api.palera.in` with your own implementation when you want full control.

# MapleSign plist-proxy (optioneel)

MapleSign's **Semi Local** installatiemethode gebruikt een externe HTTPS-server om het install-manifest te hosten.

## Endpoint

```
GET https://maplesign.net/api/genPlist?bundleid=...&name=...&version=...&fetchurl=...
```

Retourneert een `application/xml` plist voor `itms-services://`.

## Deploy opties (EU)

1. **Cloudflare Worker** — serverless, EU-regio instelbaar
2. **Kleine VPS** (Hetzner NL) met nginx + een simpele proxy naar een bestaande generator
3. **Tijdelijk**: MapleSign valt terug op lokale server-modus (aanbevolen)

## Privacy

De proxy host alleen install-manifests. Geen certificaten, geen IPA-bestanden, geen gebruikersdata.

## Voorbeeld Worker (concept)

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

Vervang `api.palera.in` door je eigen implementatie wanneer je volledige controle wilt.

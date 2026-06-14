# DefianceSign API

## Bootstrap signer (one-time install)

Install DefianceSign on iPhone/iPad **without a Mac**:

- **Website:** https://defiancesign.com/install.html
- **API:** https://api.defiancesign.com

Users upload `.p12` + `.mobileprovision` once. The server signs **only** the official `DefianceSign.ipa`, returns an `itms-services://` link, and **destroys certificate files immediately**.

See [`../../services/bootstrap-signer/README.md`](../../services/bootstrap-signer/README.md) for deploy instructions.

## Plist proxy (Semi Local mode in app)

```
GET https://api.defiancesign.com/api/genPlist?bundleid=...&name=...&version=...&fetchurl=...
```

Returns an `application/xml` plist for `itms-services://`.

## Privacy

- Bootstrap signer: no certificate retention; signed IPA links expire in 10 minutes
- Plist proxy: no user data, no certificates, no IPA hosting

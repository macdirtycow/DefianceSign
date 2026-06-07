# DefianceSign features

DefianceSign inherits the full Ksign/Feather feature set. Overview:

## Core (MVP)

- [x] `.p12` + `.mobileprovision` import
- [x] Keychain storage for passwords
- [x] OCSP revoke check on certificates
- [x] IPA signing via zsign
- [x] Server installation (Vapor + itms-services)
- [x] App library (unsigned/signed)

## ESign parity (phase 2)

- [x] Bulk signing (`BulkSigningView`)
- [x] Bulk installation
- [x] Dylib/framework/deb injection (`SigningTweaksView`, ElleKit)
- [x] Bundle ID, name, version, icon customization
- [x] AltStore repository sources
- [x] File manager (unzip, plist editor, hex editor)
- [x] Background downloads (`DownloadManager`, `BackgroundTaskManager`)
- [x] idevice/AFC installation (`InstallationProxy`, VPN + pairing)
- [x] IPA downloader with built-in browser
- [x] Logs tab

## Intentionally absent (security)

- [ ] Built-in shared certificates
- [ ] Anti-revoke DNS / OCSP blocking
- [ ] Telemetry / analytics

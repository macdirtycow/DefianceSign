# MapleSign functies

MapleSign erft de volledige Ksign/Feather feature-set. Overzicht:

## Kern (MVP)

- [x] `.p12` + `.mobileprovision` import
- [x] Keychain-opslag voor wachtwoorden
- [x] OCSP revoke-check op certificaten
- [x] IPA signen via zsign
- [x] Server-installatie (Vapor + itms-services)
- [x] App-bibliotheek (unsigned/signed)

## ESign-pariteit (fase 2)

- [x] Bulk signen (`BulkSigningView`)
- [x] Bulk installeren
- [x] Dylib/framework/deb injectie (`SigningTweaksView`, ElleKit)
- [x] Bundle ID, naam, versie, icon aanpassen
- [x] AltStore repository-bronnen
- [x] File manager (unzip, plist editor, hex editor)
- [x] Achtergrond downloads (`DownloadManager`, `BackgroundTaskManager`)
- [x] idevice/AFC installatie (`InstallationProxy`, VPN + pairing)
- [x] IPA downloader met ingebouwde browser
- [x] Logs-tab

## Bewust niet aanwezig (veiligheid)

- [ ] Ingebouwde gedeelde certificaten
- [ ] Anti-revoke DNS / OCSP-blokkering
- [ ] Telemetry / analytics

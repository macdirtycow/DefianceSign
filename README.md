# DefianceSign

Veilige, open-source IPA-signer en installer voor iPhone en iPad. Fork van [Ksign](https://github.com/Nyasami/Ksign) (gebaseerd op [Feather](https://github.com/khcrysalis/Feather)).

**Website:** [defiancesign.com](https://defiancesign.com)

## Waarom DefianceSign?

- **Open source** — volledig transparante code op GitHub
- **Geen Chinese backend** — geen telemetry, geen gedeelde certificaten
- **Eigen certificaat** — importeer je eigen `.p12` + `.mobileprovision` van je Apple Developer-account
- **Lokaal en veilig** — certificaatwachtwoorden in iOS Keychain, data blijft op je device
- **iPhone + iPad** — universele SwiftUI-app

## Vereisten

- iPhone of iPad met iOS 16+
- Mac met Xcode 15+ (alleen voor bouwen)
- [Apple Developer-account](https://developer.apple.com) ($99/jaar)
- Eenmalige installatie van DefianceSign zelf via Sideloadly, AltStore of SideStore

## Certificaat importeren

1. Ga naar [developer.apple.com](https://developer.apple.com) → Certificates → maak een iOS Development/Distribution certificaat
2. Maak een Provisioning Profile voor je devices
3. Exporteer `.p12` vanuit Keychain Access op je Mac
4. Open DefianceSign → Settings → Certificates → importeer `.p12` en `.mobileprovision`

Je p12-wachtwoord wordt opgeslagen in de iOS Keychain, niet in platte tekst.

Zie [scripts/export-p12-guide.md](scripts/export-p12-guide.md) voor een uitgebreide handleiding.

## Download

Download de nieuwste `.ipa` van [GitHub Releases (beta)](https://github.com/macdirtycow/DefianceSign/releases/tag/beta).

Website-bron staat in [`website/`](website/) — deploy naar [defiancesign.com](https://defiancesign.com).

## Bouwen

```bash
git clone https://github.com/defiancesign/DefianceSign --recursive
cd DefianceSign
./scripts/build-release.sh
# Output: packages/DefianceSign.ipa (~13 MB)
```

Of handmatig:

```bash
make DefianceSign
```

De build maakt een **unsigned IPA** die je daarna via Sideloadly/AltStore installeert.

## Beveiliging

DefianceSign doet **niet**:

- Ingebouwde gratis/gedeelde certificaten importeren
- Anti-revoke DNS of OCSP-blokkering
- Data naar externe servers sturen

## Licentie

GPL-3.0 — zie [LICENSE](LICENSE). Gebaseerd op Feather (GPL-3.0) en Ksign (GPL-3.0).

## Credits

- [Feather](https://github.com/khcrysalis/Feather) door samara / claration
- [Ksign](https://github.com/Nyasami/Ksign) door Nyasami
- [zsign](https://github.com/xtool-org/zsign) signing engine

## Disclaimer

DefianceSign is geen App Store-app. Gebruik alleen je eigen Apple Developer-certificaat. Misbruik van enterprise-certificaten schendt Apple's voorwaarden.

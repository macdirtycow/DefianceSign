# DefianceSign

Secure, open-source IPA signer and installer for iPhone and iPad. Fork of [Ksign](https://github.com/Nyasami/Ksign) (based on [Feather](https://github.com/khcrysalis/Feather)).

**Website:** [defiancesign.com](https://defiancesign.com)

## Why DefianceSign?

- **Open source** — fully transparent code on GitHub
- **No Chinese backend** — no telemetry, no shared certificates
- **Your own certificate** — import your `.p12` + `.mobileprovision` from your Apple Developer account
- **Local and secure** — certificate passwords in iOS Keychain, data stays on your device
- **iPhone + iPad** — universal SwiftUI app

## Requirements

- iPhone or iPad with iOS 16+
- Mac with Xcode 15+ (for building only)
- [Apple Developer account](https://developer.apple.com) ($99/year)
- One-time install of DefianceSign itself via Sideloadly, AltStore, or SideStore

## Import your certificate

1. Go to [developer.apple.com](https://developer.apple.com) → Certificates → create an iOS Development/Distribution certificate
2. Create a Provisioning Profile for your devices
3. Export `.p12` from Keychain Access on your Mac
4. Open DefianceSign → Settings → Certificates → import `.p12` and `.mobileprovision`

Your p12 password is stored in the iOS Keychain, not in plain text.

See [scripts/export-p12-guide.md](scripts/export-p12-guide.md) for a detailed guide.

## Download

Download the latest `.ipa` from [GitHub Releases](https://github.com/macdirtycow/DefianceSign/releases).

Website source is in [`website/`](website/) — deploy to [defiancesign.com](https://defiancesign.com).

## Build

```bash
git clone https://github.com/macdirtycow/DefianceSign --recursive
cd DefianceSign
./scripts/build-release.sh
# Output: packages/DefianceSign.ipa (~13 MB)
```

Or manually:

```bash
make DefianceSign
```

The build produces an **unsigned IPA** that you install via Sideloadly/AltStore afterward.

## Security

DefianceSign does **not**:

- Import built-in free/shared certificates
- Use anti-revoke DNS or OCSP blocking
- Send data to external servers

## License

GPL-3.0 — see [LICENSE](LICENSE). Based on Feather (GPL-3.0) and Ksign (GPL-3.0).

## Credits

- [Feather](https://github.com/khcrysalis/Feather) by samara / claration
- [Ksign](https://github.com/Nyasami/Ksign) by Nyasami
- [zsign](https://github.com/xtool-org/zsign) signing engine

## Disclaimer

DefianceSign is not an App Store app. Use only your own Apple Developer certificate. Misuse of enterprise certificates violates Apple's terms.

# DefianceSign installation guide

## First install (DefianceSign itself)

1. Download `DefianceSign.ipa` from [GitHub Releases](https://github.com/macdirtycow/DefianceSign/releases)
2. Install via Sideloadly, AltStore, or SideStore
3. Trust the developer profile on your iPhone/iPad

## Certificate

See [export-p12-guide.md](export-p12-guide.md).

## Sign & install apps

1. **Files** → import `.ipa`
2. **Library** → Unsigned → select app → **Sign**
3. Choose certificate and options
4. Tap **Install**

## Installation methods

| Method | When |
|--------|------|
| **Server** (default) | Works for most users; local HTTPS server |
| **idevice** | Advanced; requires VPN + pairing file |

Settings → Installation to switch.

## Re-sign after 7 days

Development certificates expire after 7 days. Open DefianceSign and sign again — no revoke bypass needed.

# DefianceSign installatiehandleiding

## Eerste installatie (DefianceSign zelf)

1. Download `DefianceSign.ipa` van [GitHub Releases (beta)](https://github.com/macdirtycow/DefianceSign/releases/tag/beta)
2. Installeer via Sideloadly, AltStore of SideStore
3. Vertrouw het developer-profiel op je iPhone/iPad

## Certificaat

Zie [export-p12-guide.md](export-p12-guide.md).

## App signeren & installeren

1. **Bestanden** → importeer `.ipa`
2. **Bibliotheek** → Unsigned → selecteer app → **Signeren**
3. Kies certificaat en opties
4. Tik **Installeren**

## Installatiemethoden

| Methode | Wanneer |
|---------|---------|
| **Server** (standaard) | Werkt voor de meeste gebruikers; lokale HTTPS-server |
| **idevice** | Geavanceerd; vereist VPN + pairing file |

Instellingen → Installatie om te wisselen.

## Her-signen na 7 dagen

Development-certificaten verlopen na 7 dagen. Open DefianceSign en signeer opnieuw — geen revoke-bypass nodig.

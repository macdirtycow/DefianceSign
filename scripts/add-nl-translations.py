#!/usr/bin/env python3
"""Add Dutch (nl) translations to Localizable.xcstrings for MapleSign."""

import json
from pathlib import Path

TRANSLATIONS = {
    "Get started signing by importing your first certificate.": "Begin met signen door je eerste certificaat te importeren.",
    "No Certificates": "Geen certificaten",
    "Certificates": "Certificaten",
    "Import": "Importeren",
    "Library": "Bibliotheek",
    "Settings": "Instellingen",
    "Files": "Bestanden",
    "Installation": "Installatie",
    "Server": "Server",
    "Website": "Website",
    "About": "Over",
    "Signing Options": "Signeeropties",
    "App Features": "App-functies",
    "Reset": "Resetten",
    "Install": "Installeren",
    "Sign": "Signeren",
    "New Certificate": "Nieuw certificaat",
    "Import Certificate File": "Certificaatbestand importeren",
    "Import Provisioning File": "Provisioningprofiel importeren",
    "Enter Password": "Wachtwoord invoeren",
    "Save": "Opslaan",
    "Downloads": "Downloads",
    "Sources": "Bronnen",
    "Based on Feather and Ksign — open-source sideloading tools.": "Gebaseerd op Feather en Ksign — open-source sideload-tools.",
    "MapleSign is a secure, open-source IPA signer for iPhone and iPad.\n\n- Import your own Apple Developer certificate\n- Sign and install IPA files on-device\n- No bundled certificates or telemetry\n- Based on Feather and Ksign": "MapleSign is een veilige, open-source IPA-signer voor iPhone en iPad.\n\n- Importeer je eigen Apple Developer-certificaat\n- Signeer en installeer IPA-bestanden op je device\n- Geen ingebouwde certificaten of telemetry\n- Gebaseerd op Feather en Ksign",
    "Uses a local HTTPS server and itms-services:// to install signed IPAs.": "Gebruikt een lokale HTTPS-server en itms-services:// om gesigneerde IPA's te installeren.",
    "Uses VPN tunnel and AFC to install directly via installd.": "Gebruikt een VPN-tunnel en AFC om direct via installd te installeren.",
    "All of MapleSign files except certificates are contained in the documents directory, here are some quick links to these.": "Alle MapleSign-bestanden (behalve certificaten) staan in de documentenmap. Hier zijn snelle links.",
    "Add and manage certificates used for signing applications.": "Beheer certificaten die gebruikt worden om apps te signeren.",
    "GitHub Repository": "GitHub-repository",
}

def main() -> None:
    path = Path(__file__).resolve().parents[1] / "MapleSign/Resources/Localizable.xcstrings"
    data = json.loads(path.read_text(encoding="utf-8"))
    strings = data.setdefault("strings", {})

    for key, nl_value in TRANSLATIONS.items():
        entry = strings.setdefault(key, {"localizations": {}})
        locs = entry.setdefault("localizations", {})
        locs["nl"] = {
            "stringUnit": {
                "state": "translated",
                "value": nl_value,
            }
        }

    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Added/updated {len(TRANSLATIONS)} Dutch translations in {path}")

if __name__ == "__main__":
    main()

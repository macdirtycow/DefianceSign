# Apple Developer-certificaat exporteren voor DefianceSign

## Stap 1: Certificaat aanmaken

1. Log in op [developer.apple.com](https://developer.apple.com)
2. Ga naar **Certificates, Identifiers & Profiles**
3. Klik **Certificates** → **+** → kies **iOS App Development** (of Distribution)
4. Volg de stappen en download het certificaat (`.cer`)

## Stap 2: Certificaat installeren op je Mac

1. Dubbelklik op het `.cer`-bestand
2. Het wordt toegevoegd aan **Keychain Access** (login keychain)

## Stap 3: Provisioning Profile

1. Ga naar **Profiles** → **+**
2. Kies **iOS App Development**
3. Selecteer je App ID en geregistreerde devices
4. Download het `.mobileprovision`-bestand

## Stap 4: Exporteer .p12

1. Open **Keychain Access** op je Mac
2. Zoek je certificaat onder **My Certificates**
3. Rechtsklik → **Export** → kies **Personal Information Exchange (.p12)**
4. Stel een wachtwoord in (onthoud dit — DefianceSign vraagt dit bij import)

## Stap 5: Importeer in DefianceSign

1. Open DefianceSign op je iPhone/iPad
2. Ga naar **Settings** → **Certificates** → **+**
3. Importeer het `.p12`-bestand en het `.mobileprovision`-bestand
4. Voer je p12-wachtwoord in

Het wachtwoord wordt veilig opgeslagen in de iOS Keychain.

## Tips

- Registreer je device op developer.apple.com voordat je een profile maakt
- Development-certificaten verlopen na 7 dagen (her-sign via DefianceSign)
- Deel nooit je `.p12` met anderen

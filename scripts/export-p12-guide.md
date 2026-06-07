# Export Apple Developer certificate for DefianceSign

## Step 1: Create certificate

1. Log in at [developer.apple.com](https://developer.apple.com)
2. Go to **Certificates, Identifiers & Profiles**
3. Click **Certificates** → **+** → choose **iOS App Development** (or Distribution)
4. Follow the steps and download the certificate (`.cer`)

## Step 2: Install certificate on your Mac

1. Double-click the `.cer` file
2. It is added to **Keychain Access** (login keychain)

## Step 3: Provisioning Profile

1. Go to **Profiles** → **+**
2. Choose **iOS App Development**
3. Select your App ID and registered devices
4. Download the `.mobileprovision` file

## Step 4: Export .p12

1. Open **Keychain Access** on your Mac
2. Find your certificate under **My Certificates**
3. Right-click → **Export** → choose **Personal Information Exchange (.p12)**
4. Set a password (remember it — DefianceSign asks for it on import)

## Step 5: Import into DefianceSign

1. Open DefianceSign on your iPhone/iPad
2. Go to **Settings** → **Certificates** → **+**
3. Import the `.p12` file and the `.mobileprovision` file
4. Enter your p12 password

The password is stored securely in the iOS Keychain.

## Tips

- Register your device on developer.apple.com before creating a profile
- Development certificates expire after 7 days (re-sign via DefianceSign)
- Never share your `.p12` with others

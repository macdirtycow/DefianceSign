from config import APP_NAME, APP_VERSION


def build_manifest_xml(ipa_url: str, bundle_id: str) -> str:
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>items</key>
  <array>
    <dict>
      <key>assets</key>
      <array>
        <dict>
          <key>kind</key>
          <string>software-package</string>
          <key>url</key>
          <string>{_xml_escape(ipa_url)}</string>
        </dict>
      </array>
      <key>metadata</key>
      <dict>
        <key>bundle-identifier</key>
        <string>{bundle_id}</string>
        <key>bundle-version</key>
        <string>{APP_VERSION}</string>
        <key>kind</key>
        <string>software</string>
        <key>title</key>
        <string>{APP_NAME}</string>
      </dict>
    </dict>
  </array>
</dict>
</plist>
"""


def build_itms_url(manifest_url: str) -> str:
    from urllib.parse import quote

    return f"itms-services://?action=download-manifest&url={quote(manifest_url, safe='')}"


def _xml_escape(value: str) -> str:
    return (
        value.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
        .replace("'", "&apos;")
    )

import os

# Bundle ID inside the official DefianceSign.ipa from GitHub releases.
# Wildcard provisioning profiles keep this ID; specific App IDs are applied at sign time.
IPA_BUNDLE_ID = "net.defiancesign.app"
APP_NAME = "DefianceSign"
IPA_DOWNLOAD_URL = os.getenv(
    "BOOTSTRAP_IPA_URL",
    "https://github.com/macdirtycow/DefianceSign/releases/download/v1.1.4/DefianceSign.ipa",
)
# Local unsigned IPA uploaded from a Mac. Preferred over GitHub when the file exists.
IPA_PATH = os.getenv("BOOTSTRAP_IPA_PATH", "/opt/defiancesign-bootstrap/DefianceSign.ipa")
APP_VERSION = os.getenv("BOOTSTRAP_APP_VERSION", "1.1.4")

ZSIGN_PATH = os.getenv("ZSIGN_PATH", "zsign")
PUBLIC_BASE_URL = os.getenv("BOOTSTRAP_PUBLIC_URL", "https://defiancesign.com").rstrip("/")

# Signed IPA download links expire quickly.
SIGNED_IPA_TTL_SECONDS = int(os.getenv("BOOTSTRAP_IPA_TTL", "600"))

MAX_UPLOAD_BYTES = int(os.getenv("BOOTSTRAP_MAX_UPLOAD", str(5 * 1024 * 1024)))
MAX_IPA_BYTES = int(os.getenv("BOOTSTRAP_MAX_IPA", str(400 * 1024 * 1024)))
ZSIGN_TIMEOUT_SECONDS = int(os.getenv("BOOTSTRAP_ZSIGN_TIMEOUT", "600"))

# Comma-separated origins, or * for dev only.
CORS_ORIGINS = [
    o.strip()
    for o in os.getenv(
        "BOOTSTRAP_CORS_ORIGINS",
        "https://defiancesign.com,https://www.defiancesign.com,http://127.0.0.1:5500,http://127.0.0.1:8788",
    ).split(",")
    if o.strip()
]

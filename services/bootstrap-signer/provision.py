import plistlib
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from config import IPA_BUNDLE_ID


def resolve_signing_bundle_id(path: Path) -> str:
    """
    Read the provisioning profile and return the bundle ID to use when signing.
    Wildcard profiles keep the official IPA bundle ID; specific App IDs are
    applied via zsign so users are not locked to net.defiancesign.app.
    """
    data = _read_provision_plist(path)
    if data is None:
        raise ValueError("Could not read provisioning profile")

    if _is_expired(data):
        raise ValueError("Provisioning profile has expired")

    raw_app_id = _extract_app_id(data)
    if raw_app_id is None:
        raise ValueError("Could not read App ID from provisioning profile")

    if raw_app_id == "*" or raw_app_id.endswith(".*"):
        return IPA_BUNDLE_ID

    return raw_app_id


def _read_provision_plist(path: Path) -> dict | None:
    try:
        raw = path.read_bytes()
        for marker in (b"<?xml", b"bplist"):
            idx = raw.find(marker)
            if idx != -1:
                chunk = raw[idx:]
                if marker == b"<?xml":
                    end = chunk.find(b"</plist>")
                    if end != -1:
                        chunk = chunk[: end + len(b"</plist>")]
                    return plistlib.loads(chunk)
                return plistlib.loads(chunk)
    except Exception:
        pass

    try:
        result = subprocess.run(
            ["security", "cms", "-D", "-i", str(path)],
            capture_output=True,
            timeout=10,
            check=False,
        )
        if result.returncode == 0 and result.stdout:
            return plistlib.loads(result.stdout)
    except (FileNotFoundError, subprocess.TimeoutExpired, plistlib.InvalidFileException):
        pass

    return None


def _extract_app_id(data: dict) -> str | None:
    entitlements = data.get("Entitlements", {})
    if isinstance(entitlements, dict):
        app_id = entitlements.get("application-identifier")
        if isinstance(app_id, str):
            parts = app_id.split(".", 1)
            return parts[1] if len(parts) == 2 else app_id
    return None


def _is_expired(data: dict) -> bool:
    exp = data.get("ExpirationDate")
    if not isinstance(exp, datetime):
        return False
    if exp.tzinfo is None:
        exp = exp.replace(tzinfo=timezone.utc)
    return exp < datetime.now(timezone.utc)

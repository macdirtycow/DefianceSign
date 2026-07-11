import plistlib
import subprocess
from datetime import datetime, timezone
from pathlib import Path

from config import IPA_BUNDLE_ID


def validate_provisioning_profile(path: Path) -> str:
    """
    Validate a Development or Ad Hoc profile and return the bundle ID for signing.
    Raises ValueError with a user-facing message when install would fail on device.
    """
    data = _read_provision_plist(path)
    if data is None:
        raise ValueError("Could not read provisioning profile")

    if _is_expired(data):
        raise ValueError("Provisioning profile has expired — create a new one in Apple Developer")

    raw_app_id = _extract_app_id(data)
    if raw_app_id is None:
        raise ValueError("Could not read App ID from provisioning profile")

    _validate_installable_profile(data)
    return _resolve_bundle_id(raw_app_id)


def resolve_signing_bundle_id(path: Path) -> str:
    """Backward-compatible alias used by signer.py."""
    return validate_provisioning_profile(path)


def _resolve_bundle_id(raw_app_id: str) -> str:
    if raw_app_id == "*" or raw_app_id.endswith(".*"):
        prefix = raw_app_id[:-2] if raw_app_id.endswith(".*") else ""
        if prefix and not IPA_BUNDLE_ID.startswith(prefix + "."):
            raise ValueError(
                f"Wildcard profile ({raw_app_id}) does not cover {IPA_BUNDLE_ID}. "
                "Create a Development profile with App ID net.defiancesign.app, "
                "or a specific App ID profile for your bundle."
            )
        return IPA_BUNDLE_ID
    return raw_app_id


def _validate_installable_profile(data: dict) -> None:
    entitlements = data.get("Entitlements", {})
    if not isinstance(entitlements, dict):
        raise ValueError("Provisioning profile is missing entitlements")

    provisions_all = data.get("ProvisionsAllDevices") is True
    devices = data.get("ProvisionedDevices")
    device_count = len(devices) if isinstance(devices, list) else 0

    if not provisions_all and device_count == 0:
        raise ValueError(
            "Profile has no registered devices. Use an iOS App Development or Ad Hoc "
            "profile that includes your iPhone/iPad UDID (not App Store Distribution)."
        )

    get_task_allow = entitlements.get("get-task-allow")
    if not provisions_all and get_task_allow is not True and device_count > 0:
        # Ad Hoc profiles may omit get-task-allow; still installable when UDID matches.
        pass
    elif not provisions_all and get_task_allow is not True and device_count == 0:
        raise ValueError(
            "Profile cannot install to a device. Use iOS App Development with your UDID registered."
        )


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

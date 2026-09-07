import shutil
import plistlib
import re
import subprocess
import urllib.request
import zipfile
from pathlib import Path

from config import IPA_DOWNLOAD_URL, IPA_PATH, ZSIGN_PATH, ZSIGN_TIMEOUT_SECONDS
from provision import validate_provisioning_profile
from security import secure_workspace, wipe_workspace


class SignError(Exception):
    pass


def _write_ipa_bytes(dest: Path, data: bytes, min_bytes: int = 1_000_000) -> None:
    if len(data) < min_bytes:
        raise SignError("IPA looks too small — aborting")
    dest.write_bytes(data)


def download_official_ipa(dest: Path) -> None:
    """Use the IPA uploaded to this server, else fetch the pinned GitHub release."""
    local = Path(IPA_PATH) if IPA_PATH else None
    if local and local.is_file():
        _write_ipa_bytes(dest, local.read_bytes())
        return

    if not IPA_DOWNLOAD_URL.startswith("https://github.com/macdirtycow/DefianceSign/releases/download/"):
        raise SignError("IPA source is not pinned to official DefianceSign releases")

    req = urllib.request.Request(
        IPA_DOWNLOAD_URL,
        headers={"User-Agent": "DefianceSign-Bootstrap/1.0"},
    )
    with urllib.request.urlopen(req, timeout=120) as response:
        data = response.read()
    _write_ipa_bytes(dest, data)


def inspect_ipa(ipa_path: Path) -> tuple[str | None, str, str]:
    """Return (bundle_id, app_name, version) from Payload/*.app/Info.plist."""
    try:
        with zipfile.ZipFile(ipa_path) as archive:
            names = [
                name
                for name in archive.namelist()
                if name.startswith("Payload/") and name.endswith(".app/Info.plist")
            ]
            if not names:
                raise SignError("Not a valid IPA — missing Payload/*.app/Info.plist")
            names.sort(key=lambda n: n.count("/"))
            raw = archive.read(names[0])
    except zipfile.BadZipFile as exc:
        raise SignError("Uploaded file is not a valid IPA (zip)") from exc

    try:
        info = plistlib.loads(raw)
    except Exception as exc:
        raise SignError("Could not read Info.plist inside the IPA") from exc

    bundle_id = info.get("CFBundleIdentifier")
    if not isinstance(bundle_id, str) or not bundle_id.strip():
        bundle_id = None
    name = info.get("CFBundleDisplayName") or info.get("CFBundleName") or "App"
    if not isinstance(name, str) or not name.strip():
        name = "App"
    version = info.get("CFBundleShortVersionString") or info.get("CFBundleVersion") or "1.0"
    if not isinstance(version, str):
        version = str(version)
    return bundle_id, name.strip(), version.strip()


def safe_ipa_filename(name: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9._-]+", "-", name).strip(".-") or "App"
    return f"{cleaned}.ipa"


def _verify_signed_ipa(ipa_path: Path) -> None:
    """Ensure the OTA IPA contains an embedded provisioning profile."""
    try:
        with zipfile.ZipFile(ipa_path) as archive:
            has_profile = any(
                name.endswith("embedded.mobileprovision")
                for name in archive.namelist()
            )
    except zipfile.BadZipFile as exc:
        raise SignError("Signed IPA is corrupt") from exc

    if not has_profile:
        raise SignError(
            "Signed IPA is missing embedded.mobileprovision. "
            "The server signer needs an update — try Sideloadly or ESign meanwhile."
        )


def sign_ipa(
    p12_bytes: bytes,
    mobileprovision_bytes: bytes,
    password: str,
    unsigned_ipa_path: Path | None = None,
) -> tuple[Path, str, str, str]:
    """
    Sign an IPA in an ephemeral workspace.
    Returns signed IPA path, bundle ID, app name, version.
    Caller must wipe workspace when done serving.
    """
    workspace = secure_workspace()
    p12_path = workspace / "input.p12"
    provision_path = workspace / "input.mobileprovision"
    unsigned_ipa = workspace / "input.ipa"
    signed_ipa = workspace / "signed.ipa"

    try:
        p12_path.write_bytes(p12_bytes)
        provision_path.write_bytes(mobileprovision_bytes)
        p12_path.chmod(0o600)
        provision_path.chmod(0o600)

        if p12_path.stat().st_size < 256:
            raise SignError("Uploaded .p12 file looks invalid or empty")

        custom = unsigned_ipa_path is not None
        if custom:
            if not unsigned_ipa_path.is_file():
                raise SignError("Uploaded IPA is missing")
            shutil.copy2(unsigned_ipa_path, unsigned_ipa)
            if unsigned_ipa.stat().st_size < 10_000:
                raise SignError("Uploaded IPA looks too small — aborting")
        else:
            download_official_ipa(unsigned_ipa)

        ipa_bundle_id, app_name, app_version = inspect_ipa(unsigned_ipa)
        try:
            bundle_id = validate_provisioning_profile(provision_path, ipa_bundle_id)
        except ValueError as exc:
            raise SignError(str(exc)) from exc

        cmd = [
            ZSIGN_PATH,
            "-q",
            "-k",
            str(p12_path),
            "-m",
            str(provision_path),
            "-p",
            password,
            "-o",
            str(signed_ipa),
            "-b",
            bundle_id,
            str(unsigned_ipa),
        ]
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=ZSIGN_TIMEOUT_SECONDS
        )
        if result.returncode != 0:
            detail = (result.stderr or result.stdout or "zsign failed").strip()
            if "p12" in detail.lower() or "password" in detail.lower() or "private key" in detail.lower():
                raise SignError(
                    "Invalid .p12 password or corrupt certificate file. "
                    "Re-export from Keychain Access and leave the password blank if you did not set one."
                )
            raise SignError(f"Signing failed: {detail[:300]}")

        min_signed = 10_000 if custom else 1_000_000
        if not signed_ipa.is_file() or signed_ipa.stat().st_size < min_signed:
            raise SignError("Signed IPA was not produced")

        _verify_signed_ipa(signed_ipa)

        final_path = workspace / safe_ipa_filename(app_name)
        signed_ipa.replace(final_path)
        unsigned_ipa.unlink(missing_ok=True)
        return final_path, bundle_id, app_name, app_version
    except Exception:
        wipe_workspace(workspace)
        raise
    finally:
        for cred in (p12_path, provision_path):
            if cred.exists():
                cred.unlink(missing_ok=True)


def sign_defiancesign_ipa(
    p12_bytes: bytes,
    mobileprovision_bytes: bytes,
    password: str,
) -> tuple[Path, str]:
    signed_ipa, bundle_id, _, _ = sign_ipa(p12_bytes, mobileprovision_bytes, password)
    return signed_ipa, bundle_id

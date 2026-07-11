import subprocess
import urllib.request
import zipfile
from pathlib import Path

from config import IPA_DOWNLOAD_URL, ZSIGN_PATH
from provision import validate_provisioning_profile
from security import secure_workspace, wipe_workspace


class SignError(Exception):
    pass


def download_official_ipa(dest: Path) -> None:
    """Fetch the pinned DefianceSign.ipa from GitHub releases only."""
    if not IPA_DOWNLOAD_URL.startswith("https://github.com/macdirtycow/DefianceSign/releases/download/"):
        raise SignError("IPA source is not pinned to official DefianceSign releases")

    req = urllib.request.Request(
        IPA_DOWNLOAD_URL,
        headers={"User-Agent": "DefianceSign-Bootstrap/1.0"},
    )
    with urllib.request.urlopen(req, timeout=120) as response:
        data = response.read()
    if len(data) < 1_000_000:
        raise SignError("Downloaded IPA looks too small — aborting")
    dest.write_bytes(data)


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


def sign_defiancesign_ipa(
    p12_bytes: bytes,
    mobileprovision_bytes: bytes,
    password: str,
) -> tuple[Path, str]:
    """
    Sign only the official DefianceSign.ipa in an ephemeral workspace.
    Returns signed IPA path and the bundle ID used. Caller must wipe workspace when done serving.
    """
    workspace = secure_workspace()
    p12_path = workspace / "input.p12"
    provision_path = workspace / "input.mobileprovision"
    unsigned_ipa = workspace / "DefianceSign.ipa"
    signed_ipa = workspace / "DefianceSign-signed.ipa"

    try:
        p12_path.write_bytes(p12_bytes)
        provision_path.write_bytes(mobileprovision_bytes)
        p12_path.chmod(0o600)
        provision_path.chmod(0o600)

        if p12_path.stat().st_size < 256:
            raise SignError("Uploaded .p12 file looks invalid or empty")

        try:
            bundle_id = validate_provisioning_profile(provision_path)
        except ValueError as exc:
            raise SignError(str(exc)) from exc

        download_official_ipa(unsigned_ipa)

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
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
        if result.returncode != 0:
            detail = (result.stderr or result.stdout or "zsign failed").strip()
            if "p12" in detail.lower() or "password" in detail.lower() or "private key" in detail.lower():
                raise SignError(
                    "Invalid .p12 password or corrupt certificate file. "
                    "Re-export from Keychain Access and leave the password blank if you did not set one."
                )
            raise SignError(f"Signing failed: {detail[:300]}")

        if not signed_ipa.is_file() or signed_ipa.stat().st_size < 1_000_000:
            raise SignError("Signed IPA was not produced")

        _verify_signed_ipa(signed_ipa)

        unsigned_ipa.unlink(missing_ok=True)
        return signed_ipa, bundle_id
    except Exception:
        wipe_workspace(workspace)
        raise
    finally:
        for cred in (p12_path, provision_path):
            if cred.exists():
                cred.unlink(missing_ok=True)

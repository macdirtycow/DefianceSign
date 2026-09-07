from pathlib import Path

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, PlainTextResponse, JSONResponse

from config import (
    APP_NAME,
    APP_VERSION,
    CORS_ORIGINS,
    IPA_BUNDLE_ID,
    IPA_PATH,
    MAX_IPA_BYTES,
    MAX_UPLOAD_BYTES,
    PUBLIC_BASE_URL,
    SIGNED_IPA_TTL_SECONDS,
)
from manifest import build_itms_url, build_manifest_xml
from security import ArtifactStore, secure_workspace, wipe_workspace
from signer import SignError, sign_ipa

app = FastAPI(
    title="DefianceSign Bootstrap Signer",
    description="Ephemeral IPA signer. Certificates are never stored.",
    version="1.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

store = ArtifactStore()


async def _read_bounded(upload: UploadFile, label: str) -> bytes:
    data = await upload.read()
    if not data:
        raise HTTPException(400, f"Missing {label}")
    if len(data) > MAX_UPLOAD_BYTES:
        raise HTTPException(400, f"{label} is too large (max {MAX_UPLOAD_BYTES // 1024 // 1024} MB)")
    return data


async def _save_ipa_upload(upload: UploadFile, dest: Path) -> None:
    written = 0
    dest.parent.mkdir(parents=True, exist_ok=True)
    with dest.open("wb") as out:
        while True:
            chunk = await upload.read(1024 * 1024)
            if not chunk:
                break
            written += len(chunk)
            if written > MAX_IPA_BYTES:
                dest.unlink(missing_ok=True)
                raise HTTPException(
                    400,
                    f"IPA is too large (max {MAX_IPA_BYTES // 1024 // 1024} MB)",
                )
            out.write(chunk)
    if written < 10_000:
        dest.unlink(missing_ok=True)
        raise HTTPException(400, "Uploaded IPA looks empty or too small")


@app.get("/health")
@app.get("/api/health")
def health() -> dict:
    local_ipa = Path(IPA_PATH) if IPA_PATH else Path()
    local_ready = local_ipa.is_file() and local_ipa.stat().st_size >= 1_000_000
    return {
        "ok": True,
        "service": "bootstrap-signer",
        "app": APP_NAME,
        "version": APP_VERSION,
        "defaultBundleId": IPA_BUNDLE_ID,
        "signing": "uploaded-ipa-or-defiancesign",
        "ipaSource": "local" if local_ready else "github",
        "ipaBytes": local_ipa.stat().st_size if local_ready else None,
        "maxIpaMb": MAX_IPA_BYTES // 1024 // 1024,
    }


@app.get("/api/genPlist")
def gen_plist(
    bundleid: str,
    name: str,
    version: str,
    fetchurl: str,
) -> PlainTextResponse:
    """Install manifest proxy used by Semi Local mode in the app."""
    xml = build_manifest_xml(fetchurl, bundleid, title=name, version=version)
    return PlainTextResponse(xml, media_type="application/xml")


@app.post("/api/bootstrap/sign")
async def bootstrap_sign(
    p12: UploadFile = File(...),
    mobileprovision: UploadFile = File(...),
    password: str = Form(...),
    consent: str = Form(default=""),
    ipa: UploadFile | None = File(default=None),
) -> JSONResponse:
    if consent.lower() not in ("true", "1", "yes", "on"):
        raise HTTPException(400, "You must confirm ephemeral signing consent")

    if len(password) > 256:
        raise HTTPException(400, "Certificate password is too long (max 256 characters)")

    p12_bytes = await _read_bounded(p12, ".p12 file")
    provision_bytes = await _read_bounded(mobileprovision, ".mobileprovision file")

    uploaded_ipa: Path | None = None
    upload_workspace: Path | None = None
    filename = (ipa.filename or "").lower() if ipa is not None else ""
    has_custom_ipa = bool(ipa is not None and filename and not filename.endswith("/"))

    try:
        if has_custom_ipa:
            upload_workspace = secure_workspace()
            uploaded_ipa = upload_workspace / "upload.ipa"
            await _save_ipa_upload(ipa, uploaded_ipa)

        signed_ipa, bundle_id, app_name, app_version = sign_ipa(
            p12_bytes,
            provision_bytes,
            password,
            unsigned_ipa_path=uploaded_ipa,
        )
    except SignError as exc:
        raise HTTPException(400, str(exc)) from exc
    finally:
        p12_bytes = b""
        provision_bytes = b""
        if upload_workspace is not None:
            wipe_workspace(upload_workspace)

    workspace = signed_ipa.parent
    manifest_path = workspace / "manifest.plist"
    token = store.put(signed_ipa, manifest_path, SIGNED_IPA_TTL_SECONDS)

    ipa_url = f"{PUBLIC_BASE_URL}/api/bootstrap/download/{token}"
    manifest_url = f"{PUBLIC_BASE_URL}/api/bootstrap/manifest/{token}"
    install_url = build_itms_url(manifest_url)

    manifest_path.write_text(
        build_manifest_xml(ipa_url, bundle_id, title=app_name, version=app_version),
        encoding="utf-8",
    )

    return JSONResponse(
        {
            "ok": True,
            "app": app_name,
            "bundleId": bundle_id,
            "version": app_version,
            "installUrl": install_url,
            "downloadUrl": ipa_url,
            "manifestUrl": manifest_url,
            "expiresInSeconds": SIGNED_IPA_TTL_SECONDS,
            "customIpa": has_custom_ipa,
            "message": "Certificate files were destroyed on the server.",
        }
    )


@app.get("/api/bootstrap/manifest/{token}")
def download_manifest(token: str) -> PlainTextResponse:
    item = store.get(token)
    if item is None:
        raise HTTPException(404, "Install link expired or invalid")
    xml = item.manifest_path.read_text(encoding="utf-8")
    return PlainTextResponse(xml, media_type="application/xml")


@app.get("/api/bootstrap/download/{token}")
def download_ipa(token: str) -> FileResponse:
    item = store.get(token)
    if item is None:
        raise HTTPException(404, "Download link expired or invalid")
    return FileResponse(
        path=item.ipa_path,
        media_type="application/octet-stream",
        filename=item.ipa_path.name or "signed.ipa",
    )


@app.get("/")
def root() -> dict:
    return {
        "service": "DefianceSign bootstrap signer",
        "defaultBundleId": IPA_BUNDLE_ID,
        "note": "POST /api/bootstrap/sign with p12, mobileprovision, password, optional ipa.",
    }

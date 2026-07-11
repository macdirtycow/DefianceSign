import time
from pathlib import Path

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, PlainTextResponse, JSONResponse

from config import (
    APP_NAME,
    APP_VERSION,
    CORS_ORIGINS,
    IPA_BUNDLE_ID,
    MAX_UPLOAD_BYTES,
    PUBLIC_BASE_URL,
    SIGNED_IPA_TTL_SECONDS,
)
from manifest import build_itms_url, build_manifest_xml
from security import ArtifactStore, wipe_workspace
from signer import SignError, sign_defiancesign_ipa

app = FastAPI(
    title="DefianceSign Bootstrap Signer",
    description="One-time installer for DefianceSign.ipa only. Certificates are never stored.",
    version="1.0.0",
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


@app.get("/health")
@app.get("/api/health")
def health() -> dict:
    return {
        "ok": True,
        "service": "bootstrap-signer",
        "defaultBundleId": IPA_BUNDLE_ID,
        "signing": "bundle-id-from-provisioning-profile",
    }


@app.get("/api/genPlist")
def gen_plist(
    bundleid: str,
    name: str,
    version: str,
    fetchurl: str,
) -> PlainTextResponse:
    """Install manifest proxy used by Semi Local mode in the app."""
    xml = build_manifest_xml(fetchurl, bundleid)
    return PlainTextResponse(xml, media_type="application/xml")


@app.post("/api/bootstrap/sign")
async def bootstrap_sign(
    p12: UploadFile = File(...),
    mobileprovision: UploadFile = File(...),
    password: str = Form(...),
    consent: str = Form(default=""),
) -> JSONResponse:
    if consent.lower() not in ("true", "1", "yes", "on"):
        raise HTTPException(400, "You must confirm ephemeral signing consent")

    if len(password) > 256:
        raise HTTPException(400, "Certificate password is too long (max 256 characters)")

    p12_bytes = await _read_bounded(p12, ".p12 file")
    provision_bytes = await _read_bounded(mobileprovision, ".mobileprovision file")

    try:
        signed_ipa, bundle_id = sign_defiancesign_ipa(p12_bytes, provision_bytes, password)
    except SignError as exc:
        raise HTTPException(400, str(exc)) from exc
    finally:
        p12_bytes = b""
        provision_bytes = b""

    workspace = signed_ipa.parent
    manifest_path = workspace / "manifest.plist"
    token = store.put(signed_ipa, manifest_path, SIGNED_IPA_TTL_SECONDS)

    ipa_url = f"{PUBLIC_BASE_URL}/api/bootstrap/download/{token}"
    manifest_url = f"{PUBLIC_BASE_URL}/api/bootstrap/manifest/{token}"
    install_url = build_itms_url(manifest_url)

    # Write manifest after we know public URLs.
    manifest_path.write_text(build_manifest_xml(ipa_url, bundle_id), encoding="utf-8")

    return JSONResponse(
        {
            "ok": True,
            "app": APP_NAME,
            "bundleId": bundle_id,
            "version": APP_VERSION,
            "installUrl": install_url,
            "manifestUrl": manifest_url,
            "expiresInSeconds": SIGNED_IPA_TTL_SECONDS,
            "message": "Certificate files were destroyed on the server. Open installUrl in Safari on your iPhone or iPad.",
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
        filename="DefianceSign.ipa",
    )


@app.get("/")
def root() -> dict:
    return {
        "service": "DefianceSign bootstrap signer",
        "defaultBundleId": IPA_BUNDLE_ID,
        "note": "POST /api/bootstrap/sign with p12, mobileprovision, password. Signs DefianceSign.ipa using your profile's App ID.",
    }

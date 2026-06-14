import os
import secrets
import shutil
import time
from dataclasses import dataclass
from pathlib import Path
from threading import Lock


@dataclass
class SignedArtifact:
    token: str
    ipa_path: Path
    manifest_path: Path
    expires_at: float


class ArtifactStore:
    """In-memory registry of short-lived signed IPAs. Nothing persisted to disk beyond TTL."""

    def __init__(self) -> None:
        self._items: dict[str, SignedArtifact] = {}
        self._lock = Lock()

    def put(self, ipa_path: Path, manifest_path: Path, ttl: int) -> str:
        token = secrets.token_urlsafe(32)
        expires_at = time.time() + ttl
        with self._lock:
            self._purge_expired_locked()
            self._items[token] = SignedArtifact(token, ipa_path, manifest_path, expires_at)
        return token

    def get(self, token: str) -> SignedArtifact | None:
        with self._lock:
            self._purge_expired_locked()
            item = self._items.get(token)
            if item is None or item.expires_at < time.time():
                return None
            return item

    def _purge_expired_locked(self) -> None:
        now = time.time()
        expired = [k for k, v in self._items.items() if v.expires_at < now]
        for key in expired:
            item = self._items.pop(key, None)
            if item:
                _secure_wipe_paths(item.ipa_path, item.manifest_path, item.ipa_path.parent)


def secure_workspace() -> Path:
    base = os.getenv("BOOTSTRAP_WORK_ROOT")
    if base:
        root = Path(base)
        root.mkdir(parents=True, exist_ok=True)
        path = root / secrets.token_hex(16)
        path.mkdir(mode=0o700)
        return path
    import tempfile

    return Path(tempfile.mkdtemp(prefix="defiancesign-bootstrap-"))


def _secure_wipe_paths(*paths: Path) -> None:
    seen_dirs: set[Path] = set()
    for path in paths:
        if path is None:
            continue
        try:
            if path.is_file():
                path.unlink(missing_ok=True)
            elif path.is_dir():
                shutil.rmtree(path, ignore_errors=True)
                seen_dirs.add(path)
        except OSError:
            pass
    for directory in seen_dirs:
        try:
            shutil.rmtree(directory, ignore_errors=True)
        except OSError:
            pass


def wipe_workspace(workspace: Path) -> None:
    if workspace.exists():
        shutil.rmtree(workspace, ignore_errors=True)

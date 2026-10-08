"""Zip frozen worker + torch cache for a GitHub Release.

Path.with_suffix('.zip') is wrong for versioned names: v0.2.0.zip would be
looked up as v0.2.zip because pathlib treats '.0' as the suffix.
"""
from __future__ import annotations

import os
import shutil
import sys
from pathlib import Path


def main() -> int:
    version = os.environ.get("VERSION", "").strip()
    if not version:
        print("ERROR: VERSION env is empty", file=sys.stderr)
        return 1

    worker_dir = Path("dist/worker/demucs_torch_worker")
    exe = worker_dir / "demucs_torch_worker.exe"
    models_dir = Path("models")
    if not exe.is_file():
        print(f"ERROR: missing frozen worker {exe}", file=sys.stderr)
        return 1
    if not models_dir.is_dir():
        print(f"ERROR: missing {models_dir}", file=sys.stderr)
        return 1

    assets = Path("release-assets")
    assets.mkdir(parents=True, exist_ok=True)

    worker_base = assets / f"demucs-cuda-windows-worker-v{version}"
    models_base = assets / "htdemucs-6s-torch-cache"
    shutil.make_archive(os.fspath(worker_base), "zip", "dist/worker", "demucs_torch_worker")
    shutil.make_archive(os.fspath(models_base), "zip", "models")

    worker_zip = Path(os.fspath(worker_base) + ".zip")
    models_zip = Path(os.fspath(models_base) + ".zip")
    if not worker_zip.is_file():
        print(f"ERROR: make_archive did not create {worker_zip}", file=sys.stderr)
        return 1
    if not models_zip.is_file():
        print(f"ERROR: make_archive did not create {models_zip}", file=sys.stderr)
        return 1

    worker_bytes = worker_zip.stat().st_size
    models_bytes = models_zip.stat().st_size
    print(f"packaged {worker_zip} ({worker_bytes} bytes)")
    print(f"packaged {models_zip} ({models_bytes} bytes)")
    if models_bytes <= 1_000_000:
        print(f"ERROR: models zip too small: {models_bytes}", file=sys.stderr)
        return 1
    if models_bytes >= 2_147_483_648:
        print(f"ERROR: models zip exceeds GitHub 2 GiB asset cap: {models_bytes}", file=sys.stderr)
        return 1

    gh_env = os.environ.get("GITHUB_ENV")
    if not gh_env:
        print("ERROR: GITHUB_ENV missing", file=sys.stderr)
        return 1
    with open(gh_env, "a", encoding="utf-8") as fh:
        fh.write(f"WORKER_BYTES={worker_bytes}\n")

    if worker_bytes >= 2_147_483_648:
        print(f"Worker zip is {worker_bytes} bytes (>= 2 GiB). Dropping from GitHub Release assets.")
        worker_zip.unlink()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

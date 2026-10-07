# demucs-windows

Windows x86_64 CUDA worker for Demucs stem separation. Frozen `demucs_torch_worker.exe`
is consumed by [demucs-ui-app](https://github.com/nicapotato/demucs-ui-app).

Official Meta Demucs + PyTorch CUDA 12.1. Apple Silicon MLX lives in
[demucs-mac-silicon](https://github.com/nicapotato/demucs-mac-silicon). Version: [`project.conf`](project.conf).

## Requirements

- Windows x86_64
- Python 3.12
- NVIDIA driver (CUDA 12.1 runtime ships inside the frozen worker; no CUDA toolkit)
- CPU works but is slow

VRAM: default `htdemucs_6s` segments want about 5–7 GB. 3–4 GB cards may OOM; set
`DEMUCS_DEVICE=cpu`.

## Dev CLI

```powershell
python -m pip install torch==2.2.2 torchaudio==2.2.2 --index-url https://download.pytorch.org/whl/cu121
python -m pip install -r requirements-windows.txt
$env:PYTHONPATH = (Get-Location)
$env:DEMUCS_DEVICE = "cuda"   # or cpu
python -m demucs_torch.separate song.mp3 -n htdemucs_6s -o stems --mp3 --track-name song
```

## Freeze worker

```powershell
$env:DEMUCS_TORCH_PYTHON = (Get-Command python).Source
pwsh -File scripts/prefetch_torch_models.ps1
pwsh -File scripts/freeze_worker_torch.ps1
# → dist/worker/demucs_torch_worker/demucs_torch_worker.exe
```

CI (`make ci` from git bash, or GitHub Actions `workflow_dispatch`) freezes the worker
and uploads `demucs-cuda-windows-worker`. Product zips and itch.io shipping are in
demucs-ui-app.

## Env vars

| Variable | Purpose |
|----------|---------|
| `DEMUCS_TORCH_PYTHON` | Python that has `demucs` + torch |
| `DEMUCS_TORCH_WORKER` | Path to frozen `demucs_torch_worker.exe` |
| `DEMUCS_TORCH_CACHE` | Model cache (`TORCH_HOME` = `cache/torch`) |
| `DEMUCS_DEVICE` | `cuda` or `cpu` (default: cuda if available) |
| `DEMUCS_TORCH_WORKER_DIST` | Override freeze output dir (default `dist/worker`) |

Unsigned PyInstaller onedirs trip SmartScreen (“Windows protected your PC”).
Right-click → Open / More info → Run anyway.

## License

MIT. Based on [Demucs](https://github.com/adefossez/demucs) by Meta Research. See `LICENSE`.

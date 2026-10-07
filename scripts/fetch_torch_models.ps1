# Download the pinned torch/HF Demucs cache from the immutable GitHub Release
# named in project.conf MODELS_RELEASE_TAG. Exit 2 if that release does not exist.
$ErrorActionPreference = "Stop"

$Repo = Split-Path -Parent $PSScriptRoot
$Conf = Join-Path $Repo "project.conf"
if (-not (Test-Path $Conf)) { Write-Error "missing $Conf" }

$tag = $null
Get-Content $Conf | ForEach-Object {
    if ($_ -match '^MODELS_RELEASE_TAG=(.*)$') {
        $tag = $Matches[1].Trim()
    }
}
if (-not $tag) { Write-Error "MODELS_RELEASE_TAG is empty in $Conf" }

function OriginToRepo([string]$url) {
    $url = $url -replace '\.git$', ''
    $url = $url -replace '^git@github\.com:', ''
    $url = $url -replace '^https://github\.com/', ''
    return $url
}

$ghRepo = $env:GITHUB_REPOSITORY
if (-not $ghRepo) {
    $origin = git -C $Repo remote get-url origin 2>$null
    if ($origin) { $ghRepo = OriginToRepo $origin }
}
if (-not $ghRepo) { Write-Error "set GITHUB_REPOSITORY or git remote origin" }

$PSNativeCommandUseErrorActionPreference = $false
gh release view $tag --repo $ghRepo *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "models release $tag is not published on $ghRepo yet"
    exit 2
}
$PSNativeCommandUseErrorActionPreference = $true

$Out = if ($env:DEMUCS_TORCH_CACHE) { $env:DEMUCS_TORCH_CACHE } else { Join-Path $Repo "models" }
New-Item -ItemType Directory -Force -Path $Out | Out-Null

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("dmx-models-" + [guid]::NewGuid().ToString("n"))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
try {
    gh release download $tag --repo $ghRepo -p "htdemucs-6s-torch-cache.zip" -p "htdemucs-6s-torch-cache.zip.sha256" -D $tmp
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    $zip = Join-Path $tmp "htdemucs-6s-torch-cache.zip"
    if (-not (Test-Path $zip)) { Write-Error "download missed htdemucs-6s-torch-cache.zip" }
    $hashFile = Join-Path $tmp "htdemucs-6s-torch-cache.zip.sha256"
    if (Test-Path $hashFile) {
        $expected = ((Get-Content $hashFile -Raw).Trim() -split '\s+')[0].ToLowerInvariant()
        $actual = (Get-FileHash -Algorithm SHA256 $zip).Hash.ToLowerInvariant()
        if ($expected -ne $actual) {
            Write-Error "sha256 mismatch for htdemucs-6s-torch-cache.zip: expected $expected got $actual"
        }
    }
    Expand-Archive -Path $zip -DestinationPath $Out -Force
} finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

$hfHub = Join-Path $Out "hf\hub"
$torchHub = Join-Path $Out "torch\hub"
if (-not (Test-Path $hfHub) -and -not (Test-Path $torchHub)) {
    Write-Error "extracted cache has neither $hfHub nor $torchHub"
}
Write-Host "fetched torch cache into $Out from $ghRepo $tag"

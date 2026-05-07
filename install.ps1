# Cipher Windows Installer
# SPDX-License-Identifier: AGPL-3.0-only

$ErrorActionPreference = "Stop"

Write-Host "Cipher - Encrypted. Private. Yours." -ForegroundColor Cyan
Write-Host ""

$Repo = "braxius-hq/cipher"
$InstallDir = "$env:LOCALAPPDATA\Programs\cipher"
$BinaryName = "cipher.exe"

$arch = [System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture
if ($arch -ne "X64") {
    Write-Host "Error: Unsupported architecture $arch. Only x64 is currently supported." -ForegroundColor Red
    exit 1
}

Write-Host "Fetching latest release..."
try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -UseBasicParsing
} catch {
    Write-Host "Error: Could not fetch release info. $_" -ForegroundColor Red
    exit 1
}

$asset = $release.assets | Where-Object { $_.name -match "windows-amd64\.exe$" } | Select-Object -First 1
if (-not $asset) {
    Write-Host "Error: No Windows binary found in release $($release.tag_name)." -ForegroundColor Red
    exit 1
}

$version = $release.tag_name -replace '^v', ''
$tempFile = Join-Path $env:TEMP "cipher-$version.exe"

Write-Host "Installing Cipher v$version (~100 MB)..."
try {
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $tempFile -UseBasicParsing
} catch {
    Write-Host "Error: Download failed. $_" -ForegroundColor Red
    if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
    exit 1
}

$bytes = [System.IO.File]::ReadAllBytes($tempFile)
if ($bytes.Length -lt 2 -or $bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) {
    Write-Host "Error: Downloaded file is not a valid Windows binary." -ForegroundColor Red
    Write-Host "This may be a temporary issue. Try again later." -ForegroundColor Red
    Remove-Item $tempFile -Force
    exit 1
}

New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
$target = Join-Path $InstallDir $BinaryName
Move-Item -Path $tempFile -Destination $target -Force

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$InstallDir", "User")
    $env:Path = "$env:Path;$InstallDir"
    Write-Host ""
    Write-Host "Added $InstallDir to your PATH." -ForegroundColor Yellow
    Write-Host "Restart your terminal for PATH changes to take effect." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Cipher v$version installed to $target" -ForegroundColor Green
Write-Host ""
Write-Host "Run 'cipher' in a new terminal to get started."

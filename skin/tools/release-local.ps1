param(
    [Parameter(Mandatory = $true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$SigningKeyPath,
    [Parameter(Mandatory = $true)][string]$ExpectedPublicKeyPayload,
    [string]$MinisignExe = ""
)

$ErrorActionPreference = "Stop"
$SkinRoot = Split-Path $PSScriptRoot -Parent
if (-not [IO.Path]::IsPathRooted($SigningKeyPath)) { $SigningKeyPath = [IO.Path]::GetFullPath($SigningKeyPath) }
if (-not $MinisignExe) {
    $command = Get-Command minisign -ErrorAction SilentlyContinue
    if ($command) { $MinisignExe = $command.Source }
}
if (-not (Test-Path -LiteralPath $SigningKeyPath -PathType Leaf)) { throw "Publisher private key not found: $SigningKeyPath" }
if (-not (Test-Path -LiteralPath $MinisignExe -PathType Leaf)) { throw "Minisign executable not found. Set -MinisignExe or add minisign to PATH." }

$manifest = Get-Content -LiteralPath (Join-Path $SkinRoot "manifest.json") -Raw -Encoding UTF8 | ConvertFrom-Json
if ([string]$manifest.version -ne $Version) { throw "manifest.json version $($manifest.version) does not match $Version" }
$outputDirectory = Join-Path $SkinRoot "dist"
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$archivePath = Join-Path $outputDirectory "$($manifest.id)-$Version.zip"
$derivedPublicKeyPath = Join-Path $outputDirectory "publisher-derived.pub"

try {
    Push-Location $SkinRoot
    try {
        & python tools/package.py --output $archivePath
        if ($LASTEXITCODE -ne 0) { throw "Skin package build failed with exit code $LASTEXITCODE" }
    } finally { Pop-Location }

    & $MinisignExe -R -s $SigningKeyPath -p $derivedPublicKeyPath
    if ($LASTEXITCODE -ne 0) { throw "Could not derive public key from the signing key" }
    $derivedPayload = (Get-Content -LiteralPath $derivedPublicKeyPath | Select-Object -Last 1).Trim()
    if ($derivedPayload -ne $ExpectedPublicKeyPayload.Trim()) { throw "Signing key does not match the publisher key in the Marketplace" }

    $signaturePath = "$archivePath.minisig"
    $checksumPath = "$archivePath.sha256"
    Remove-Item -LiteralPath $signaturePath, $checksumPath -Force -ErrorAction SilentlyContinue
    & $MinisignExe -S -s $SigningKeyPath -m $archivePath -x $signaturePath
    if ($LASTEXITCODE -ne 0) { throw "Minisign could not sign $archivePath" }
    $hash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    [IO.File]::WriteAllText($checksumPath, "$hash  $(Split-Path -Leaf $archivePath)`n", [System.Text.UTF8Encoding]::new($false))
    Write-Host "Signed skin package assets are ready in ${outputDirectory}:" -ForegroundColor Green
    Write-Host "  $archivePath"
    Write-Host "  $signaturePath"
    Write-Host "  $checksumPath"
} finally {
    Remove-Item -LiteralPath $derivedPublicKeyPath -Force -ErrorAction SilentlyContinue
}

param(
    [Parameter(Mandatory = $true)][string]$SigningKeyPath,
    [Parameter(Mandatory = $true)][string]$ExpectedPublicKeyPayload,
    [string]$MinisignExe = ""
)

$ErrorActionPreference = "Stop"
$TemplateRoot = Split-Path $PSScriptRoot -Parent
$Manifest = Get-Content -LiteralPath (Join-Path $TemplateRoot "manifest.json") -Raw -Encoding UTF8 | ConvertFrom-Json
if ([string]$Manifest.publisher -in @("", "your-publisher-id")) {
    throw "Replace manifest publisher with the id registered in SideWeave-Marketplace."
}
if ([string]$Manifest.key_id -in @("", "replace-with-key-id")) {
    throw "Replace manifest key_id with the active Marketplace publisher key id."
}
if (-not [IO.Path]::IsPathRooted($SigningKeyPath)) {
    $SigningKeyPath = [IO.Path]::GetFullPath($SigningKeyPath)
}
if (-not (Test-Path -LiteralPath $SigningKeyPath -PathType Leaf)) {
    throw "Publisher private key not found: $SigningKeyPath"
}
if (-not $MinisignExe) {
    $Command = Get-Command minisign -ErrorAction SilentlyContinue
    if ($Command) { $MinisignExe = $Command.Source }
}
if (-not (Test-Path -LiteralPath $MinisignExe -PathType Leaf)) {
    throw "Minisign executable not found. Set -MinisignExe or add minisign to PATH."
}
$KeyHeader = [IO.File]::ReadLines($SigningKeyPath) | Select-Object -First 1
if ([string]$KeyHeader -notmatch '^untrusted comment:.*secret key') {
    throw "Publisher key is not a complete Minisign secret-key file."
}

$OutputDirectory = Join-Path $TemplateRoot "dist"
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$DerivedPublicKeyPath = Join-Path $OutputDirectory "publisher-derived.pub"
$PackageScript = Join-Path $PSScriptRoot "package.ps1"
try {
    & $PackageScript -OutputDirectory $OutputDirectory
    if ($LASTEXITCODE -ne 0) { throw "Native plugin package build failed." }

    & $MinisignExe -R -s $SigningKeyPath -p $DerivedPublicKeyPath
    if ($LASTEXITCODE -ne 0) { throw "Could not derive public key from the signing key." }
    $DerivedPayload = (Get-Content -LiteralPath $DerivedPublicKeyPath | Select-Object -Last 1).Trim()
    if ($DerivedPayload -ne $ExpectedPublicKeyPayload.Trim()) {
        throw "Signing key does not match the publisher key recorded in the Marketplace."
    }

    $ArchivePath = Join-Path $OutputDirectory "$($Manifest.id)-$($Manifest.version).zip"
    $SignaturePath = "$ArchivePath.minisig"
    $ChecksumPath = "$ArchivePath.sha256"
    & $MinisignExe -S -s $SigningKeyPath -m $ArchivePath -x $SignaturePath
    if ($LASTEXITCODE -ne 0) { throw "Minisign could not sign $ArchivePath." }
    $Hash = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $ChecksumText = "$Hash  $(Split-Path -Leaf $ArchivePath)" + [Environment]::NewLine
    [IO.File]::WriteAllText($ChecksumPath, $ChecksumText, (New-Object Text.UTF8Encoding($false)))

    Write-Host "Signed Native plugin assets are ready in ${OutputDirectory}:" -ForegroundColor Green
    Write-Host "  $ArchivePath"
    Write-Host "  $SignaturePath"
    Write-Host "  $ChecksumPath"
} finally {
    Remove-Item -LiteralPath $DerivedPublicKeyPath -Force -ErrorAction SilentlyContinue
}

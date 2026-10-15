param(
    [string]$OutputDirectory = "dist"
)

$ErrorActionPreference = "Stop"
$TemplateRoot = Split-Path $PSScriptRoot -Parent
$ManifestPath = Join-Path $TemplateRoot "manifest.json"
$CargoManifestPath = Join-Path $TemplateRoot "Cargo.toml"
$Manifest = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$CargoText = Get-Content -LiteralPath $CargoManifestPath -Raw -Encoding UTF8

if ($env:OS -ne "Windows_NT") { throw "The Native DLL starter must be built on Windows." }
if ([string]$Manifest.id -notmatch '^[a-z0-9]+(?:[-_][a-z0-9]+)*$') { throw "manifest.json has an invalid plugin id." }
if ($Manifest.type -ne "native" -or $Manifest.runtime -ne "dynamic_library") {
    throw "The Native starter must use type=native and runtime=dynamic_library."
}
if ($Manifest.requires_trust -ne $true) { throw "Native package manifest must set requires_trust to true." }
if ([string]$Manifest.backend -ne "plugin.dll") { throw "This starter builds plugin.dll; keep backend set to plugin.dll." }
if ([string]$Manifest.ui.entry -ne "ui/index.html" -or [string]$Manifest.ui.assetRoot -ne "ui") {
    throw "The starter UI must use ui/index.html and assetRoot ui."
}

$PackageSection = [regex]::Match($CargoText, '(?ms)^\[package\]\s*(.*?)(?=^\[|\z)').Groups[1].Value
$VersionMatch = [regex]::Match($PackageSection, '(?m)^\s*version\s*=\s*"([^"]+)"')
if (-not $VersionMatch.Success) { throw "Could not read the Cargo package version." }
if ([string]$Manifest.version -ne $VersionMatch.Groups[1].Value) {
    throw "manifest version $($Manifest.version) must match Cargo.toml version $($VersionMatch.Groups[1].Value)."
}
if (-not (Test-Path -LiteralPath (Join-Path $TemplateRoot "ui\index.html") -PathType Leaf)) {
    throw "Native plugin UI entry is missing."
}
if (-not (Test-Path -LiteralPath (Join-Path $TemplateRoot "ui\icon.svg") -PathType Leaf)) {
    throw "Native plugin icon is missing."
}

if (-not [IO.Path]::IsPathRooted($OutputDirectory)) {
    $OutputDirectory = Join-Path $TemplateRoot $OutputDirectory
}
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$CargoArguments = @("build", "--manifest-path", $CargoManifestPath, "--release")
if (Test-Path -LiteralPath (Join-Path $TemplateRoot "Cargo.lock") -PathType Leaf) {
    $CargoArguments += "--locked"
}
Push-Location $TemplateRoot
try {
    & cargo @CargoArguments
    if ($LASTEXITCODE -ne 0) { throw "Cargo build failed with exit code $LASTEXITCODE." }
} finally {
    Pop-Location
}

$BackendPath = Join-Path $TemplateRoot "target\release\plugin.dll"
if (-not (Test-Path -LiteralPath $BackendPath -PathType Leaf)) {
    throw "Cargo did not produce the expected DLL: $BackendPath"
}

$ArchivePath = Join-Path $OutputDirectory "$($Manifest.id)-$($Manifest.version).zip"
$TempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
$StagePath = Join-Path $TempBase ("sideweave-native-$([Guid]::NewGuid().ToString('N'))")
$StageFullPath = [IO.Path]::GetFullPath($StagePath)
if (-not $StageFullPath.StartsWith($TempBase, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Temporary package directory is outside the system temp directory."
}

try {
    New-Item -ItemType Directory -Path (Join-Path $StagePath "ui") -Force | Out-Null
    Copy-Item -LiteralPath $ManifestPath -Destination (Join-Path $StagePath "manifest.json")
    Copy-Item -LiteralPath $BackendPath -Destination (Join-Path $StagePath "plugin.dll")
    Copy-Item -Path (Join-Path $TemplateRoot "ui\*") -Destination (Join-Path $StagePath "ui") -Recurse -Force
    Compress-Archive -Path (Join-Path $StagePath "*") -DestinationPath $ArchivePath -CompressionLevel Optimal -Force
} finally {
    if (Test-Path -LiteralPath $StageFullPath) {
        Remove-Item -LiteralPath $StageFullPath -Recurse -Force
    }
}

Write-Host "Created Native plugin package: $ArchivePath" -ForegroundColor Green

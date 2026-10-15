param([string]$Output = "")

$ErrorActionPreference = "Stop"
$SkinRoot = Split-Path $PSScriptRoot -Parent
Push-Location $SkinRoot
try {
    $arguments = @("tools/package.py")
    if ($Output) { $arguments += @("--output", $Output) }
    & python @arguments
    if ($LASTEXITCODE -ne 0) { throw "Skin package build failed with exit code $LASTEXITCODE." }
} finally {
    Pop-Location
}

param(
    [switch]$RemoveBuildCache
)

$ErrorActionPreference = "Stop"

$npmPrefix = (npm prefix -g).Trim()
$cmdPath = Join-Path $npmPrefix "freebuff.cmd"
$psPath = Join-Path $npmPrefix "freebuff.ps1"

foreach ($path in @($cmdPath, $psPath)) {
    $backup = "$path.baseline-backup"
    if (Test-Path -LiteralPath $backup) {
        Copy-Item -LiteralPath $backup -Destination $path -Force
        Remove-Item -LiteralPath $backup -Force
        Write-Host "Restored backup: $path"
    } elseif (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Force
        Write-Host "Removed: $path"
    }
}

if ($RemoveBuildCache) {
    $installRoot = "$env:LOCALAPPDATA\FreebuffBaselineWindows"
    if (Test-Path -LiteralPath $installRoot) {
        Remove-Item -LiteralPath $installRoot -Recurse -Force
        Write-Host "Removed build cache: $installRoot"
    }
}

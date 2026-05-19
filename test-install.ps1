$ErrorActionPreference = "Stop"

$commands = @("node", "npm", "git", "freebuff")
foreach ($command in $commands) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        throw "Missing command: $command"
    }
}

$version = freebuff --version
if (-not $version) {
    throw "freebuff --version returned empty output"
}

$help = (freebuff --help) -join "`n"
if ($help -notmatch "Freebuff") {
    throw "freebuff --help did not look like Freebuff output"
}

Write-Host "OK: freebuff baseline command works."

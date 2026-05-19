param(
    [string]$InstallRoot = "$env:LOCALAPPDATA\FreebuffBaselineWindows",
    [string]$CodebuffRepo = "https://github.com/CodebuffAI/codebuff.git",
    [string]$CodebuffRef = "main"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Refresh-Path {
    $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $user = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machine;$user"
}

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Ensure-WingetPackage {
    param(
        [string]$CommandName,
        [string]$PackageId
    )

    if (Test-Command $CommandName) {
        return
    }

    if (-not (Test-Command "winget")) {
        throw "$CommandName is required, and winget was not found. Install $PackageId manually, then rerun this installer."
    }

    Write-Step "Installing $PackageId"
    winget install $PackageId --accept-package-agreements --accept-source-agreements --silent
    Refresh-Path

    if (-not (Test-Command $CommandName)) {
        throw "$CommandName is still unavailable after installing $PackageId. Open a new terminal and rerun this installer."
    }
}

function Get-FreebuffLatestVersion {
    try {
        $version = npm view freebuff version 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($version)) {
            return $version.Trim()
        }
    } catch {
    }
    return "1.0.0"
}

function Patch-CodebuffBuildScript {
    param([string]$RepoDir)

    $buildScript = Join-Path $RepoDir "cli\scripts\build-binary.ts"
    if (-not (Test-Path -LiteralPath $buildScript)) {
        throw "Could not find Codebuff build script at $buildScript"
    }

    $content = [System.IO.File]::ReadAllText($buildScript)
    $pattern = @"
      if (process.platform === 'win32') {
        tarArgs.unshift('--force-local')
      }

"@

    if ($content.Contains($pattern)) {
        $content = $content.Replace($pattern, "")
        [System.IO.File]::WriteAllText($buildScript, $content)
        Write-Host "Patched unsupported Windows tar --force-local flag."
    } else {
        Write-Host "No tar --force-local patch needed."
    }
}

function Write-FreebuffShims {
    param(
        [string]$ExePath,
        [string]$NpmBin
    )

    if (-not (Test-Path -LiteralPath $ExePath)) {
        throw "Built executable not found: $ExePath"
    }

    New-Item -ItemType Directory -Path $NpmBin -Force | Out-Null

    $cmdShim = @"
@ECHO off
SETLOCAL
SET "NEXT_PUBLIC_CB_ENVIRONMENT=prod"
SET "NEXT_PUBLIC_CODEBUFF_APP_URL=https://www.codebuff.com"
SET "NEXT_PUBLIC_SUPPORT_EMAIL=support@codebuff.com"
SET "NEXT_PUBLIC_POSTHOG_API_KEY=phc_dummy_posthog_key"
SET "NEXT_PUBLIC_POSTHOG_HOST_URL=https://us.i.posthog.com"
SET "NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_dummy_publishable"
SET "NEXT_PUBLIC_STRIPE_CUSTOMER_PORTAL=https://billing.stripe.com/p/login/test_dummy"
SET "NEXT_PUBLIC_WEB_PORT=3000"
"$ExePath" %*
"@

    $psShim = @"
`$env:NEXT_PUBLIC_CB_ENVIRONMENT = 'prod'
`$env:NEXT_PUBLIC_CODEBUFF_APP_URL = 'https://www.codebuff.com'
`$env:NEXT_PUBLIC_SUPPORT_EMAIL = 'support@codebuff.com'
`$env:NEXT_PUBLIC_POSTHOG_API_KEY = 'phc_dummy_posthog_key'
`$env:NEXT_PUBLIC_POSTHOG_HOST_URL = 'https://us.i.posthog.com'
`$env:NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY = 'pk_test_dummy_publishable'
`$env:NEXT_PUBLIC_STRIPE_CUSTOMER_PORTAL = 'https://billing.stripe.com/p/login/test_dummy'
`$env:NEXT_PUBLIC_WEB_PORT = '3000'

& '$ExePath' @args
exit `$LASTEXITCODE
"@

    $cmdPath = Join-Path $NpmBin "freebuff.cmd"
    $psPath = Join-Path $NpmBin "freebuff.ps1"
    if (Test-Path -LiteralPath $cmdPath) {
        Copy-Item -LiteralPath $cmdPath -Destination "$cmdPath.baseline-backup" -Force
    }
    if (Test-Path -LiteralPath $psPath) {
        Copy-Item -LiteralPath $psPath -Destination "$psPath.baseline-backup" -Force
    }

    [System.IO.File]::WriteAllText($cmdPath, $cmdShim)
    [System.IO.File]::WriteAllText($psPath, $psShim)
}

Refresh-Path

Write-Step "Checking prerequisites"
Ensure-WingetPackage -CommandName "node" -PackageId "OpenJS.NodeJS.LTS"
Ensure-WingetPackage -CommandName "npm" -PackageId "OpenJS.NodeJS.LTS"
Ensure-WingetPackage -CommandName "git" -PackageId "Git.Git"

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
$toolsDir = Join-Path $InstallRoot "tools"
$repoDir = Join-Path $InstallRoot "codebuff"
New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null

Write-Step "Installing Bun Windows x64 baseline locally"
Push-Location $toolsDir
try {
    if (-not (Test-Path -LiteralPath (Join-Path $toolsDir "package.json"))) {
        npm init -y | Out-Null
    }
    npm install @oven/bun-windows-x64-baseline
} finally {
    Pop-Location
}

$bun = Join-Path $toolsDir "node_modules\@oven\bun-windows-x64-baseline\bin\bun.exe"
if (-not (Test-Path -LiteralPath $bun)) {
    throw "Bun baseline executable not found: $bun"
}

Write-Step "Verifying baseline Bun"
& $bun --version

Write-Step "Fetching official Codebuff source"
if (Test-Path -LiteralPath (Join-Path $repoDir ".git")) {
    Push-Location $repoDir
    try {
        git fetch origin
        git checkout $CodebuffRef
        git pull --ff-only origin $CodebuffRef
    } finally {
        Pop-Location
    }
} else {
    git clone $CodebuffRepo $repoDir
    Push-Location $repoDir
    try {
        git checkout $CodebuffRef
    } finally {
        Pop-Location
    }
}

Patch-CodebuffBuildScript -RepoDir $repoDir

Write-Step "Installing Codebuff dependencies"
Push-Location $repoDir
try {
    $env:Path = "$(Split-Path -Parent $bun);$env:Path"
    & $bun install
} finally {
    Pop-Location
}

$version = Get-FreebuffLatestVersion
Write-Step "Building Freebuff $version with bun-windows-x64-baseline"
Push-Location $repoDir
try {
    $env:Path = "$(Split-Path -Parent $bun);$env:Path"
    $env:OVERRIDE_TARGET = "bun-windows-x64-baseline"
    $env:OVERRIDE_PLATFORM = "win32"
    $env:OVERRIDE_ARCH = "x64"
    $env:NEXT_PUBLIC_CB_ENVIRONMENT = "prod"
    $env:NEXT_PUBLIC_CODEBUFF_APP_URL = "https://www.codebuff.com"
    $env:NEXT_PUBLIC_SUPPORT_EMAIL = "support@codebuff.com"
    $env:NEXT_PUBLIC_POSTHOG_API_KEY = "phc_dummy_posthog_key"
    $env:NEXT_PUBLIC_POSTHOG_HOST_URL = "https://us.i.posthog.com"
    $env:NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY = "pk_test_dummy_publishable"
    $env:NEXT_PUBLIC_STRIPE_CUSTOMER_PORTAL = "https://billing.stripe.com/p/login/test_dummy"
    $env:NEXT_PUBLIC_WEB_PORT = "3000"
    & $bun freebuff/cli/build.ts $version
} finally {
    Pop-Location
}

$exe = Join-Path $repoDir "cli\bin\freebuff.exe"
$npmPrefix = (npm prefix -g).Trim()
Write-Step "Installing freebuff command shims"
Write-FreebuffShims -ExePath $exe -NpmBin $npmPrefix

Refresh-Path
Write-Step "Verifying Freebuff"
freebuff --version
freebuff --help

Write-Host ""
Write-Host "Freebuff baseline install complete." -ForegroundColor Green
Write-Host "Open a new terminal and run: freebuff"

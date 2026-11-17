<#
.SYNOPSIS
    Build a distributable GET-KIOSK installer archive from Windows.

.DESCRIPTION
    Cross-compiles to x86_64-unknown-linux-musl and packages the result into
    release/kiosk-installer-<version>-linux-x86_64.zip plus the stable
    kiosk-installer-linux-x86_64.zip that start.sh downloads.

    No C toolchain is required: the crate tree has no C dependencies, so
    Rust's bundled rust-lld links the musl target directly and the result is a
    static ELF that runs on Debian 11, 12 and 13 without matching glibc.

.PARAMETER SkipBuild
    Package the binary already present in target/ without recompiling.

.EXAMPLE
    .\rework\build-release.ps1
#>
[CmdletBinding()]
param(
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'

$Here   = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root   = Split-Path -Parent $Here
$Target = if ($env:TARGET) { $env:TARGET } else { 'x86_64-unknown-linux-musl' }
$Out    = Join-Path $Here 'release'

function Write-Say($Message) { Write-Host $Message }

# --- version -------------------------------------------------------------
$CargoToml = Get-Content (Join-Path $Here 'Cargo.toml')
$Version = ($CargoToml | Select-String -Pattern '^version\s*=\s*"(.+)"' |
    Select-Object -First 1).Matches[0].Groups[1].Value
if (-not $Version) { throw 'cannot read version from Cargo.toml' }

$Name   = "kiosk-installer-$Version-linux-x86_64"
$Stable = 'kiosk-installer-linux-x86_64.zip'
$Stage  = Join-Path $Out $Name

Write-Say "target:  $Target"
Write-Say "version: $Version"
Write-Say "output:  $Out\$Stable"

# --- toolchain -----------------------------------------------------------
if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    throw 'cargo not found; install Rust from https://rustup.rs'
}

$installed = (& rustup target list --installed) -split "`r?`n"
if ($installed -notcontains $Target) {
    Write-Say "adding Rust target $Target"
    & rustup target add $Target
    if ($LASTEXITCODE -ne 0) { throw "cannot add $Target" }
}

if (-not $SkipBuild) {
    Write-Say 'compiling'
    # rust-lld ships with the Rust toolchain; no cc/zig needed for musl here.
    $env:RUSTFLAGS = '-C linker=rust-lld'
    & cargo build --release --target $Target --manifest-path (Join-Path $Here 'Cargo.toml')
    if ($LASTEXITCODE -ne 0) { throw "build failed for $Target" }
}

$Bin = Join-Path $Here "target\$Target\release\kiosk-installer.exe"
if (-not (Test-Path $Bin)) {
    $Bin = Join-Path $Here "target\$Target\release\kiosk-installer"
}
if (-not (Test-Path $Bin)) { throw "binary not found under target\$Target\release" }

# --- sanity: must be a Linux ELF ----------------------------------------
$magic = [System.IO.File]::ReadAllBytes($Bin)[0..3]
if ($magic[0] -ne 0x7F -or $magic[1] -ne 0x45 -or $magic[2] -ne 0x4C -or $magic[3] -ne 0x46) {
    throw "$Bin is not a Linux ELF; check the target triple"
}
Write-Say ('binary size: {0:N0} bytes (stripped static ELF)' -f (Get-Item $Bin).Length)

# --- stage --------------------------------------------------------------
if (Test-Path $Stage) { Remove-Item $Stage -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $Stage 'assets') -Force | Out-Null

Copy-Item $Bin (Join-Path $Stage 'kiosk-installer')
Get-ChildItem (Join-Path $Here 'assets') -File |
    Copy-Item -Destination (Join-Path $Stage 'assets')

Write-Say 'staging payload'
# Copy to an explicit `app\<name>` path: pointing Copy-Item at a missing
# directory renames the source instead of nesting it under app\.
$AppStage = Join-Path $Stage 'app'
New-Item -ItemType Directory -Path $AppStage -Force | Out-Null
foreach ($dir in 'printer', 'terminals', 'fiscal', 'sst') {
    $source = Join-Path $Root "app\$dir"
    if (-not (Test-Path $source)) { throw "missing $source" }
    Copy-Item $source (Join-Path $AppStage $dir) -Recurse -Force
}

@"
version=$Version
target=$Target
built=$((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))
"@ | Set-Content (Join-Path $Stage 'VERSION') -Encoding utf8

# --- zip ----------------------------------------------------------------
$VersionedZip = Join-Path $Out "$Name.zip"
$StableZip    = Join-Path $Out $Stable
foreach ($zip in $VersionedZip, $StableZip) {
    if (Test-Path $zip) { Remove-Item $zip -Force }
}

Compress-Archive -Path $Stage -DestinationPath $VersionedZip -CompressionLevel Optimal
Copy-Item $VersionedZip $StableZip

Write-Say ('archive: {0} ({1:N0} bytes)' -f $VersionedZip, (Get-Item $VersionedZip).Length)
Write-Say "stable:  $StableZip"
Write-Say 'upload both to the GitHub release; start.sh fetches the stable name'

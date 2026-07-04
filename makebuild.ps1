param(
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Directory where this PowerShell script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Source development JavaScript file located next to this script
$SourceFileName = "satisfaction.dev.js"
$SourceFile = Join-Path $ScriptDir $SourceFileName

# Root directory for versioned production builds
$VersionsRoot = Join-Path $ScriptDir "versions"

if (-not (Test-Path $SourceFile)) {
    throw "Source file not found: $SourceFile"
}

# Read the source JavaScript file
$Content = Get-Content -Path $SourceFile -Raw -Encoding UTF8

# Find version declaration, for example:
# const SF_PUBLIC_VERSION = "2.1.2.1229";
$VersionRegex = 'const\s+SF_PUBLIC_VERSION\s*=\s*["''](?<version>\d+(?:\.\d+)+)["'']\s*;'
$Match = [regex]::Match($Content, $VersionRegex)

if (-not $Match.Success) {
    throw "Version was not found. Expected something like: const SF_PUBLIC_VERSION = `"2.X.X.XXXX`";"
}

$Version = $Match.Groups["version"].Value

# Target directory for this exact version
$TargetDir = Join-Path $VersionsRoot $Version

# Final minified production file
$OutputFile = Join-Path $TargetDir "satisfaction.min.js"

Write-Host "Source file: $SourceFile"
Write-Host "Detected version: $Version"
Write-Host "Target directory: $TargetDir"
Write-Host "Output file: $OutputFile"

# Prevent accidental overwrite unless -Force is used
if ((Test-Path $OutputFile) -and (-not $Force)) {
    throw "Output file already exists: $OutputFile. Use -Force to overwrite it."
}

# Create version directory if it does not exist
New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

# Check if npx is available
$npx = Get-Command "npx" -ErrorAction SilentlyContinue

if (-not $npx) {
    throw "npx was not found. Please install Node.js first, then install Terser with: npm install --save-dev terser"
}

Write-Host "Minifying with Terser..."

# Run Terser to create the minified production file.
# unused=false keeps important declarations from being removed accidentally.
# reserved keeps SF_PUBLIC_VERSION from being renamed.
& npx terser $SourceFile `
    -c "unused=false" `
    -m "reserved=['SF_PUBLIC_VERSION']" `
    -o $OutputFile

if ($LASTEXITCODE -ne 0) {
    throw "Terser failed with exit code: $LASTEXITCODE"
}

if (-not (Test-Path $OutputFile)) {
    throw "Output file was not created: $OutputFile"
}

# Verify that the generated file still contains the detected version
$OutputContent = Get-Content -Path $OutputFile -Raw -Encoding UTF8

if ($OutputContent -notmatch [regex]::Escape($Version)) {
    throw "Generated file does not contain the expected version: $Version"
}

$SourceSize = (Get-Item $SourceFile).Length
$OutputSize = (Get-Item $OutputFile).Length

Write-Host ""
Write-Host "Done."
Write-Host "Version: $Version"
Write-Host "Created: $OutputFile"
Write-Host "Source size: $SourceSize bytes"
Write-Host "Output size: $OutputSize bytes"
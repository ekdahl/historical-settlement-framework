# Build script orchestrator for historical settlement framework
# Coordinates the build pipeline: validation → GeoJSON → HTML → tiles → publish

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Get paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommandPath
$stepsDir = Join-Path $scriptDir "steps"
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)

if ($Verbose) {
    Write-Host "Build Configuration:"
    Write-Host "  Repository root: $repoRoot"
    Write-Host "  Scripts directory: $scriptDir"
    Write-Host "  Steps directory: $stepsDir"
    Write-Host ""
}

Write-Host "Starting build pipeline..."
Write-Host ""

try {
    # Step 1: Generate GeoJSON
    Write-Host "Step 1/4: Generating GeoJSON..."
    & (Join-Path $stepsDir "generate-geojson.ps1") -RepoRoot $repoRoot -Verbose:$Verbose
    Write-Host ""

    # Step 2: Convert Markdown to HTML
    Write-Host "Step 2/4: Converting Markdown to HTML..."
    & (Join-Path $stepsDir "generate-html.ps1") -RepoRoot $repoRoot -Verbose:$Verbose
    Write-Host ""

    # Step 3: Generate tiles
    Write-Host "Step 3/4: Generating map tiles..."
    & (Join-Path $stepsDir "generate-tiles.ps1") -RepoRoot $repoRoot -Verbose:$Verbose
    Write-Host ""

    # Step 4: Copy files for publication
    Write-Host "Step 4/4: Copying files to publication directory..."
    & (Join-Path $stepsDir "copy-files.ps1") -RepoRoot $repoRoot -Verbose:$Verbose
    Write-Host ""

    Write-Host "[OK] Build complete!"
}
catch {
    Write-Host "[ERROR] Build failed: $_" -ForegroundColor Red
    exit 1
}

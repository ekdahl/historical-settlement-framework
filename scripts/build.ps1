# Build script orchestrator for historical settlement framework
# Coordinates the build pipeline: validation → GeoJSON → HTML → publish
# Note: Map tile generation is handled separately via generate-map-tiles.ps1

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Get paths
$scriptDir = $PSScriptRoot
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
    Write-Host "Step 1/3: Generating GeoJSON..."
    & (Join-Path $stepsDir "generate-geojson.ps1") -RepoRoot $repoRoot -Verbose:$Verbose
    Write-Host ""

    # Step 2: Convert Markdown to HTML
    Write-Host "Step 2/3: Converting Markdown to HTML..."
    $python = $null
    if (Get-Command py -ErrorAction SilentlyContinue) {
        $python = "py"
        $pythonArgs = @("-3")
    } elseif (Get-Command python -ErrorAction SilentlyContinue) {
        $python = "python"
        $pythonArgs = @()
    } else {
        throw "Python 3 is required to run generate-html.py"
    }

    $htmlScript = Join-Path $stepsDir "generate-html.py"
    $htmlArgs = @("--RepoRoot", $repoRoot.ToString())
    if ($Verbose) { $htmlArgs += "--Verbose" }
    & $python @pythonArgs $htmlScript @htmlArgs
    Write-Host ""

    # Step 3: Copy files for publication
    Write-Host "Step 3/3: Copying files to publication directory..."
    & (Join-Path $stepsDir "copy-files.ps1") -RepoRoot $repoRoot -Verbose:$Verbose
    Write-Host ""

    Write-Host "[OK] Build complete!"
    Write-Host ""
    Write-Host "Note: Map tiles are generated separately using:"
    Write-Host "  .\framework\scripts\generate-map-tiles.ps1"
}
catch {
    Write-Host "[ERROR] Build failed: $_" -ForegroundColor Red
    exit 1
}

# Copy framework and generated files to docs/ for publication
# Clears and rebuilds the root docs/ directory for GitHub Pages

param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),
    [switch]$Verbose
)

$frameworkDocs = Join-Path (Join-Path $repoRoot "framework") "docs"
$targetDocs = Join-Path $repoRoot "docs"

if ($Verbose) {
    Write-Host "Copying files to publication directory..."
    Write-Host "  Source: $frameworkDocs"
    Write-Host "  Target: $targetDocs"
}

# Step 1: Clear target docs directory
if (Test-Path $targetDocs) {
    Remove-Item -Path $targetDocs -Recurse -Force
    Write-Host "[OK] Cleared docs/"
} else {
    Write-Host "[INFO] docs/ directory does not exist yet"
}

# Step 2: Copy framework docs to target
Copy-Item -Path $frameworkDocs -Destination $targetDocs -Recurse -Force
Write-Host "[OK] Copied framework/docs/ to docs/"

# Step 3: Copy generated GeoJSON to docs/
$buildDir = Join-Path $repoRoot "build"
$geojsonSource = Join-Path $buildDir "places.geojson"
$geojsonDest = Join-Path $targetDocs "geojson"

if (Test-Path $geojsonSource) {
    if (-not (Test-Path $geojsonDest)) {
        New-Item -ItemType Directory -Path $geojsonDest -Force | Out-Null
    }
    Copy-Item -Path $geojsonSource -Destination (Join-Path $geojsonDest "places.geojson") -Force
    Write-Host "[OK] Copied places.geojson to docs/geojson/"
} else {
    Write-Host "[WARN] places.geojson not found in build/"
}

# Step 4: Copy generated place HTML to docs/places/
$generatedHtmlSource = Join-Path $buildDir "places"
$generatedHtmlDest = Join-Path $targetDocs "places"

if (Test-Path $generatedHtmlSource) {
    Copy-Item -Path $generatedHtmlSource -Destination $generatedHtmlDest -Recurse -Force
    Write-Host "[OK] Copied generated HTML to docs/places/"
} else {
    Write-Host "[WARN] build/places/ not found"
}

# Step 5: Copy config.json to docs/
$configSource = Join-Path $repoRoot "config.json"
if (Test-Path $configSource) {
    Copy-Item -Path $configSource -Destination (Join-Path $targetDocs "config.json") -Force
    Write-Host "[OK] Copied config.json to docs/"
} else {
    Write-Host "[WARN] config.json not found at $configSource"
}

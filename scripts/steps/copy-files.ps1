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

# Clear target docs directory
if (Test-Path $targetDocs) {
    Remove-Item -Path $targetDocs -Recurse -Force
    Write-Host "[OK] Cleared docs/"
} else {
    Write-Host "[INFO] docs/ directory does not exist yet"
}

# Copy framework docs to target
Copy-Item -Path $frameworkDocs -Destination $targetDocs -Recurse -Force
Write-Host "[OK] Copied framework/docs/ to docs/"

# Copy generated GeoJSON to docs/
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

# Copy generated place HTML to docs/places/
$generatedHtmlSource = Join-Path $buildDir "places"
$generatedHtmlDest = Join-Path $targetDocs "places"

if (Test-Path $generatedHtmlSource) {
    Copy-Item -Path $generatedHtmlSource -Destination $generatedHtmlDest -Recurse -Force
    Write-Host "[OK] Copied generated HTML to docs/places/"
} else {
    Write-Host "[WARN] build/places/ not found"
}

# Copy place image assets to docs/places/<place>/images/
$placeDataRoot = Join-Path (Join-Path $repoRoot "data") "places"
if (Test-Path $placeDataRoot) {
    foreach ($placeFolder in Get-ChildItem -Path $placeDataRoot -Directory) {
        $imagesSource = Join-Path $placeFolder.FullName "images"
        if (Test-Path $imagesSource) {
            $placeOutputDir = Join-Path $generatedHtmlDest $placeFolder.Name
            $imagesDest = Join-Path $placeOutputDir "images"

            if (-not (Test-Path $placeOutputDir)) {
                New-Item -ItemType Directory -Path $placeOutputDir -Force | Out-Null
            }
            if (-not (Test-Path $imagesDest)) {
                New-Item -ItemType Directory -Path $imagesDest -Force | Out-Null
            }

            Get-ChildItem -Path $imagesSource -File | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination $imagesDest -Force
            }

            Write-Host "[OK] Copied images for $($placeFolder.Name) to docs/places/$($placeFolder.Name)/images/"
        }
    }
} else {
    Write-Host "[INFO] data/places/ not found; no place images to copy"
}

# Copy generated map tiles to docs/tiles/
$generatedTilesSource = Join-Path $buildDir "tiles"
$generatedTilesDest = Join-Path $targetDocs "tiles"

if (Test-Path $generatedTilesSource) {
    Copy-Item -Path $generatedTilesSource -Destination $generatedTilesDest -Recurse -Force
    Write-Host "[OK] Copied generated tiles to docs/tiles/"
} else {
    Write-Host "[INFO] build/tiles/ not found (skip tiles copy)"
}

# Copy config.json to docs/
$configSource = Join-Path $repoRoot "config.json"
if (Test-Path $configSource) {
    Copy-Item -Path $configSource -Destination (Join-Path $targetDocs "config.json") -Force
    Write-Host "[OK] Copied config.json to docs/"
} else {
    Write-Host "[WARN] config.json not found at $configSource"
}

# Copy favicon.svg to docs/
$faviconSource = Join-Path $repoRoot "favicon.svg"
if (Test-Path $faviconSource) {
    Copy-Item -Path $faviconSource -Destination (Join-Path $targetDocs "favicon.svg") -Force
    Write-Host "[OK] Copied favicon.svg to docs/"
} else {
    Write-Host "[WARN] favicon.svg not found at $faviconSource"
}

# Copy style.css to docs/
$styleSource = Join-Path $repoRoot "style.css"
if (Test-Path $styleSource) {
    Copy-Item -Path $styleSource -Destination (Join-Path $targetDocs "/css/style.css") -Force
    Write-Host "[OK] Copied style.css to docs/css/"
} else {
    Write-Host "[WARN] style.css not found at $styleSource"
}

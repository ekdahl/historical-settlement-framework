# Generate GeoJSON from place metadata
# Reads metadata.json files from data/places/ and generates GeoJSON

param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),
    [switch]$Verbose
)

$dataPlaces = Join-Path $repoRoot "data" "places"
$outputDir = Join-Path $repoRoot "build"

if ($Verbose) {
    Write-Host "Generating GeoJSON..."
    Write-Host "  Source: $dataPlaces"
    Write-Host "  Output: $outputDir"
}

if (-not (Test-Path $dataPlaces)) {
    Write-Host "⚠ data/places/ not found"
    return
}

# Create output directory if it doesn't exist
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# TODO: Implement GeoJSON generation from metadata.json files
Write-Host "✓ GeoJSON generation stub"

# Convert Markdown (text.md) to HTML
# Processes text.md files from data/places/ and generates HTML files

param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),
    [switch]$Verbose
)

$dataPlaces = Join-Path $repoRoot "data" "places"
$outputDir = Join-Path $repoRoot "build"

if ($Verbose) {
    Write-Host "Converting Markdown to HTML..."
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

# TODO: Implement Markdown to HTML conversion
# Could use a tool like pandoc or a custom converter
Write-Host "✓ Markdown to HTML conversion stub"

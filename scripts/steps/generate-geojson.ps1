# Generate GeoJSON from place metadata
# Reads metadata.json files from data/places/ and generates GeoJSON

param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),
    [switch]$Verbose
)

$dataPlaces = Join-Path (Join-Path $repoRoot "data") "places"
$outputDir = Join-Path $repoRoot "build"

if ($Verbose) {
    Write-Host "Generating GeoJSON..."
    Write-Host "  Source: $dataPlaces"
    Write-Host "  Output: $outputDir"
}

if (-not (Test-Path $dataPlaces)) {
    Write-Host "[WARN] data/places/ not found"
    return
}

# Create output directory if it doesn't exist
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Initialize GeoJSON FeatureCollection
$geojson = @{
    type = "FeatureCollection"
    features = @()
}

# Process each place folder
$placeFolders = Get-ChildItem -Path $dataPlaces -Directory
$placeCount = 0

foreach ($placeFolder in $placeFolders) {
    $metadataPath = Join-Path $placeFolder.FullName "metadata.json"
    
    if (Test-Path $metadataPath) {
        try {
            $metadata = Get-Content -Path $metadataPath -Raw | ConvertFrom-Json
            
            # Process each location (places) in the place
            if ($metadata.places -and $metadata.places.Count -gt 0) {
                foreach ($place in $metadata.places) {
                    $feature = @{
                        type = "Feature"
                        geometry = @{
                            type = "Point"
                            coordinates = @($place.lon, $place.lat)  # GeoJSON uses [lon, lat] and metadata fields are standard
                        }
                        properties = @{
                            id = $metadata.id
                            namn = $metadata.names[0]  # Use first name from array
                            typ = $metadata.type
                            fran = $place.from
                            till = $place.to
                        }
                    }
                    $geojson.features += $feature
                }
                $placeCount++
                
                if ($Verbose) {
                    Write-Host "  [OK] Processed: $($metadata.names[0]) ($($metadata.places.Count) location(s))"
                }
            }
        }
        catch {
            Write-Host "[WARN] Error processing $($placeFolder.Name): $_"
        }
    }
}

# Write GeoJSON to file
$outputFile = Join-Path $outputDir "places.geojson"
$geojson | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "[OK] GeoJSON generation complete ($placeCount places, $($geojson.features.Count) total features)"

# Generate web tiles from historical map data
# Standalone script for map tile generation (not part of main build pipeline)
# Downloads source maps to build/maps/ (cached for reuse)
# Generates web tiles to docs/tiles/map_name/
# Requires: GDAL tools (gdalbuildvrt, gdalwarp, gdal2tiles.py)

param(
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$MapName = "ekonomiska_kartan",
    [switch]$Force,  # Force re-download even if files exist
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Setup paths
$dataDir = Join-Path $repoRoot "data"
$buildDir = Join-Path $repoRoot "build"
$mapsDir = Join-Path $buildDir "maps"
$docsDir = Join-Path $repoRoot "docs"
$tilesDir = Join-Path $docsDir "tiles"

$mapDataDir = Join-Path $dataDir "maps" $MapName
$mapBuildDir = Join-Path $mapsDir $MapName
$mapTilesDir = Join-Path $tilesDir $MapName

# Verify tile-build.json exists
$tileConfigPath = Join-Path $mapDataDir "tile-build.json"
if (-not (Test-Path $tileConfigPath)) {
    Write-Host "[ERROR] tile-build.json not found at: $tileConfigPath"
    exit 1
}

$tileConfig = Get-Content -Path $tileConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

if ($Verbose) {
    Write-Host "Map Tile Generation Configuration:"
    Write-Host "  Repository root: $repoRoot"
    Write-Host "  Map name: $MapName"
    Write-Host "  Build directory: $mapBuildDir"
    Write-Host "  Output tiles: $mapTilesDir"
    Write-Host "  Source files: $($tileConfig.sources.Count) files to download"
    Write-Host ""
}

# Create directories
if (-not (Test-Path $mapBuildDir)) {
    New-Item -ItemType Directory -Path $mapBuildDir -Force | Out-Null
    if ($Verbose) { Write-Host "[OK] Created build directory: $mapBuildDir" }
}

if (-not (Test-Path $mapTilesDir)) {
    New-Item -ItemType Directory -Path $mapTilesDir -Force | Out-Null
    if ($Verbose) { Write-Host "[OK] Created tiles directory: $mapTilesDir" }
}

# Download source files
Write-Host "Step 1/3: Downloading source files..."
$downloadedCount = 0
$skippedCount = 0

foreach ($source in $tileConfig.sources) {
    $fileName = Split-Path -Leaf $source
    $targetPath = Join-Path $mapBuildDir $fileName
    
    if ((Test-Path $targetPath) -and -not $Force) {
        $skippedCount++
        if ($Verbose) { Write-Host "  [SKIP] $fileName (already exists)" }
    } else {
        try {
            if ($Verbose) { Write-Host "  [DL]   $fileName" }
            (New-Object System.Net.WebClient).DownloadFile($source, $targetPath)
            $downloadedCount++
        }
        catch {
            Write-Host "[WARN] Failed to download $fileName`: $_"
        }
    }
}

Write-Host "[OK] Downloaded $downloadedCount files, skipped $skippedCount (cached)"
Write-Host ""

# Verify required files exist
$tifFiles = @(Get-ChildItem -Path $mapBuildDir -Filter "*.tif" -ErrorAction SilentlyContinue)
if ($tifFiles.Count -eq 0) {
    Write-Host "[ERROR] No .tif files found in $mapBuildDir"
    exit 1
}

if ($Verbose) { Write-Host "Found $($tifFiles.Count) .tif files to process" }

# Build VRT (Virtual Dataset)
Write-Host "Step 2/3: Processing with GDAL..."
Push-Location $mapBuildDir

try {
    # Command 1: Build VRT from TIF files
    Write-Host "  Building mosaic VRT..."
    $cmd = "gdalbuildvrt"
    $args = @("mosaic.vrt", "*.tif")
    if ($Verbose) { Write-Host "    Running: $cmd $($args -join ' ')" }
    
    & $cmd @args
    if ($LASTEXITCODE -ne 0) {
        throw "gdalbuildvrt failed with exit code $LASTEXITCODE"
    }
    
    # Command 2: Reproject to Web Mercator (EPSG:3857)
    Write-Host "  Reprojecting to Web Mercator..."
    $cmd = "gdalwarp"
    $args = @("-s_srs", "EPSG:3021", "-t_srs", "EPSG:3857", "-of", "VRT", "mosaic.vrt", "mosaic_3857.vrt")
    if ($Verbose) { Write-Host "    Running: $cmd $($args -join ' ')" }
    
    & $cmd @args
    if ($LASTEXITCODE -ne 0) {
        throw "gdalwarp failed with exit code $LASTEXITCODE"
    }
    
    # Command 3: Generate web tiles
    Write-Host "  Generating web tiles (this may take a while)..."
    $cmd = "gdal2tiles.py"
    $args = @("--xyz", "--tiledriver=WEBP", "--webp-quality=85", "mosaic_3857.vrt", "tiles")
    if ($Verbose) { Write-Host "    Running: $cmd $($args -join ' ')" }
    
    # Python script execution (may be 'gdal2tiles.py' or 'gdal2tiles')
    py -3 -m osgeo_utils.samples.gdal2tiles @args
    if ($LASTEXITCODE -ne 0) {
        throw "gdal2tiles failed with exit code $LASTEXITCODE"
    }
    
    Write-Host "[OK] GDAL processing complete"
}
catch {
    Write-Host "[ERROR] GDAL processing failed: $_"
    exit 1
}
finally {
    Pop-Location
}

# Copy tiles to docs/tiles/
Write-Host "Step 3/3: Copying tiles to output directory..."
$sourceTiles = Join-Path $mapBuildDir "tiles"
if (Test-Path $sourceTiles) {
    # Remove existing tiles and copy new ones
    if (Test-Path $mapTilesDir) {
        Remove-Item -Path $mapTilesDir -Recurse -Force
    }
    Copy-Item -Path $sourceTiles -Destination $mapTilesDir -Recurse
    Write-Host "[OK] Tiles copied to: $mapTilesDir"
} else {
    Write-Host "[WARN] Tiles directory not found at: $sourceTiles"
}

Write-Host ""
Write-Host "[OK] Map tile generation complete!"
Write-Host "    Tiles location: $mapTilesDir"

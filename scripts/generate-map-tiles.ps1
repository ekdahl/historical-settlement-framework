# Generate web tiles from historical map data
# Standalone script for map tile generation (not part of main build pipeline)
# Downloads source maps to build/maps/ (cached for reuse)
# Stages generated web tiles to build/tiles/map_name/
# Requires: GDAL tools (gdalbuildvrt, gdalwarp, gdal2tiles.py)

param(
    [string]$MapName,
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [switch]$Force,  # Force re-download even if files exist
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Setup paths
$dataDir = Join-Path $repoRoot "data"
$buildDir = Join-Path $repoRoot "build"
$mapsDir = Join-Path $buildDir "maps"
$tilesBuildDir = Join-Path $buildDir "tiles"
$dataMapsDir = Join-Path $dataDir "maps"

# Auto-detect MapName if not provided
if (-not $MapName) {
    $availableMaps = @(Get-ChildItem -Path $dataMapsDir -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    
    if ($availableMaps.Count -eq 0) {
        Write-Host "[ERROR] No maps found in: $dataMapsDir"
        exit 1
    }
    elseif ($availableMaps.Count -eq 1) {
        $MapName = $availableMaps[0]
        Write-Host "No map specified. Using available map: $MapName"
    }
    else {
        Write-Host "[ERROR] Multiple maps found. Please specify which one to use:"
        foreach ($map in $availableMaps) {
            Write-Host "  .\generate-map-tiles.ps1 $map"
        }
        exit 1
    }
}

$mapDataDir = Join-Path $dataMapsDir $MapName
$mapBuildDir = Join-Path $mapsDir $MapName
$mapTilesBuildDir = Join-Path $tilesBuildDir $MapName

# Verify tile-build.json exists
$tileConfigPath = Join-Path $mapDataDir "tile-build.json"
if (-not (Test-Path $tileConfigPath)) {
    Write-Host "[ERROR] tile-build.json not found at: $tileConfigPath"
    exit 1
}

$tileConfig = Get-Content -Path $tileConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

# Folder (inside map build dir) where tileGenerationCommands write generated tiles.
# Can be overridden per map in tile-build.json via "generatedTilesFolder".
$generatedTilesFolder = "tiles"
if ($tileConfig.PSObject.Properties.Name -contains "generatedTilesFolder" -and $tileConfig.generatedTilesFolder) {
    $generatedTilesFolder = $tileConfig.generatedTilesFolder
}

if ($Verbose) {
    Write-Host "Map Tile Generation Configuration:"
    Write-Host "  Repository root: $repoRoot"
    Write-Host "  Map name: $MapName"
    Write-Host "  Build directory: $mapBuildDir"
    Write-Host "  Generated tiles folder: $generatedTilesFolder"
    Write-Host "  Staged tiles: $mapTilesBuildDir"
    Write-Host "  Source files: $($tileConfig.sources.Count) files to download"
    Write-Host ""
}

# Create directories
if (-not (Test-Path $mapBuildDir)) {
    New-Item -ItemType Directory -Path $mapBuildDir -Force | Out-Null
    if ($Verbose) { Write-Host "[OK] Created build directory: $mapBuildDir" }
}

if (-not (Test-Path $mapTilesBuildDir)) {
    New-Item -ItemType Directory -Path $mapTilesBuildDir -Force | Out-Null
    if ($Verbose) { Write-Host "[OK] Created tiles directory: $mapTilesBuildDir" }
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

            $isRemoteSource = $false
            if ($source -match '^(https?|ftp)://') {
                $isRemoteSource = $true
            }

            if ($isRemoteSource) {
                (New-Object System.Net.WebClient).DownloadFile($source, $targetPath)
            }
            else {
                if ($source -match '^file://') {
                    $sourcePath = [System.Uri]::new($source).LocalPath
                }
                elseif ([System.IO.Path]::IsPathRooted($source)) {
                    $sourcePath = $source
                }
                else {
                    $sourcePath = Join-Path $mapDataDir $source
                }

                if (-not (Test-Path $sourcePath)) {
                    throw "Local source file not found: $sourcePath"
                }

                Copy-Item -Path $sourcePath -Destination $targetPath -Force
            }

            $downloadedCount++
        }
        catch {
            Write-Host "[WARN] Failed to retrieve $fileName`: $_"
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

# Execute tile generation commands
Write-Host "Step 2/3: Processing with GDAL..."
Push-Location $mapBuildDir

try {
    if (-not $tileConfig.tileGenerationCommands -or $tileConfig.tileGenerationCommands.Count -eq 0) {
        throw "No tileGenerationCommands defined in tile-build.json"
    }
    
    $commandIndex = 1
    $lastResolvedCommand = $null
    foreach ($command in $tileConfig.tileGenerationCommands) {
        $resolvedCommand = $command
        $resolvedCommand = $resolvedCommand.Replace("{{mapBuildDir}}", $mapBuildDir)
        $resolvedCommand = $resolvedCommand.Replace("{{generatedTilesFolder}}", $generatedTilesFolder)
        $lastResolvedCommand = $resolvedCommand

        Write-Host "  Command $commandIndex/$($tileConfig.tileGenerationCommands.Count): $resolvedCommand"
        if ($Verbose) { Write-Host "    Working directory: $mapBuildDir" }
        
        # Execute via cmd.exe so external command failures propagate as a non-zero exit code.
        & cmd.exe /c $resolvedCommand
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed with exit code $LASTEXITCODE"
        }
        
        $commandIndex++
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

# Stage tiles to build/tiles/
Write-Host "Step 3/3: Staging tiles to build output directory..."
$sourceTiles = Join-Path $mapBuildDir $generatedTilesFolder

if (-not (Test-Path $sourceTiles) -and $lastResolvedCommand) {
    # Fallback 1: infer output directory from last token in last executed command.
    $lastToken = ($lastResolvedCommand.Trim() -split "\s+")[-1].Trim('"')
    if ($lastToken -and -not $lastToken.StartsWith("-")) {
        $candidate = if ([System.IO.Path]::IsPathRooted($lastToken)) {
            $lastToken
        } else {
            Join-Path $mapBuildDir $lastToken
        }
        if (Test-Path $candidate) {
            $sourceTiles = $candidate
        }
    }
}

if (-not (Test-Path $sourceTiles)) {
    # Fallback 2: detect a tile-like directory (contains at least one numeric zoom folder).
    $tileLikeDir = Get-ChildItem -Path $mapBuildDir -Directory -ErrorAction SilentlyContinue |
        Where-Object {
            @(Get-ChildItem -Path $_.FullName -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match '^[0-9]+$' }).Count -gt 0
        } |
        Select-Object -First 1
    if ($tileLikeDir) {
        $sourceTiles = $tileLikeDir.FullName
    }
}

if (Test-Path $sourceTiles) {
    # Remove existing staged tiles for this map and copy new ones
    if (Test-Path $mapTilesBuildDir) {
        Remove-Item -Path $mapTilesBuildDir -Recurse -Force
    }
    Copy-Item -Path $sourceTiles -Destination $mapTilesBuildDir -Recurse
    Write-Host "[OK] Tiles staged to: $mapTilesBuildDir"
} else {
    Write-Host "[ERROR] Tiles directory not found at: $sourceTiles" -ForegroundColor Red
    Write-Host "[ERROR] Check the last tileGenerationCommands output path in tile-build.json" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[OK] Map tile generation complete!"
Write-Host "    Staged tiles location: $mapTilesBuildDir"

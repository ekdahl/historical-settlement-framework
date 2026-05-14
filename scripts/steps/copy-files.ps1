# Copy framework and generated files to docs/ for publication
# Clears and rebuilds the root docs/ directory for GitHub Pages

param(
    [string]$RepoRoot = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))),
    [switch]$Verbose
)

$frameworkDocs = Join-Path $repoRoot "framework" "docs"
$targetDocs = Join-Path $repoRoot "docs"

if ($Verbose) {
    Write-Host "Copying files to publication directory..."
    Write-Host "  Source: $frameworkDocs"
    Write-Host "  Target: $targetDocs"
}

# Step 1: Clear target docs directory
if (Test-Path $targetDocs) {
    Remove-Item -Path $targetDocs -Recurse -Force
    Write-Host "✓ Cleared docs/"
} else {
    Write-Host "ℹ docs/ directory does not exist yet"
}

# Step 2: Copy framework docs to target
Copy-Item -Path $frameworkDocs -Destination $targetDocs -Recurse -Force
Write-Host "✓ Copied framework/docs/ to docs/"

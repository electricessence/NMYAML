# NMYAML Pack Script (PowerShell)
# Creates NuGet package for the Core library

param(
    [string]$Configuration = "Release"
)

Write-Host "=== NMYAML Pack Script ===" -ForegroundColor Cyan
Write-Host "Creating NuGet package for NMYAML.Core..." -ForegroundColor Yellow
Write-Host ""

try {
    # Pack the Core library
    Write-Host "Packing NMYAML.Core..." -ForegroundColor Green
    dotnet pack Core/NMYAML.Core/NMYAML.Core.csproj --configuration $Configuration --no-restore
    if ($LASTEXITCODE -ne 0) { throw "Pack failed" }

    # Show package info
    Write-Host ""
    Write-Host "📦 Package created:" -ForegroundColor Green
    Get-ChildItem Core/NMYAML.Core/bin/$Configuration/*.nupkg | Format-Table Name, Length, LastWriteTime

    Write-Host ""
    Write-Host "✅ Packaging completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "❌ Pack failed: $_" -ForegroundColor Red
    exit 1
}

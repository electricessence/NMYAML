# NMYAML Build Script (PowerShell)
# Builds the entire solution in Release configuration

param(
    [string]$Configuration = "Release"
)

Write-Host "=== NMYAML Build Script ===" -ForegroundColor Cyan
Write-Host "Building NMYAML solution in $Configuration configuration..." -ForegroundColor Yellow
Write-Host ""

try {
    # Restore dependencies
    Write-Host "Step 1: Restoring dependencies..." -ForegroundColor Green
    dotnet restore
    if ($LASTEXITCODE -ne 0) { throw "Restore failed" }

    # Build solution
    Write-Host "Step 2: Building solution..." -ForegroundColor Green
    dotnet build --configuration $Configuration --no-restore
    if ($LASTEXITCODE -ne 0) { throw "Build failed" }

    # Run tests
    Write-Host "Step 3: Running tests..." -ForegroundColor Green
    dotnet test --configuration $Configuration --no-build --verbosity normal
    if ($LASTEXITCODE -ne 0) { throw "Tests failed" }

    Write-Host ""
    Write-Host "✅ Build completed successfully!" -ForegroundColor Green
    Write-Host "Ready for packaging and deployment." -ForegroundColor Yellow
}
catch {
    Write-Host "❌ Build failed: $_" -ForegroundColor Red
    exit 1
}

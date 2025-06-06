# NMYAML Full Pipeline Script (PowerShell)
# Runs the complete build, test, pack, and demo pipeline

param(
    [string]$Configuration = "Release",
    [switch]$SkipTests,
    [switch]$SkipDemo
)

Write-Host "=== NMYAML Full Pipeline ===" -ForegroundColor Cyan
Write-Host "Running complete build pipeline..." -ForegroundColor Yellow
Write-Host ""

$ErrorActionPreference = "Stop"

try {
    # Step 1: Build and Test
    Write-Host "🔨 Phase 1: Build and Test" -ForegroundColor Magenta
    Write-Host "=" * 50 -ForegroundColor Gray
    
    & "$PSScriptRoot\build.ps1" -Configuration $Configuration
    if ($LASTEXITCODE -ne 0) { throw "Build phase failed" }

    # Step 2: Pack NuGet Package
    Write-Host ""
    Write-Host "📦 Phase 2: Package Creation" -ForegroundColor Magenta
    Write-Host "=" * 50 -ForegroundColor Gray
    
    & "$PSScriptRoot\pack.ps1" -Configuration $Configuration
    if ($LASTEXITCODE -ne 0) { throw "Pack phase failed" }

    # Step 3: Test CLI
    if (!$SkipTests) {
        Write-Host ""
        Write-Host "🧪 Phase 3: CLI Testing" -ForegroundColor Magenta
        Write-Host "=" * 50 -ForegroundColor Gray
        
        & "$PSScriptRoot\test-cli.ps1" -Configuration $Configuration
        if ($LASTEXITCODE -ne 0) { throw "CLI test phase failed" }
    }

    # Step 4: Dogfooding Demo
    if (!$SkipDemo) {
        Write-Host ""
        Write-Host "🚀 Phase 4: Dogfooding Demo" -ForegroundColor Magenta
        Write-Host "=" * 50 -ForegroundColor Gray
        
        & "$PSScriptRoot\demo.ps1" -Configuration $Configuration
        if ($LASTEXITCODE -ne 0) { throw "Demo phase failed" }
    }

    # Summary
    Write-Host ""
    Write-Host "🎉 PIPELINE COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host "✅ Build: Complete" -ForegroundColor Green
    Write-Host "✅ Tests: $(if ($SkipTests) { 'Skipped' } else { 'Passed' })" -ForegroundColor $(if ($SkipTests) { 'Yellow' } else { 'Green' })
    Write-Host "✅ Package: Created" -ForegroundColor Green
    Write-Host "✅ CLI Test: $(if ($SkipTests) { 'Skipped' } else { 'Passed' })" -ForegroundColor $(if ($SkipTests) { 'Yellow' } else { 'Green' })
    Write-Host "✅ Demo: $(if ($SkipDemo) { 'Skipped' } else { 'Complete' })" -ForegroundColor $(if ($SkipDemo) { 'Yellow' } else { 'Green' })
    
    Write-Host ""
    Write-Host "📂 Generated Files:" -ForegroundColor Yellow
    if (Test-Path "Core/NMYAML.Core/bin/$Configuration/*.nupkg") {
        Write-Host "  • NuGet Package: $(Get-ChildItem "Core/NMYAML.Core/bin/$Configuration/*.nupkg" | Select-Object -First 1 -ExpandProperty Name)" -ForegroundColor Gray
    }
    if (Test-Path ".github/workflows/build-and-publish.yml") {
        Write-Host "  • GitHub Workflow: .github/workflows/build-and-publish.yml" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "🚀 Ready for production deployment!" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "❌ PIPELINE FAILED: $_" -ForegroundColor Red
    Write-Host "Check the error messages above for details." -ForegroundColor Yellow
    exit 1
}

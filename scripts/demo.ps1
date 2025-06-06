# NMYAML Demo Script (PowerShell)
# Demonstrates the dogfooding capabilities by transforming the XML workflow to YAML

param(
    [string]$Configuration = "Release"
)

Write-Host "=== NMYAML Dogfooding Demo ===" -ForegroundColor Cyan
Write-Host "Demonstrating XML to YAML transformation..." -ForegroundColor Yellow
Write-Host ""

try {
    # Ensure CLI is built
    Write-Host "Step 1: Building CLI tool..." -ForegroundColor Green
    dotnet build CLI/NMYAML.CLI --configuration $Configuration
    if ($LASTEXITCODE -ne 0) { throw "CLI build failed" }

    # Create .github/workflows directory if it doesn't exist
    if (!(Test-Path ".github/workflows")) {
        New-Item -ItemType Directory -Path ".github/workflows" -Force | Out-Null
    }

    # Transform XML workflow to YAML using the correct XSLT
    Write-Host "Step 2: Transforming XML workflow to YAML..." -ForegroundColor Green
    Push-Location CLI/NMYAML.CLI
    
    dotnet run --configuration $Configuration -- transform `
        "../../workflows/build-and-publish.xml" `
        "../../.github/workflows/build-and-publish.yml" `
        --xslt "../../xslt/github-actions-transform.xslt"
    if ($LASTEXITCODE -ne 0) { throw "Transform failed" }

    Write-Host ""
    Write-Host "Step 3: Validating generated workflow..." -ForegroundColor Green
    dotnet run --configuration $Configuration -- validate `
        "../../.github/workflows/build-and-publish.yml"
    if ($LASTEXITCODE -ne 0) { throw "Validation failed" }

    Pop-Location

    Write-Host ""
    Write-Host "Generated YAML workflow:" -ForegroundColor Green
    Write-Host "========================" -ForegroundColor Yellow
    Get-Content ".github/workflows/build-and-publish.yml" | Select-Object -First 30
    if ((Get-Content ".github/workflows/build-and-publish.yml").Count -gt 30) {
        Write-Host "... (truncated, see full file at .github/workflows/build-and-publish.yml)" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "✅ Dogfooding demo completed successfully!" -ForegroundColor Green
    Write-Host "🚀 Generated workflow is ready for GitHub Actions!" -ForegroundColor Yellow
}
catch {
    if (Get-Location | Where-Object { $_.Path -like "*CLI*" }) { Pop-Location }
    Write-Host "❌ Demo failed: $_" -ForegroundColor Red
    exit 1
}

# NMYAML CLI Test Script (PowerShell)
# Tests the CLI tool functionality with sample files

param(
    [string]$Configuration = "Release"
)

Write-Host "=== NMYAML CLI Test Script ===" -ForegroundColor Cyan
Write-Host "Testing CLI tool functionality..." -ForegroundColor Yellow
Write-Host ""

try {
    Push-Location CLI/NMYAML.CLI

    Write-Host "Step 1: Showing CLI help..." -ForegroundColor Green
    dotnet run -- --help
    if ($LASTEXITCODE -ne 0) { throw "CLI help failed" }

    Write-Host ""
    Write-Host "Step 2: Testing transformation with sample workflow..." -ForegroundColor Green
    dotnet run -- transform `
        "../../samples/github-workflow.xml" `
        "test-workflow.yml" `
        --xslt "../../xslt/github-actions-transform.xslt"
    if ($LASTEXITCODE -ne 0) { throw "Transform failed" }

    Write-Host ""
    Write-Host "Step 3: Validating transformed output..." -ForegroundColor Green
    dotnet run -- validate "test-workflow.yml"
    if ($LASTEXITCODE -ne 0) { throw "Validation failed" }

    Write-Host ""
    Write-Host "Generated test workflow preview:" -ForegroundColor Green
    Write-Host "===============================" -ForegroundColor Yellow
    Get-Content "test-workflow.yml" | Select-Object -First 20

    Pop-Location

    Write-Host ""
    Write-Host "✅ CLI test completed successfully!" -ForegroundColor Green
}
catch {
    if (Get-Location | Where-Object { $_.Path -like "*CLI*" }) { Pop-Location }
    Write-Host "❌ CLI test failed: $_" -ForegroundColor Red
    exit 1
}

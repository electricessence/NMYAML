# Test script to verify module re-import behavior
Write-Host "Testing module re-import behavior..." -ForegroundColor Yellow

$terminalModulePath = ".\scripts\modules\TerminalOutput.psm1"

# Test multiple imports without -Force
Write-Host "`nTest: Multiple imports without -Force"
try {
    Import-Module $terminalModulePath -ErrorAction Stop
    Write-InfoMessage "First import successful"
    
    Import-Module $terminalModulePath -ErrorAction Stop
    Write-InfoMessage "Second import successful"
    
    Write-Host "SUCCESS: Multiple imports without -Force work fine" -ForegroundColor Green
} catch {
    Write-Host "FAILED: Multiple imports without -Force - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nModule re-import testing complete." -ForegroundColor Yellow

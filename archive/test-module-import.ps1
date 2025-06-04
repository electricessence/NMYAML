# Test script to verify module import behavior
Write-Host "Testing module import approaches..." -ForegroundColor Yellow

$terminalModulePath = ".\scripts\modules\TerminalOutput.psm1"

# Test 1: Current approach (with -Force and -Scope Local)
Write-Host "`nTest 1: Current approach (with -Force and -Scope Local)"
try {
    Import-Module $terminalModulePath -Force -ErrorAction Stop -Scope Local
    Write-InfoMessage "Test message 1"
    Write-Host "SUCCESS: Current approach works" -ForegroundColor Green
    Remove-Module TerminalOutput -ErrorAction SilentlyContinue
} catch {
    Write-Host "FAILED: Current approach - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Simplified approach (ErrorAction Stop only)
Write-Host "`nTest 2: Simplified approach (ErrorAction Stop only)"
try {
    Import-Module $terminalModulePath -ErrorAction Stop
    Write-InfoMessage "Test message 2"
    Write-Host "SUCCESS: Simplified approach works" -ForegroundColor Green
    Remove-Module TerminalOutput -ErrorAction SilentlyContinue
} catch {
    Write-Host "FAILED: Simplified approach - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Minimal approach (just the path)
Write-Host "`nTest 3: Minimal approach (just the path)"
try {
    Import-Module $terminalModulePath
    Write-InfoMessage "Test message 3"
    Write-Host "SUCCESS: Minimal approach works" -ForegroundColor Green
    Remove-Module TerminalOutput -ErrorAction SilentlyContinue
} catch {
    Write-Host "FAILED: Minimal approach - $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nModule import testing complete." -ForegroundColor Yellow

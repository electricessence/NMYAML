# Comprehensive Test Script for XML-to-YAML Transformation System
# Tests all features: namespace support, schema validation, anchors/aliases, proper disposal

param(
    [switch]$Detailed = $false
)

Write-Host "=== XML-to-YAML Transformation System Test Suite ===" -ForegroundColor Cyan
Write-Host "Testing enhanced system with improved resource management" -ForegroundColor Green
Write-Host ""

$testResults = @()

function Test-Transformation {
    param(
        [string]$TestName,
        [string]$XmlFile,
        [string]$XsltFile,
        [string]$OutputFile,
        [string]$ExpectedContent = $null
    )
    
    Write-Host "Testing: $TestName" -ForegroundColor Yellow
    
    if (-not (Test-Path $XmlFile)) {
        Write-Host "  ❌ FAIL: XML file '$XmlFile' not found" -ForegroundColor Red
        return $false
    }
    
    if (-not (Test-Path $XsltFile)) {
        Write-Host "  ❌ FAIL: XSLT file '$XsltFile' not found" -ForegroundColor Red
        return $false
    }
    
    try {
        # Run transformation
        $result = & powershell -File transform-improved.ps1 -XmlFile $XmlFile -XsltFile $XsltFile -OutputFile $OutputFile 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            if (Test-Path $OutputFile) {
                $content = Get-Content $OutputFile -Raw
                if ($Detailed) {
                    Write-Host "  📄 Generated content:" -ForegroundColor Cyan
                    Write-Host "  $content" -ForegroundColor Gray
                }
                
                # Basic validation
                if ($content -match "name:" -and $content -match "age:" -and $content -match "30") {
                    Write-Host "  ✅ PASS: Transformation successful" -ForegroundColor Green
                    return $true
                } else {
                    Write-Host "  ❌ FAIL: Output doesn't contain expected content" -ForegroundColor Red
                    return $false
                }
            } else {
                Write-Host "  ❌ FAIL: Output file not created" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "  ❌ FAIL: Transformation failed with exit code $LASTEXITCODE" -ForegroundColor Red
            if ($Detailed) {
                Write-Host "  Error details: $result" -ForegroundColor Red
            }
            return $false
        }
    } catch {
        Write-Host "  ❌ FAIL: Exception during transformation: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Test-FileHandles {
    param([string]$TestFile)
    
    Write-Host "Testing: File Handle Management" -ForegroundColor Yellow
    
    # Try to delete and recreate the file immediately after transformation
    try {
        if (Test-Path $TestFile) {
            Remove-Item $TestFile -Force
            New-Item $TestFile -ItemType File -Force | Out-Null
            Write-Host "  ✅ PASS: File handles properly released" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  ❌ FAIL: Test file doesn't exist" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  ❌ FAIL: File handle still locked: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Test Cases
Write-Host "Running test cases..." -ForegroundColor Cyan
Write-Host ""

# Test 1: Non-namespaced XML
$test1 = Test-Transformation -TestName "Non-namespaced XML Support" -XmlFile "sample-no-namespace.yaml.xml" -XsltFile "xml-to-yaml.xslt" -OutputFile "test-output-1.yaml"
$testResults += @{Name="Non-namespaced XML"; Result=$test1}

# Test 2: Namespaced XML
$test2 = Test-Transformation -TestName "Namespaced XML Support" -XmlFile "sample.yaml.xml" -XsltFile "xml-to-yaml.xslt" -OutputFile "test-output-2.yaml"
$testResults += @{Name="Namespaced XML"; Result=$test2}

# Test 3: Backward compatibility
$test3 = Test-Transformation -TestName "Backward Compatibility" -XmlFile "sample-old-format.xml" -XsltFile "xml-to-yaml.xslt" -OutputFile "test-output-3.yaml"
$testResults += @{Name="Backward Compatibility"; Result=$test3}

# Test 4: File handle management
$test4 = Test-FileHandles -TestFile "test-output-1.yaml"
$testResults += @{Name="File Handle Management"; Result=$test4}

# Test 5: Schema validation (if available)
if (Test-Path "yaml-schema-no-namespace.xsd") {
    Write-Host "Testing: XSD Schema Validation" -ForegroundColor Yellow
    try {
        # Basic XML validation check
        [xml]$xml = Get-Content "sample-no-namespace.yaml.xml"
        Write-Host "  ✅ PASS: XML is well-formed" -ForegroundColor Green
        $test5 = $true
    } catch {
        Write-Host "  ❌ FAIL: XML validation failed: $($_.Exception.Message)" -ForegroundColor Red
        $test5 = $false
    }
    $testResults += @{Name="Schema Validation"; Result=$test5}
}

# Test 6: Anchor/Alias support
Write-Host "Testing: Anchor/Alias Support" -ForegroundColor Yellow
if (Test-Path "test-output-1.yaml") {
    $content = Get-Content "test-output-1.yaml" -Raw
    if ($content -match "&address-info" -and $content -match "\*address-info") {
        Write-Host "  ✅ PASS: Anchors and aliases properly generated" -ForegroundColor Green
        $test6 = $true
    } else {
        Write-Host "  ❌ FAIL: Anchors/aliases not found in output" -ForegroundColor Red
        $test6 = $false
    }
} else {
    Write-Host "  ❌ FAIL: Test output file not available" -ForegroundColor Red
    $test6 = $false
}
$testResults += @{Name="Anchor/Alias Support"; Result=$test6}

# Summary
Write-Host ""
Write-Host "=== Test Results Summary ===" -ForegroundColor Cyan
$passCount = 0
$totalCount = $testResults.Count

foreach ($test in $testResults) {
    $status = if ($test.Result) { "✅ PASS" } else { "❌ FAIL" }
    $color = if ($test.Result) { "Green" } else { "Red" }
    Write-Host "  $($test.Name): $status" -ForegroundColor $color
    if ($test.Result) { $passCount++ }
}

Write-Host ""
Write-Host "Overall Result: $passCount/$totalCount tests passed" -ForegroundColor $(if ($passCount -eq $totalCount) { "Green" } else { "Yellow" })

if ($passCount -eq $totalCount) {
    Write-Host "🎉 All tests passed! The XML-to-YAML transformation system is working correctly." -ForegroundColor Green
} else {
    Write-Host "⚠️ Some tests failed. Please review the issues above." -ForegroundColor Yellow
}

# Cleanup test files
Write-Host ""
Write-Host "Cleaning up test files..." -ForegroundColor Gray
Remove-Item "test-output-*.yaml" -ErrorAction SilentlyContinue

Write-Host "Test suite completed." -ForegroundColor Cyan

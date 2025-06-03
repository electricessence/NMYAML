# Improved XML Schema validation test
param(
    [string]$TestType = "all"
)

Write-Host "=== Improved XML Schema Validation Tests ===" -ForegroundColor Cyan

function Test-XmlValidation {
    param(
        [string]$XmlFile,
        [string]$XsdFile,
        [string]$Description
    )
    
    Write-Host "`nTesting: $Description" -ForegroundColor Yellow
    Write-Host "XML: $XmlFile" -ForegroundColor Gray
    Write-Host "XSD: $XsdFile" -ForegroundColor Gray
    
    try {
        # First, analyze the schema to determine if it has a target namespace
        $xsdContent = Get-Content $XsdFile -Raw
        $hasTargetNamespace = $xsdContent -match 'targetNamespace\s*=\s*"([^"]*)"'
        $targetNs = if ($matches) { $matches[1] } else { $null }
        
        Write-Host "   Schema target namespace: $(if ($targetNs) { $targetNs } else { '(none)' })" -ForegroundColor Gray
        
        # Load the schema
        $schemaSet = New-Object System.Xml.Schema.XmlSchemaSet
        if ($targetNs) {
            $schema = $schemaSet.Add($targetNs, (Resolve-Path $XsdFile).Path)
        } else {
            $schema = $schemaSet.Add($null, (Resolve-Path $XsdFile).Path)
        }
        
        # Create XML reader settings with validation
        $settings = New-Object System.Xml.XmlReaderSettings
        $settings.ValidationType = [System.Xml.ValidationType]::Schema
        $settings.Schemas = $schemaSet
        $settings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessIdentityConstraints
        
        # Track validation errors
        $validationErrors = @()
        $settings.add_ValidationEventHandler({
            param($sender, $e)
            $validationErrors += $e.Message
        })
        
        # Validate the XML
        $reader = [System.Xml.XmlReader]::Create((Resolve-Path $XmlFile).Path, $settings)
        while ($reader.Read()) { }
        $reader.Close()
        
        if ($validationErrors.Count -eq 0) {
            Write-Host "✅ VALIDATION PASSED" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ VALIDATION FAILED" -ForegroundColor Red
            foreach ($error in $validationErrors) {
                Write-Host "   Error: $error" -ForegroundColor Red
            }
            return $false
        }
    } catch {
        Write-Host "❌ VALIDATION ERROR: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Test combinations
Write-Host "Testing XML validation with improved schema loading..." -ForegroundColor Green

$results = @()

# Test 1: Namespaced XML with namespaced schema
$results += [PSCustomObject]@{
    Test = "Namespaced XML + Namespaced Schema"
    Result = Test-XmlValidation "sample.yaml.xml" "yaml-schema.xsd" "Namespaced XML with Namespaced Schema"
}

# Test 2: Non-namespaced XML with non-namespaced schema
$results += [PSCustomObject]@{
    Test = "Non-namespaced XML + Non-namespaced Schema"  
    Result = Test-XmlValidation "sample-no-namespace.yaml.xml" "yaml-schema-no-namespace.xsd" "Non-namespaced XML with Non-namespaced Schema"
}

# Test 3: Namespaced XML with non-namespaced schema
$results += [PSCustomObject]@{
    Test = "Namespaced XML + Non-namespaced Schema"
    Result = Test-XmlValidation "sample.yaml.xml" "yaml-schema-no-namespace.xsd" "Namespaced XML with Non-namespaced Schema"
}

# Test 4: Non-namespaced XML with namespaced schema
$results += [PSCustomObject]@{
    Test = "Non-namespaced XML + Namespaced Schema"
    Result = Test-XmlValidation "sample-no-namespace.yaml.xml" "yaml-schema.xsd" "Non-namespaced XML with Namespaced Schema"
}

# Summary
Write-Host "`n=== VALIDATION SUMMARY ===" -ForegroundColor Cyan
$results | ForEach-Object {
    $status = if ($_.Result) { "✅ PASS" } else { "❌ FAIL" }
    Write-Host "$status - $($_.Test)" -ForegroundColor $(if ($_.Result) { "Green" } else { "Red" })
}

Write-Host "`n=== ANALYSIS ===" -ForegroundColor Cyan
Write-Host "• Testing XSD flexibility with different namespace configurations..." -ForegroundColor Yellow

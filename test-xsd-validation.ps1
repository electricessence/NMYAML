# Test XML Schema validation for both namespaced and non-namespaced versions
param(
    [string]$TestType = "all"
)

Write-Host "=== XML Schema Validation Tests ===" -ForegroundColor Cyan

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
        # Load the schema
        $schemaSet = New-Object System.Xml.Schema.XmlSchemaSet
        $schema = $schemaSet.Add($null, (Resolve-Path $XsdFile).Path)
        
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
Write-Host "Testing XML validation with different schema combinations..." -ForegroundColor Green

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

# Test 3: Namespaced XML with non-namespaced schema (should fail)
$results += [PSCustomObject]@{
    Test = "Namespaced XML + Non-namespaced Schema (Cross-test)"
    Result = Test-XmlValidation "sample.yaml.xml" "yaml-schema-no-namespace.xsd" "Namespaced XML with Non-namespaced Schema"
}

# Test 4: Non-namespaced XML with namespaced schema (should fail)
$results += [PSCustomObject]@{
    Test = "Non-namespaced XML + Namespaced Schema (Cross-test)"
    Result = Test-XmlValidation "sample-no-namespace.yaml.xml" "yaml-schema.xsd" "Non-namespaced XML with Namespaced Schema"
}

# Summary
Write-Host "`n=== VALIDATION SUMMARY ===" -ForegroundColor Cyan
$results | ForEach-Object {
    $status = if ($_.Result) { "✅ PASS" } else { "❌ FAIL" }
    Write-Host "$status - $($_.Test)" -ForegroundColor $(if ($_.Result) { "Green" } else { "Red" })
}

Write-Host "`n=== CONCLUSION ===" -ForegroundColor Cyan
Write-Host "• XSD schemas with targetNamespace REQUIRE namespaced XML" -ForegroundColor Yellow
Write-Host "• XSD schemas without targetNamespace validate non-namespaced XML" -ForegroundColor Yellow
Write-Host "• Cross-validation (namespaced XML + non-namespaced schema) should fail" -ForegroundColor Yellow
Write-Host "• We need SEPARATE schemas for namespaced vs non-namespaced XML" -ForegroundColor Yellow

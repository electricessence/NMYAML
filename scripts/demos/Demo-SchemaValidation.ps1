# Demo-SchemaValidation.ps1
# Script to demonstrate schema validation functionality with namespaced and non-namespaced schemas

# Import modules
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesDir = Join-Path $scriptDir "modules"
$schemaModulePath = Join-Path $modulesDir "XmlYamlSchema.psm1"
$terminalOutputModule = Join-Path $modulesDir "TerminalOutput.psm1"

Import-Module $schemaModulePath -Force
Import-Module $terminalOutputModule -Force

# Define paths
$projectRoot = Split-Path -Parent $scriptDir
$namespacedSchemaPath = Join-Path $projectRoot "schemas\yaml-schema.xsd"
$nonNamespacedSchemaPath = Join-Path $projectRoot "schemas\yaml-schema-no-namespace.xsd"
$namespacedXmlPath = Join-Path $projectRoot "samples\sample.yaml.xml"
$nonNamespacedXmlPath = Join-Path $projectRoot "samples\sample-no-namespace.yaml.xml"

Write-Banner -Text "XML Schema Validation Demonstration" -ForegroundColor Cyan

# Function to display result
function Show-ValidationResult {
    param(
        [string]$Title,
        [PSObject]$Result
    )
    
    Write-SectionHeader -Text $Title -ForegroundColor Yellow
    if ($Result.Success) {
        Write-SuccessMessage "Validation successful!"
    } else {
        Write-ErrorMessage "Validation failed with the following errors:"
        foreach ($error in $Result.Errors) {
            Write-InfoMessage "- $error" -ForegroundColor Red -NoPrefix:$true
        }
    }
    Write-Host ""
}

# 1. Validate namespaced XML against namespaced schema
Write-InfoMessage "Testing namespaced XML against namespaced schema..."
# For namespaced schema, we need to specify the namespace
$settings = New-Object System.Xml.XmlReaderSettings
$settings.ValidationType = [System.Xml.ValidationType]::Schema
$settings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessIdentityConstraints

# Add the schema with namespace
$schemaSet = New-Object System.Xml.Schema.XmlSchemaSet
$schemaSet.Add("http://yaml.org/xml/1.2", $namespacedSchemaPath)
$settings.Schemas = $schemaSet

# Track validation errors
$validationErrors = @()
$settings.add_ValidationEventHandler({
    param($sender, $e)
    $validationErrors += $e.Message
})

try {
    # Validate the XML
    $reader = [System.Xml.XmlReader]::Create($namespacedXmlPath, $settings)
    try {
        while ($reader.Read()) { }
    }
    finally {
        if ($reader) { $reader.Close() }
    }
    
    $result1 = [PSCustomObject]@{
        Success = ($validationErrors.Count -eq 0)
        Errors = $validationErrors
    }
}
catch {
    $result1 = [PSCustomObject]@{
        Success = $false
        Errors = @($_.Exception.Message)
    }
}

Show-ValidationResult -Title "Namespaced XML against Namespaced Schema" -Result $result1

# 2. Validate non-namespaced XML against non-namespaced schema
Write-InfoMessage "Testing non-namespaced XML against non-namespaced schema..."
$result2 = Test-XmlAgainstSchema -XmlPath $nonNamespacedXmlPath -SchemaPath $nonNamespacedSchemaPath
Show-ValidationResult -Title "Non-namespaced XML against Non-namespaced Schema" -Result $result2

# 3. Create a temporary file with namespaced XML converted to non-namespaced
Write-InfoMessage "Creating a temporary version of the namespaced XML with namespaces removed..."
$tempFile = Join-Path $env:TEMP "temp-converted-xml.xml"

# Read the namespaced XML and remove the namespace prefix
[xml]$namespacedXml = Get-Content -Path $namespacedXmlPath -Raw
$namespacedXmlContent = Get-Content -Path $namespacedXmlPath -Raw
$convertedXml = $namespacedXmlContent -replace 'xmlns:yaml="http://yaml.org/xml/1.2"', '' -replace 'yaml:', ''
$convertedXml | Out-File -FilePath $tempFile -Encoding utf8

# 4. Validate the converted XML against the non-namespaced schema
Write-InfoMessage "Testing converted XML against non-namespaced schema..."
$result3 = Test-XmlAgainstSchema -XmlPath $tempFile -SchemaPath $nonNamespacedSchemaPath
Show-ValidationResult -Title "Converted XML against Non-namespaced Schema" -Result $result3

# 5. Validate non-namespaced XML against namespaced schema (expected to fail)
Write-InfoMessage "Testing non-namespaced XML against namespaced schema (expected to fail)..."
# For namespaced schema, we need to specify the namespace
$settings = New-Object System.Xml.XmlReaderSettings
$settings.ValidationType = [System.Xml.ValidationType]::Schema
$settings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessIdentityConstraints

# Add the schema with namespace
$schemaSet = New-Object System.Xml.Schema.XmlSchemaSet
$schemaSet.Add("http://yaml.org/xml/1.2", $namespacedSchemaPath)
$settings.Schemas = $schemaSet

# Track validation errors
$validationErrors = @()
$settings.add_ValidationEventHandler({
    param($sender, $e)
    $validationErrors += $e.Message
})

try {
    # Validate the XML
    $reader = [System.Xml.XmlReader]::Create($nonNamespacedXmlPath, $settings)
    try {
        while ($reader.Read()) { }
    }
    catch {
        $validationErrors += $_.Exception.Message
    }
    finally {
        if ($reader) { $reader.Close() }
    }
    
    $result4 = [PSCustomObject]@{
        Success = ($validationErrors.Count -eq 0)
        Errors = $validationErrors
    }
}
catch {
    $result4 = [PSCustomObject]@{
        Success = $false
        Errors = @($_.Exception.Message)
    }
}

Show-ValidationResult -Title "Non-namespaced XML against Namespaced Schema (Expected Failure)" -Result $result4

# Summary
Write-SectionHeader -Text "Validation Summary" -ForegroundColor Cyan
$tableData = @(
    [PSCustomObject]@{
        "Test Case" = "Namespaced XML → Namespaced Schema"
        "Result" = if ($result1.Success) { "✓ PASS" } else { "✗ FAIL" }
        "Expected" = "PASS"
        "Status" = if ($result1.Success) { "As Expected" } else { "ERROR" }
    },
    [PSCustomObject]@{
        "Test Case" = "Non-namespaced XML → Non-namespaced Schema"
        "Result" = if ($result2.Success) { "✓ PASS" } else { "✗ FAIL" }
        "Expected" = "PASS"
        "Status" = if ($result2.Success) { "As Expected" } else { "ERROR" }
    },
    [PSCustomObject]@{
        "Test Case" = "Converted XML → Non-namespaced Schema"
        "Result" = if ($result3.Success) { "✓ PASS" } else { "✗ FAIL" }
        "Expected" = "PASS"
        "Status" = if ($result3.Success) { "As Expected" } else { "ERROR" }
    },
    [PSCustomObject]@{
        "Test Case" = "Non-namespaced XML → Namespaced Schema"
        "Result" = if ($result4.Success) { "✓ PASS" } else { "✗ FAIL" }
        "Expected" = "FAIL"
        "Status" = if (!$result4.Success) { "As Expected" } else { "ERROR" }
    }
)

Write-ConsoleTable -Data $tableData -Properties "Test Case","Result","Expected","Status" -Title "XML Schema Validation Results"

# Cleanup
Remove-Item -Path $tempFile -Force

Write-Banner -Text "Demonstration Complete" -ForegroundColor Green -Width 40 -Character '-'

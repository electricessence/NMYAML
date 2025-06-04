# Validate-AllXmlSamples.ps1
# An automated validation pipeline to test multiple XML samples against schemas

param(
    [Parameter(Mandatory=$false)]
    [string]$NamespacedSchemaPath = "..\..\schemas\yaml-schema.xsd",
    
    [Parameter(Mandatory=$false)]
    [string]$NonNamespacedSchemaPath = "..\..\schemas\yaml-schema-no-namespace.xsd",
    
    [Parameter(Mandatory=$false)]
    [string]$SamplesDir = "..\..\samples",

    [Parameter(Mandatory=$false)]
    [switch]$GenerateReport = $false,

    [Parameter(Mandatory=$false)]
    [string]$ReportPath = "..\..\output\validation-report.html"
)

# Resolve paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

# If relative paths are provided, make them absolute
if (-not [System.IO.Path]::IsPathRooted($NamespacedSchemaPath)) {
    $NamespacedSchemaPath = Join-Path $projectRoot $NamespacedSchemaPath.TrimStart("..\")
}
if (-not [System.IO.Path]::IsPathRooted($NonNamespacedSchemaPath)) {
    $NonNamespacedSchemaPath = Join-Path $projectRoot $NonNamespacedSchemaPath.TrimStart("..\")
}
if (-not [System.IO.Path]::IsPathRooted($SamplesDir)) {
    $SamplesDir = Join-Path $projectRoot $SamplesDir.TrimStart("..\")
}
if (-not [System.IO.Path]::IsPathRooted($ReportPath)) {
    $ReportPath = Join-Path $projectRoot $ReportPath.TrimStart("..\")
}

# Banner
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "           Automated XML Schema Validation Pipeline" -ForegroundColor Cyan  
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host

# Helper function to validate XML against a schema
function Test-XmlWithSchema {
    param(
        [string]$XmlPath,
        [string]$SchemaPath,
        [string]$TargetNamespace = $null
    )
    
    try {
        $settings = New-Object System.Xml.XmlReaderSettings
        $settings.ValidationType = [System.Xml.ValidationType]::Schema
        $settings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessIdentityConstraints
        
        $schemaSet = New-Object System.Xml.Schema.XmlSchemaSet
        if ($TargetNamespace) {
            $schema = $schemaSet.Add($TargetNamespace, $SchemaPath)
        } else {
            $schema = $schemaSet.Add($null, $SchemaPath)
        }
        $settings.Schemas = $schemaSet
        
        # Track validation errors
        $validationErrors = @()
        $settings.add_ValidationEventHandler({
            param($sender, $e)
            $validationErrors += $e.Message
        })
        
        # Validate the XML
        $reader = [System.Xml.XmlReader]::Create($XmlPath, $settings)
        try {
            while ($reader.Read()) { }
        }
        catch {
            $validationErrors += $_.Exception.Message
        }
        finally {
            if ($reader) { $reader.Close() }
        }
        
        return [PSCustomObject]@{
            Success = ($validationErrors.Count -eq 0)
            Errors = $validationErrors
        }
    }
    catch {
        return [PSCustomObject]@{
            Success = $false
            Errors = @($_.Exception.Message)
        }
    }
}

# Helper function to detect if XML has a namespace
function Test-XmlHasNamespace {
    param([string]$XmlPath)
    
    try {
        [xml]$xmlContent = Get-Content -Path $XmlPath -Raw
        $rootElement = $xmlContent.DocumentElement
        
        # Check for any namespace declarations
        $hasNamespace = $rootElement.GetAttribute("xmlns") -or 
                       ($rootElement.Attributes | Where-Object { $_.Name -like "xmlns:*" }).Count -gt 0
                       
        # Also check if any elements use a prefix
        if (-not $hasNamespace) {
            $hasNamespace = $rootElement.OuterXml -match "<[^>]+:"
        }
        
        return $hasNamespace
    }
    catch {
        Write-Host "Error checking namespace in $XmlPath : $_" -ForegroundColor Red
        return $false
    }
}

# Helper function to get namespace from XML
function Get-XmlNamespace {
    param([string]$XmlPath)
    
    try {
        [xml]$xmlContent = Get-Content -Path $XmlPath -Raw
        $rootElement = $xmlContent.DocumentElement
        
        # Look for namespace declarations
        $ns = $null
        
        # First check for default namespace
        $defaultNs = $rootElement.GetAttribute("xmlns")
        if ($defaultNs) {
            return $defaultNs
        }
        
        # Then check for any prefixed namespaces
        foreach ($attr in $rootElement.Attributes) {
            if ($attr.Name -like "xmlns:*") {
                return $attr.Value
            }
        }
        
        return $null
    }
    catch {
        Write-Host "Error extracting namespace from $XmlPath : $_" -ForegroundColor Red
        return $null
    }
}

# Get the target namespace from the schema
$namespaceTargetNs = $null
$schemaContent = Get-Content -Path $NamespacedSchemaPath -Raw
if ($schemaContent -match 'targetNamespace\s*=\s*"([^"]+)"') {
    $namespaceTargetNs = $matches[1]
    Write-Host "Detected target namespace in schema: $namespaceTargetNs" -ForegroundColor Yellow
} else {
    Write-Host "Warning: No target namespace found in the namespaced schema." -ForegroundColor Red
}

# Find all XML files in the samples directory
$xmlFiles = Get-ChildItem -Path $SamplesDir -Filter "*.xml" -Recurse

if ($xmlFiles.Count -eq 0) {
    Write-Host "No XML files found in $SamplesDir" -ForegroundColor Red
    exit
}

Write-Host "Found $($xmlFiles.Count) XML files to validate" -ForegroundColor Yellow
Write-Host

# Validate each XML file
$results = @()

foreach ($xmlFile in $xmlFiles) {
    Write-Host "Processing: $($xmlFile.Name)" -ForegroundColor Magenta
    
    # Determine if the XML has a namespace
    $hasNamespace = Test-XmlHasNamespace -XmlPath $xmlFile.FullName
    $xmlNamespace = if ($hasNamespace) { Get-XmlNamespace -XmlPath $xmlFile.FullName } else { $null }
    
    # Choose the appropriate schema based on namespace presence
    if ($hasNamespace) {
        Write-Host "  XML has namespace: $xmlNamespace" -ForegroundColor Gray
        $schemaPath = $NamespacedSchemaPath
        $targetNs = $namespaceTargetNs
    } else {
        Write-Host "  XML has no namespace" -ForegroundColor Gray
        $schemaPath = $NonNamespacedSchemaPath
        $targetNs = $null
    }
    
    # Validate with the appropriate schema
    Write-Host "  Using schema: $schemaPath" -ForegroundColor Gray
    if ($targetNs) {
        Write-Host "  With target namespace: $targetNs" -ForegroundColor Gray
    }
    
    $validationResult = Test-XmlWithSchema -XmlPath $xmlFile.FullName -SchemaPath $schemaPath -TargetNamespace $targetNs
    
    if ($validationResult.Success) {
        Write-Host "  ✅ Validation Passed" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Validation Failed" -ForegroundColor Red
        foreach ($error in $validationResult.Errors) {
            Write-Host "    - $error" -ForegroundColor Red
        }
    }
    
    # Also try validating with the opposite schema (for testing purposes)
    $oppositeSchemaPath = if ($hasNamespace) { $NonNamespacedSchemaPath } else { $NamespacedSchemaPath }
    $oppositeTargetNs = if ($hasNamespace) { $null } else { $namespaceTargetNs }
    
    Write-Host "  Testing with opposite schema: $oppositeSchemaPath" -ForegroundColor Gray
    $oppositeResult = Test-XmlWithSchema -XmlPath $xmlFile.FullName -SchemaPath $oppositeSchemaPath -TargetNamespace $oppositeTargetNs
    
    $oppositeOutcome = if ($oppositeResult.Success) {
        "✅ Passed (Unexpected)"
    } else {
        "❌ Failed (Expected)"
    }
    Write-Host "  $oppositeOutcome" -ForegroundColor $(if ($oppositeResult.Success) { "Yellow" } else { "Gray" })
    
    # Store the results
    $results += [PSCustomObject]@{
        FileName = $xmlFile.Name
        FilePath = $xmlFile.FullName
        HasNamespace = $hasNamespace
        Namespace = $xmlNamespace
        SchemaUsed = $schemaPath
        ValidationSuccess = $validationResult.Success
        ValidationErrors = $validationResult.Errors
        OppositeSchemaSuccess = $oppositeResult.Success
    }
    
    Write-Host
}

# Print summary
Write-Host "Validation Summary:" -ForegroundColor Yellow
$passed = ($results | Where-Object { $_.ValidationSuccess }).Count
$failed = ($results | Where-Object { -not $_.ValidationSuccess }).Count
$total = $results.Count

Write-Host "Total Files: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })

# Detailed breakdown
$namespacedCount = ($results | Where-Object { $_.HasNamespace }).Count
$nonNamespacedCount = ($results | Where-Object { -not $_.HasNamespace }).Count

Write-Host
Write-Host "Files with namespace: $namespacedCount" -ForegroundColor White
Write-Host "Files without namespace: $nonNamespacedCount" -ForegroundColor White

# Generate HTML report if requested
if ($GenerateReport) {
    Write-Host
    Write-Host "Generating HTML validation report..." -ForegroundColor Yellow
    
    $reportHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>YAML XML Schema Validation Report</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 20px; }
        h1, h2 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .pass { color: green; }
        .fail { color: red; }
        .summary { margin-bottom: 20px; padding: 10px; background-color: #f5f5f5; border-left: 5px solid #333; }
        .error-details { font-family: monospace; color: #d14; margin-top: 5px; }
    </style>
</head>
<body>
    <h1>YAML XML Schema Validation Report</h1>
    <div class="summary">
        <p><strong>Date:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        <p><strong>Total Files:</strong> $total</p>
        <p><strong>Passed:</strong> <span class="pass">$passed</span></p>
        <p><strong>Failed:</strong> <span class="fail">$failed</span></p>
        <p><strong>Files with namespace:</strong> $namespacedCount</p>
        <p><strong>Files without namespace:</strong> $nonNamespacedCount</p>
        <p><strong>Namespaced Schema:</strong> $NamespacedSchemaPath</p>
        <p><strong>Non-namespaced Schema:</strong> $NonNamespacedSchemaPath</p>
    </div>
    
    <h2>Validation Results</h2>
    <table>
        <tr>
            <th>File Name</th>
            <th>Has Namespace</th>
            <th>Schema Used</th>
            <th>Result</th>
            <th>Error Details</th>
        </tr>
"@

    foreach ($result in $results) {
        $resultText = if ($result.ValidationSuccess) { "PASS" } else { "FAIL" }
        $resultClass = if ($result.ValidationSuccess) { "pass" } else { "fail" }
        $schemaUsedName = Split-Path -Leaf $result.SchemaUsed
        $errorDetails = if ($result.ValidationErrors) { 
            "<div class='error-details'>" + ($result.ValidationErrors -join "<br>") + "</div>" 
        } else { 
            "" 
        }
        
        $reportHtml += @"
        <tr>
            <td>$($result.FileName)</td>
            <td>$($result.HasNamespace)</td>
            <td>$schemaUsedName</td>
            <td class="$resultClass">$resultText</td>
            <td>$errorDetails</td>
        </tr>
"@
    }

    $reportHtml += @"
    </table>
    
    <h2>Cross-Schema Validation</h2>
    <p>This section shows the results of validating each XML file against the opposite schema type (namespaced vs non-namespaced).
       For properly formatted XML, we expect validation to succeed only with the matching schema type.</p>
    
    <table>
        <tr>
            <th>File Name</th>
            <th>Has Namespace</th>
            <th>Primary Schema Result</th>
            <th>Opposite Schema Result</th>
        </tr>
"@

    foreach ($result in $results) {
        $primaryResult = if ($result.ValidationSuccess) { "PASS" } else { "FAIL" }
        $primaryClass = if ($result.ValidationSuccess) { "pass" } else { "fail" }
        
        $oppositeResult = if ($result.OppositeSchemaSuccess) { "PASS (Unexpected)" } else { "FAIL (Expected)" }
        $oppositeClass = if ($result.OppositeSchemaSuccess) { "fail" } else { "pass" }
        
        $reportHtml += @"
        <tr>
            <td>$($result.FileName)</td>
            <td>$($result.HasNamespace)</td>
            <td class="$primaryClass">$primaryResult</td>
            <td class="$oppositeClass">$oppositeResult</td>
        </tr>
"@
    }

    $reportHtml += @"
    </table>
    
    <footer>
        <p>Report generated by Validate-AllXmlSamples.ps1 at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </footer>
</body>
</html>
"@

    $reportHtml | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Host "Report saved to: $ReportPath" -ForegroundColor Green
}

Write-Host
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "                  Validation Complete" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

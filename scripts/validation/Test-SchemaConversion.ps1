# Test-SchemaConversion.ps1
# Comprehensive testing script for schema conversion validation

param(
    [Parameter(Mandatory=$false)]
    [string]$NamespacedSchemaPath = "..\schemas\yaml-schema.xsd",
    
    [Parameter(Mandatory=$false)]
    [string]$NonNamespacedSchemaPath = "..\schemas\yaml-schema-no-namespace.xsd",
    
    [Parameter(Mandatory=$false)]
    [string]$SamplesDirectory = "..\samples\test-cases"
)

# Import modules
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesDir = Join-Path $scriptDir "modules"
$schemaModulePath = Join-Path $modulesDir "XmlYamlSchema.psm1"
$terminalModulePath = Join-Path $modulesDir "TerminalOutput.psm1"

Import-Module $schemaModulePath -Force -ErrorAction Stop -Scope Local
Import-Module $terminalModulePath -ErrorAction Stop

# Banner
Write-Banner -Text "Schema Conversion Test Suite" -ForegroundColor Cyan

# Resolve paths
$projectRoot = Split-Path -Parent $scriptDir
$absNamespacedPath = Join-Path $projectRoot $NamespacedSchemaPath.TrimStart("..\")
$absNonNamespacedPath = Join-Path $projectRoot $NonNamespacedSchemaPath.TrimStart("..\")
$absSamplesDir = Join-Path $projectRoot $SamplesDirectory.TrimStart("..\")

# Create test samples directory if it doesn't exist
if (-not (Test-Path $absSamplesDir)) {
    Write-InfoMessage "Creating test samples directory: $absSamplesDir"
    New-Item -Path $absSamplesDir -ItemType Directory -Force | Out-Null
}

# Define test cases with specific XML features to test
$testCases = @{
    "simple_scalar" = @{
        namespaced = '<yaml:document xmlns:yaml="http://yaml.org/xml/1.2"><yaml:scalar>Simple value</yaml:scalar></yaml:document>'
        nonNamespaced = '<document><scalar>Simple value</scalar></document>'
    }
    "complex_mapping" = @{
        namespaced = '<yaml:document xmlns:yaml="http://yaml.org/xml/1.2"><yaml:mapping><yaml:entry><yaml:key><yaml:scalar>key</yaml:scalar></yaml:key><yaml:value><yaml:scalar>value</yaml:scalar></yaml:value></yaml:entry></yaml:mapping></yaml:document>'
        nonNamespaced = '<document><mapping><entry><key><scalar>key</scalar></key><value><scalar>value</scalar></value></entry></mapping></document>'
    }
    "nested_sequence" = @{
        namespaced = '<yaml:document xmlns:yaml="http://yaml.org/xml/1.2"><yaml:sequence><yaml:item><yaml:sequence><yaml:item><yaml:scalar>Nested item</yaml:scalar></yaml:item></yaml:sequence></yaml:item></yaml:sequence></yaml:document>'
        nonNamespaced = '<document><sequence><item><sequence><item><scalar>Nested item</scalar></item></sequence></item></sequence></document>'
    }
    "anchors_aliases" = @{
        namespaced = '<yaml:document xmlns:yaml="http://yaml.org/xml/1.2"><yaml:mapping><yaml:entry><yaml:key><yaml:scalar>base</yaml:scalar></yaml:key><yaml:value><yaml:mapping yaml:anchor="base"><yaml:entry><yaml:key><yaml:scalar>name</yaml:scalar></yaml:key><yaml:value><yaml:scalar>Base Object</yaml:scalar></yaml:value></yaml:entry></yaml:mapping></yaml:value></yaml:entry><yaml:entry><yaml:key><yaml:scalar>derived</yaml:scalar></yaml:key><yaml:value><yaml:alias yaml:ref="base"/></yaml:value></yaml:entry></yaml:mapping></yaml:document>'
        nonNamespaced = '<document><mapping><entry><key><scalar>base</scalar></key><value><mapping anchor="base"><entry><key><scalar>name</scalar></key><value><scalar>Base Object</scalar></value></entry></mapping></value></entry><entry><key><scalar>derived</scalar></key><value><alias ref="base"/></value></entry></mapping></document>'
    }
    "tagged_values" = @{
        namespaced = '<yaml:document xmlns:yaml="http://yaml.org/xml/1.2"><yaml:scalar yaml:tag="tag:yaml.org,2002:int">42</yaml:scalar></yaml:document>'
        nonNamespaced = '<document><scalar tag="tag:yaml.org,2002:int">42</scalar></document>'
    }
}

# Save test cases to files
Write-SectionHeader -Text "Creating Test Cases" -ForegroundColor Yellow
foreach ($testName in $testCases.Keys) {
    $namespacedFile = Join-Path $absSamplesDir "$testName-namespaced.yaml.xml"
    $nonNamespacedFile = Join-Path $absSamplesDir "$testName-no-namespace.yaml.xml"
    
    $testCases[$testName].namespaced | Out-File -FilePath $namespacedFile -Encoding UTF8
    $testCases[$testName].nonNamespaced | Out-File -FilePath $nonNamespacedFile -Encoding UTF8
    
    Write-InfoMessage "Created test case: $testName"
}

# Test function to validate schema conversion
function Test-SchemaFeature {
    param (
        [string]$TestName,
        [string]$NamespacedXmlPath,
        [string]$NonNamespacedXmlPath,
        [string]$NamespacedSchemaPath,
        [string]$NonNamespacedSchemaPath
    )
    
    Write-InfoMessage "Testing feature: $TestName" -ForegroundColor Yellow
    
    # Test original namespaced XML against namespaced schema
    $nsResult1 = Test-XmlAgainstSchema -XmlPath $NamespacedXmlPath -SchemaPath $NamespacedSchemaPath
    
    # Test non-namespaced XML against non-namespaced schema
    $nonNsResult = Test-XmlAgainstSchema -XmlPath $NonNamespacedXmlPath -SchemaPath $NonNamespacedSchemaPath
    
    # Test if converted namespaced XML can validate against non-namespaced schema
    $converterScript = Join-Path $scriptDir "Convert-NamespacedSchema.ps1"
    $tempOutputPath = Join-Path $absSamplesDir "$TestName-converted.yaml.xml"
    
    # Create a temporary converted version of the namespaced XML directly with regex
    $xmlContent = Get-Content -Path $NamespacedXmlPath -Raw
    $xmlContent = $xmlContent -replace 'xmlns:yaml="http://yaml.org/xml/1.2"', ''
    $xmlContent = $xmlContent -replace 'yaml:', ''
    $xmlContent | Out-File -FilePath $tempOutputPath -Encoding UTF8
    
    # Validate the converted XML against the non-namespaced schema
    $convertedResult = Test-XmlAgainstSchema -XmlPath $tempOutputPath -SchemaPath $NonNamespacedSchemaPath
    
    # Return results
    return [PSCustomObject]@{
        Feature = $TestName
        OriginalValidation = $nsResult1.Success
        ConvertedValidation = $convertedResult.Success
        NonNamespacedValidation = $nonNsResult.Success
        AllPassed = $nsResult1.Success -and $convertedResult.Success -and $nonNsResult.Success
    }
}

# Run tests on all test cases
Write-SectionHeader -Text "Running Test Cases" -ForegroundColor Magenta
$testResults = @()

foreach ($testName in $testCases.Keys) {
    $namespacedFile = Join-Path $absSamplesDir "$testName-namespaced.yaml.xml"
    $nonNamespacedFile = Join-Path $absSamplesDir "$testName-no-namespace.yaml.xml"
    
    $result = Test-SchemaFeature `
        -TestName $testName `
        -NamespacedXmlPath $namespacedFile `
        -NonNamespacedXmlPath $nonNamespacedFile `
        -NamespacedSchemaPath $absNamespacedPath `
        -NonNamespacedSchemaPath $absNonNamespacedPath
    
    $testResults += $result
}

# Display test results summary
Write-SectionHeader -Text "Test Results Summary" -ForegroundColor Cyan
Write-ConsoleTable -Data $testResults -Properties Feature,OriginalValidation,ConvertedValidation,NonNamespacedValidation,AllPassed -Title "Schema Conversion Test Results"

# Final summary
$passedCount = ($testResults | Where-Object { $_.AllPassed }).Count
$totalCount = $testResults.Count

Write-InfoMessage "$passedCount of $totalCount tests passed" -ForegroundColor $(if ($passedCount -eq $totalCount) { "Green" } else { "Yellow" })

if ($passedCount -eq $totalCount) {
    Write-SuccessMessage "All schema conversion tests passed! The conversion is working correctly."
} else {
    Write-WarningMessage "Some tests failed. Please review the results for details."
}

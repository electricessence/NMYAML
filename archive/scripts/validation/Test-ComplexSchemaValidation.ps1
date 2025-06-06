# Test-ComplexSchemaValidation.ps1
# Advanced validation script that tests complex YAML XML structures against schemas

param(
    [Parameter(Mandatory=$false)]
    [string]$NamespacedSchemaPath = "..\..\schemas\yaml-schema.xsd",
    
    [Parameter(Mandatory=$false)]
    [string]$NonNamespacedSchemaPath = "..\..\schemas\yaml-schema-no-namespace.xsd",
    
    [Parameter(Mandatory=$false)]
    [string]$TestCasesDir = "..\..\samples\test-cases"
)

# Define text styling for consistent output
function Write-Title {
    param([string]$Text)
    Write-Host "`n$Text" -ForegroundColor Yellow
    Write-Host ("=" * $Text.Length) -ForegroundColor Yellow
}

function Write-SubTitle {
    param([string]$Text)
    Write-Host "`n$Text" -ForegroundColor Magenta
    Write-Host ("-" * $Text.Length) -ForegroundColor Magenta
}

# Banner
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "           Complex XML Schema Validation Tests" -ForegroundColor Cyan  
Write-Host "=========================================================" -ForegroundColor Cyan

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
if (-not [System.IO.Path]::IsPathRooted($TestCasesDir)) {
    $TestCasesDir = Join-Path $projectRoot $TestCasesDir.TrimStart("..\")
}

# Create the test cases directory if it doesn't exist
if (-not (Test-Path -Path $TestCasesDir)) {
    New-Item -Path $TestCasesDir -ItemType Directory -Force | Out-Null
    Write-Host "Created test cases directory: $TestCasesDir" -ForegroundColor Gray
}

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

# Create complex test cases
Write-Host "Creating complex test cases..." -ForegroundColor Yellow

# Test Case 1: Nested Mappings with Sequences (With Namespace)
$complexNestedXmlNs = @"
<?xml version="1.0" encoding="UTF-8"?>
<yaml:document xmlns:yaml="http://yaml.org/xml/1.2">
  <yaml:mapping>
    <yaml:entry>
      <yaml:key>
        <yaml:scalar>api</yaml:scalar>
      </yaml:key>
      <yaml:value>
        <yaml:mapping>
          <yaml:entry>
            <yaml:key>
              <yaml:scalar>endpoints</yaml:scalar>
            </yaml:key>
            <yaml:value>
              <yaml:sequence>
                <yaml:item>
                  <yaml:mapping>
                    <yaml:entry>
                      <yaml:key>
                        <yaml:scalar>name</yaml:scalar>
                      </yaml:key>
                      <yaml:value>
                        <yaml:scalar>users</yaml:scalar>
                      </yaml:value>
                    </yaml:entry>
                    <yaml:entry>
                      <yaml:key>
                        <yaml:scalar>url</yaml:scalar>
                      </yaml:key>
                      <yaml:value>
                        <yaml:scalar>/api/users</yaml:scalar>
                      </yaml:value>
                    </yaml:entry>
                    <yaml:entry>
                      <yaml:key>
                        <yaml:scalar>methods</yaml:scalar>
                      </yaml:key>
                      <yaml:value>
                        <yaml:sequence>
                          <yaml:item>
                            <yaml:scalar>GET</yaml:scalar>
                          </yaml:item>
                          <yaml:item>
                            <yaml:scalar>POST</yaml:scalar>
                          </yaml:item>
                          <yaml:item>
                            <yaml:scalar>DELETE</yaml:scalar>
                          </yaml:item>
                        </yaml:sequence>
                      </yaml:value>
                    </yaml:entry>
                  </yaml:mapping>
                </yaml:item>
                <yaml:item>
                  <yaml:mapping>
                    <yaml:entry>
                      <yaml:key>
                        <yaml:scalar>name</yaml:scalar>
                      </yaml:key>
                      <yaml:value>
                        <yaml:scalar>products</yaml:scalar>
                      </yaml:value>
                    </yaml:entry>
                    <yaml:entry>
                      <yaml:key>
                        <yaml:scalar>url</yaml:scalar>
                      </yaml:key>
                      <yaml:value>
                        <yaml:scalar>/api/products</yaml:scalar>
                      </yaml:value>
                    </yaml:entry>
                  </yaml:mapping>
                </yaml:item>
              </yaml:sequence>
            </yaml:value>
          </yaml:entry>
          <yaml:entry>
            <yaml:key>
              <yaml:scalar>version</yaml:scalar>
            </yaml:key>
            <yaml:value>
              <yaml:scalar>1.0</yaml:scalar>
            </yaml:value>
          </yaml:entry>
        </yaml:mapping>
      </yaml:value>
    </yaml:entry>
  </yaml:mapping>
</yaml:document>
"@

$complexNestedXmlPath = Join-Path $TestCasesDir "complex-nested.yaml.xml"
$complexNestedXmlNs | Out-File -FilePath $complexNestedXmlPath -Encoding utf8
Write-Host "Created complex nested XML test case (namespaced): $complexNestedXmlPath" -ForegroundColor Gray

# Test Case 1: Nested Mappings with Sequences (Without Namespace)
$complexNestedXmlNoNs = $complexNestedXmlNs -replace 'xmlns:yaml="http://yaml.org/xml/1.2"', '' -replace 'yaml:', ''
$complexNestedXmlNoNsPath = Join-Path $TestCasesDir "complex-nested-no-namespace.yaml.xml"
$complexNestedXmlNoNs | Out-File -FilePath $complexNestedXmlNoNsPath -Encoding utf8
Write-Host "Created complex nested XML test case (non-namespaced): $complexNestedXmlNoNsPath" -ForegroundColor Gray

# Test Case 2: Empty and null values (With Namespace)
$emptyNullXmlNs = @"
<?xml version="1.0" encoding="UTF-8"?>
<yaml:document xmlns:yaml="http://yaml.org/xml/1.2">
  <yaml:mapping>
    <yaml:entry>
      <yaml:key>
        <yaml:scalar>empty_string</yaml:scalar>
      </yaml:key>
      <yaml:value>
        <yaml:scalar></yaml:scalar>
      </yaml:value>
    </yaml:entry>
    <yaml:entry>
      <yaml:key>
        <yaml:scalar>null_value</yaml:scalar>
      </yaml:key>
      <yaml:value>
        <yaml:null />
      </yaml:value>
    </yaml:entry>
    <yaml:entry>
      <yaml:key>
        <yaml:scalar>empty_mapping</yaml:scalar>
      </yaml:key>
      <yaml:value>
        <yaml:mapping />
      </yaml:value>
    </yaml:entry>
    <yaml:entry>
      <yaml:key>
        <yaml:scalar>empty_sequence</yaml:scalar>
      </yaml:key>
      <yaml:value>
        <yaml:sequence />
      </yaml:value>
    </yaml:entry>
  </yaml:mapping>
</yaml:document>
"@

$emptyNullXmlPath = Join-Path $TestCasesDir "empty-null-values.yaml.xml"
$emptyNullXmlNs | Out-File -FilePath $emptyNullXmlPath -Encoding utf8
Write-Host "Created empty/null values XML test case (namespaced): $emptyNullXmlPath" -ForegroundColor Gray

# Test Case 2: Empty and null values (Without Namespace)
$emptyNullXmlNoNs = $emptyNullXmlNs -replace 'xmlns:yaml="http://yaml.org/xml/1.2"', '' -replace 'yaml:', ''
$emptyNullXmlNoNsPath = Join-Path $TestCasesDir "empty-null-values-no-namespace.yaml.xml"
$emptyNullXmlNoNs | Out-File -FilePath $emptyNullXmlNoNsPath -Encoding utf8
Write-Host "Created empty/null values XML test case (non-namespaced): $emptyNullXmlNoNsPath" -ForegroundColor Gray

# Test Case 3: Deep nesting with mixed content types (With Namespace)
$deepNestedXmlNs = @"
<?xml version="1.0" encoding="UTF-8"?>
<yaml:document xmlns:yaml="http://yaml.org/xml/1.2">
  <yaml:mapping>
    <yaml:entry>
      <yaml:key>
        <yaml:scalar>level1</yaml:scalar>
      </yaml:key>
      <yaml:value>
        <yaml:mapping>
          <yaml:entry>
            <yaml:key>
              <yaml:scalar>level2</yaml:scalar>
            </yaml:key>
            <yaml:value>
              <yaml:mapping>
                <yaml:entry>
                  <yaml:key>
                    <yaml:scalar>level3</yaml:scalar>
                  </yaml:key>
                  <yaml:value>
                    <yaml:mapping>
                      <yaml:entry>
                        <yaml:key>
                          <yaml:scalar>level4</yaml:scalar>
                        </yaml:key>
                        <yaml:value>
                          <yaml:mapping>
                            <yaml:entry>
                              <yaml:key>
                                <yaml:scalar>level5</yaml:scalar>
                              </yaml:key>
                              <yaml:value>
                                <yaml:sequence>
                                  <yaml:item>
                                    <yaml:mapping>
                                      <yaml:entry>
                                        <yaml:key>
                                          <yaml:scalar>name</yaml:scalar>
                                        </yaml:key>
                                        <yaml:value>
                                          <yaml:scalar>deep nesting test</yaml:scalar>
                                        </yaml:value>
                                      </yaml:entry>
                                    </yaml:mapping>
                                  </yaml:item>
                                </yaml:sequence>
                              </yaml:value>
                            </yaml:entry>
                          </yaml:mapping>
                        </yaml:value>
                      </yaml:entry>
                    </yaml:mapping>
                  </yaml:value>
                </yaml:entry>
              </yaml:mapping>
            </yaml:value>
          </yaml:entry>
        </yaml:mapping>
      </yaml:value>
    </yaml:entry>
  </yaml:mapping>
</yaml:document>
"@

$deepNestedXmlPath = Join-Path $TestCasesDir "deep-nesting.yaml.xml"
$deepNestedXmlNs | Out-File -FilePath $deepNestedXmlPath -Encoding utf8
Write-Host "Created deep nesting XML test case (namespaced): $deepNestedXmlPath" -ForegroundColor Gray

# Test Case 3: Deep nesting with mixed content types (Without Namespace)
$deepNestedXmlNoNs = $deepNestedXmlNs -replace 'xmlns:yaml="http://yaml.org/xml/1.2"', '' -replace 'yaml:', ''
$deepNestedXmlNoNsPath = Join-Path $TestCasesDir "deep-nesting-no-namespace.yaml.xml"
$deepNestedXmlNoNs | Out-File -FilePath $deepNestedXmlNoNsPath -Encoding utf8
Write-Host "Created deep nesting XML test case (non-namespaced): $deepNestedXmlNoNsPath" -ForegroundColor Gray

# Detect the target namespace for the namespaced schema
$schemaContent = Get-Content -Path $NamespacedSchemaPath -Raw
if ($schemaContent -match 'targetNamespace\s*=\s*"([^"]+)"') {
    $targetNs = $matches[1]
    Write-Host "Detected target namespace: $targetNs" -ForegroundColor Yellow
} else {
    Write-Host "Warning: No target namespace found in the schema." -ForegroundColor Red
    $targetNs = $null
}

# Run validation tests
Write-Title "Running Validation Tests"

$testCases = @(
    @{
        Name = "Complex Nested Structure (Namespaced)"
        XmlPath = $complexNestedXmlPath
        SchemaPath = $NamespacedSchemaPath
        TargetNamespace = $targetNs
        IsNamespaced = $true
    },
    @{
        Name = "Complex Nested Structure (Non-namespaced)"
        XmlPath = $complexNestedXmlNoNsPath
        SchemaPath = $NonNamespacedSchemaPath
        TargetNamespace = $null
        IsNamespaced = $false
    },
    @{
        Name = "Empty and Null Values (Namespaced)"
        XmlPath = $emptyNullXmlPath
        SchemaPath = $NamespacedSchemaPath
        TargetNamespace = $targetNs
        IsNamespaced = $true
    },
    @{
        Name = "Empty and Null Values (Non-namespaced)"
        XmlPath = $emptyNullXmlNoNsPath
        SchemaPath = $NonNamespacedSchemaPath
        TargetNamespace = $null
        IsNamespaced = $false
    },
    @{
        Name = "Deep Nesting (Namespaced)"
        XmlPath = $deepNestedXmlPath
        SchemaPath = $NamespacedSchemaPath
        TargetNamespace = $targetNs
        IsNamespaced = $true
    },
    @{
        Name = "Deep Nesting (Non-namespaced)"
        XmlPath = $deepNestedXmlNoNsPath
        SchemaPath = $NonNamespacedSchemaPath
        TargetNamespace = $null
        IsNamespaced = $false
    }
)

$testResults = @()

foreach ($testCase in $testCases) {
    Write-SubTitle $testCase.Name
    
    if ($testCase.IsNamespaced) {
        Write-Host "XML Format: Namespaced" -ForegroundColor White
        Write-Host "Schema: $($testCase.SchemaPath)" -ForegroundColor White
        Write-Host "Target Namespace: $($testCase.TargetNamespace)" -ForegroundColor White
    } else {
        Write-Host "XML Format: Non-namespaced" -ForegroundColor White 
        Write-Host "Schema: $($testCase.SchemaPath)" -ForegroundColor White
        Write-Host "Target Namespace: None" -ForegroundColor White
    }
    
    $result = Test-XmlWithSchema `
        -XmlPath $testCase.XmlPath `
        -SchemaPath $testCase.SchemaPath `
        -TargetNamespace $testCase.TargetNamespace
    
    if ($result.Success) {
        Write-Host "✅ Validation Passed" -ForegroundColor Green
    } else {
        Write-Host "❌ Validation Failed" -ForegroundColor Red
        foreach ($error in $result.Errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
    }
    
    $testResults += [PSCustomObject]@{
        TestCase = $testCase.Name
        Success = $result.Success
        Errors = $result.Errors
    }
}

# Print summary
Write-Title "Test Results Summary"

$passed = ($testResults | Where-Object { $_.Success }).Count
$failed = ($testResults | Where-Object { -not $_.Success }).Count
$total = $testResults.Count

Write-Host "Total Tests: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })

Write-Host
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "                 Testing Completed" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

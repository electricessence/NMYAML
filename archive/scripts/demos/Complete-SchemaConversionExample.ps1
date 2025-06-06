# Complete-SchemaConversionExample.ps1
# A comprehensive demonstration of the schema conversion with practical examples

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "     Complete XML Schema Namespace Conversion Example" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host

# Resolve paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$demosDir = Split-Path -Parent $scriptDir
$projectRoot = Split-Path -Parent $demosDir

$namespacedSchemaPath = Join-Path $projectRoot "schemas\yaml-schema.xsd"
$nonNamespacedSchemaPath = Join-Path $projectRoot "schemas\yaml-schema-no-namespace.xsd"
$namespacedXmlPath = Join-Path $projectRoot "samples\sample.yaml.xml"
$nonNamespacedXmlPath = Join-Path $projectRoot "samples\sample-no-namespace.yaml.xml"

# Create a temp directory for our demonstration files
$tempDir = Join-Path $env:TEMP "schema-demo-$(Get-Random)"
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

Write-Host "[1] Creating a simple example XML document..." -ForegroundColor Yellow
Write-Host

# Create a simple XML example
$simpleXmlNamespaced = @"
<?xml version="1.0" encoding="UTF-8"?>
<yaml:document xmlns:yaml="http://yaml.org/xml/1.2">
  <yaml:mapping>
    <yaml:entry>
      <yaml:key>
        <yaml:scalar>config</yaml:scalar>
      </yaml:key>
      <yaml:value>
        <yaml:mapping>
          <yaml:entry>
            <yaml:key>
              <yaml:scalar>server</yaml:scalar>
            </yaml:key>
            <yaml:value>
              <yaml:scalar>example.com</yaml:scalar>
            </yaml:value>
          </yaml:entry>
          <yaml:entry>
            <yaml:key>
              <yaml:scalar>port</yaml:scalar>
            </yaml:key>
            <yaml:value>
              <yaml:scalar>8080</yaml:scalar>
            </yaml:value>
          </yaml:entry>
        </yaml:mapping>
      </yaml:value>
    </yaml:entry>
  </yaml:mapping>
</yaml:document>
"@

$simpleXmlPath = Join-Path $tempDir "example-namespaced.yaml.xml"
$simpleXmlNamespaced | Out-File -FilePath $simpleXmlPath -Encoding utf8

# Display the example XML
Write-Host "Simple XML document with namespaces:" -ForegroundColor Magenta
Write-Host $simpleXmlNamespaced
Write-Host
Write-Host "Saved to: $simpleXmlPath" -ForegroundColor Gray
Write-Host

# Create a non-namespaced version by removing namespace prefixes
$simpleXmlNonNamespaced = $simpleXmlNamespaced -replace 'xmlns:yaml="http://yaml.org/xml/1.2"', '' -replace 'yaml:', ''
$simpleXmlNonNamespacedPath = Join-Path $tempDir "example-non-namespaced.yaml.xml"
$simpleXmlNonNamespaced | Out-File -FilePath $simpleXmlNonNamespacedPath -Encoding utf8

Write-Host "[2] Demonstrating Validation with Different Schemas..." -ForegroundColor Yellow
Write-Host

# Function to validate XML
function Test-XmlValidation {
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

# Test validation with namespaced schema
Write-Host "Validating namespaced XML with namespaced schema:"
$result1 = Test-XmlValidation -XmlPath $simpleXmlPath -SchemaPath $namespacedSchemaPath -TargetNamespace "http://yaml.org/xml/1.2"
if ($result1.Success) {
    Write-Host "✅ Validation successful" -ForegroundColor Green
} else {
    Write-Host "❌ Validation failed:" -ForegroundColor Red
    foreach ($error in $result1.Errors) {
        Write-Host "   $error" -ForegroundColor Red
    }
}
Write-Host

# Test validation with non-namespaced schema (should fail without conversion)
Write-Host "Validating namespaced XML with non-namespaced schema (should fail):"
$result2 = Test-XmlValidation -XmlPath $simpleXmlPath -SchemaPath $nonNamespacedSchemaPath
if ($result2.Success) {
    Write-Host "⚠️ Validation unexpectedly successful (may be schema processor quirk)" -ForegroundColor Yellow
} else {
    Write-Host "❌ Validation failed (expected):" -ForegroundColor Green
    foreach ($error in $result2.Errors) {
        Write-Host "   $error" -ForegroundColor Gray
    }
}
Write-Host

# Test validation of non-namespaced XML with non-namespaced schema
Write-Host "Validating non-namespaced XML with non-namespaced schema:"
$result3 = Test-XmlValidation -XmlPath $simpleXmlNonNamespacedPath -SchemaPath $nonNamespacedSchemaPath
if ($result3.Success) {
    Write-Host "✅ Validation successful" -ForegroundColor Green
} else {
    Write-Host "❌ Validation failed:" -ForegroundColor Red
    foreach ($error in $result3.Errors) {
        Write-Host "   $error" -ForegroundColor Red
    }
}
Write-Host

Write-Host "[3] Real-world Benefit: Consuming XML in Tools that Don't Handle Namespaces Well" -ForegroundColor Yellow
Write-Host

# Create example files for simulating XML processing in a system that doesn't handle namespaces well
Write-Host "Creating a simple XPath query example to access data from the XML..."

# Create XPath example script for namespaced XML
$xpathNamespacedScript = @"
# This example demonstrates accessing XML with namespaces
# Many systems struggle with namespace handling

# Load the XML document
[xml]\$doc = Get-Content -Path '$simpleXmlPath'

# Need to create a namespace manager to work with XPath
\$nsManager = New-Object System.Xml.XmlNamespaceManager(\$doc.NameTable)
\$nsManager.AddNamespace('y', 'http://yaml.org/xml/1.2')

# XPath query with namespaces requires prefix for EVERY node
\$serverNode = \$doc.SelectSingleNode('//y:mapping/y:entry/y:key[y:scalar="server"]/following-sibling::y:value/y:scalar', \$nsManager)

Write-Host "Server value from namespaced XML: \$(\$serverNode.InnerText)"
"@

$xpathNamespacedScriptPath = Join-Path $tempDir "query-namespaced.ps1"
$xpathNamespacedScript | Out-File -FilePath $xpathNamespacedScriptPath -Encoding utf8

# Create XPath example script for non-namespaced XML
$xpathNonNamespacedScript = @"
# This example demonstrates accessing XML without namespaces
# Much simpler to work with in many systems

# Load the XML document
[xml]\$doc = Get-Content -Path '$simpleXmlNonNamespacedPath'

# Simple XPath query without namespace complexity
\$serverNode = \$doc.SelectSingleNode('//mapping/entry/key[scalar="server"]/following-sibling::value/scalar')

Write-Host "Server value from non-namespaced XML: \$(\$serverNode.InnerText)"
"@

$xpathNonNamespacedScriptPath = Join-Path $tempDir "query-non-namespaced.ps1"
$xpathNonNamespacedScript | Out-File -FilePath $xpathNonNamespacedScriptPath -Encoding utf8

# Show the scripts
Write-Host
Write-Host "Accessing XML with namespaces requires complex namespace handling:" -ForegroundColor Magenta
Get-Content $xpathNamespacedScriptPath | ForEach-Object { Write-Host "  $_" }

Write-Host
Write-Host "Accessing XML without namespaces is much simpler:" -ForegroundColor Magenta
Get-Content $xpathNonNamespacedScriptPath | ForEach-Object { Write-Host "  $_" }

Write-Host
Write-Host "Running the query scripts:"
Write-Host "--------------------------"
Write-Host "Namespaced XML query:"
& pwsh -File $xpathNamespacedScriptPath
Write-Host
Write-Host "Non-namespaced XML query:"
& pwsh -File $xpathNonNamespacedScriptPath

Write-Host
Write-Host "[4] Summary and Conclusion" -ForegroundColor Yellow
Write-Host
Write-Host "The YAML XML Schema conversion provides these key benefits:" -ForegroundColor White
Write-Host "1. Maintains schema validation capabilities" -ForegroundColor White
Write-Host "2. Reduces complexity when processing XML documents" -ForegroundColor White
Write-Host "3. Improves compatibility with tools that don't handle namespaces well" -ForegroundColor White
Write-Host "4. Makes XPath queries much simpler" -ForegroundColor White
Write-Host "5. Preserves the same document structure and semantics" -ForegroundColor White

Write-Host
Write-Host "Temporary files created for this demo are stored in: $tempDir" -ForegroundColor Gray
Write-Host

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "                   Example Completed" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

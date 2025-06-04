# XmlYamlSchema.psm1
# PowerShell module for XML Schema operations related to YAML-XML conversion

# Import TerminalOutput module if available
$terminalModulePath = Join-Path $PSScriptRoot "TerminalOutput.psm1"
Import-Module $terminalModulePath -ErrorAction Stop

<#
.SYNOPSIS
    Creates a combined schema that supports both namespaced and non-namespaced XML.
.DESCRIPTION
    Generates an XSD schema that can validate both namespaced and non-namespaced XML
    by creating element definitions for both variants.
.PARAMETER NamespacedSchemaPath
    Path to the XML Schema with namespace definitions.
.PARAMETER NonNamespacedSchemaPath
    Path to the XML Schema without namespace definitions.
.PARAMETER OutputSchemaPath
    Path to save the generated combined schema.
.EXAMPLE
    New-CombinedSchema -NamespacedSchemaPath "yaml-schema.xsd" -NonNamespacedSchemaPath "yaml-schema-no-namespace.xsd" -OutputSchemaPath "yaml-schema-combined.xsd"
#>
function New-CombinedSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$NamespacedSchemaPath,
        
        [Parameter(Mandatory = $true)]
        [string]$NonNamespacedSchemaPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputSchemaPath
    )
      try {
        if (Get-Command "Write-InfoMessage" -ErrorAction SilentlyContinue) {
            Write-InfoMessage "Creating combined schema file..." -ForegroundColor Green
        } else {
            Write-Host "Creating combined schema file..." -ForegroundColor Green
        }
        
        # Load the namespaced schema
        $nsSchema = [xml](Get-Content -Path $NamespacedSchemaPath -Raw)
        
        # Load the non-namespaced schema
        $noNsSchema = [xml](Get-Content -Path $NonNamespacedSchemaPath -Raw)
        
        # Create a new schema document
        $combinedSchema = New-Object System.Xml.XmlDocument
        
        # Create XML declaration
        $xmlDecl = $combinedSchema.CreateXmlDeclaration("1.0", "UTF-8", $null)
        $combinedSchema.AppendChild($xmlDecl) | Out-Null
        
        # Create schema root element with necessary namespaces
        $schemaRoot = $combinedSchema.CreateElement("xs", "schema", "http://www.w3.org/2001/XMLSchema")
        $schemaRoot.SetAttribute("elementFormDefault", "qualified")
        $nsAttr = $combinedSchema.CreateAttribute("xmlns:yaml")
        $nsAttr.Value = "http://yaml.org/xml/1.2"
        $schemaRoot.Attributes.Append($nsAttr) | Out-Null
        $combinedSchema.AppendChild($schemaRoot) | Out-Null
        
        # Add annotation
        $annotation = $combinedSchema.CreateElement("xs", "annotation", "http://www.w3.org/2001/XMLSchema")
        $documentation = $combinedSchema.CreateElement("xs", "documentation", "http://www.w3.org/2001/XMLSchema")
        $documentation.InnerText = "Combined schema for YAML-XML that supports both namespaced and non-namespaced XML formats"
        $annotation.AppendChild($documentation) | Out-Null
        $schemaRoot.AppendChild($annotation) | Out-Null
        
        # Add import for namespaced schema
        $import = $combinedSchema.CreateElement("xs", "import", "http://www.w3.org/2001/XMLSchema")
        $import.SetAttribute("namespace", "http://yaml.org/xml/1.2")
        $import.SetAttribute("schemaLocation", "yaml-schema.xsd")
        $schemaRoot.AppendChild($import) | Out-Null
        
        # Add include for non-namespaced schema
        $include = $combinedSchema.CreateElement("xs", "include", "http://www.w3.org/2001/XMLSchema")
        $include.SetAttribute("schemaLocation", "yaml-schema-no-namespace.xsd")
        $schemaRoot.AppendChild($include) | Out-Null
        
        # Save the combined schema
        $combinedSchema.Save($OutputSchemaPath)
        
        Write-Host "Combined schema created successfully at $OutputSchemaPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to create combined schema: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Validates whether a schema supports both namespaced and non-namespaced XML.
.DESCRIPTION
    Tests if a given XSD schema can validate both namespaced and non-namespaced XML documents.
.PARAMETER SchemaPath
    Path to the XSD schema to test.
.PARAMETER NamespacedXmlPath
    Path to a sample XML file with namespaces.
.PARAMETER NonNamespacedXmlPath
    Path to a sample XML file without namespaces.
.EXAMPLE
    Test-SchemaFlexibility -SchemaPath "yaml-schema-combined.xsd" -NamespacedXmlPath "sample.yaml.xml" -NonNamespacedXmlPath "sample-no-namespace.yaml.xml"
#>
function Test-SchemaFlexibility {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SchemaPath,
        
        [Parameter(Mandatory = $true)]
        [string]$NamespacedXmlPath,
        
        [Parameter(Mandatory = $true)]
        [string]$NonNamespacedXmlPath
    )
    
    try {
        if (Get-Command "Write-InfoMessage" -ErrorAction SilentlyContinue) {
            Write-InfoMessage "Testing schema flexibility..."
            Write-InfoMessage "Schema: $SchemaPath"
        } else {
            Write-Host "Testing schema flexibility..." -ForegroundColor Yellow
            Write-Host "Schema: $SchemaPath" -ForegroundColor Gray
        }
        
        # Load the schema
        $schemaSet = New-Object System.Xml.Schema.XmlSchemaSet
        $schema = $null
          try {
            # First attempt to load the schema - use direct path to avoid Resolve-Path issues
            if (Test-Path $SchemaPath) {
                $schema = $schemaSet.Add($null, $SchemaPath)
                $schemaSet.Compile()
            } else {
                throw "Schema file not found: $SchemaPath"
            }
        }
        catch {
            if (Get-Command "Write-ErrorMessage" -ErrorAction SilentlyContinue) {
                Write-ErrorMessage "Failed to load schema: $($_.Exception.Message)"
            } else {
                Write-Error "Failed to load schema: $($_.Exception.Message)"
            }
            return [PSCustomObject]@{
                IsFlexible = $false
                NamespacedResult = $false
                NonNamespacedResult = $false
                Error = $_.Exception.Message
            }
        }
        
        # Test with namespaced XML
        if (Get-Command "Write-InfoMessage" -ErrorAction SilentlyContinue) {
            Write-InfoMessage "Testing with namespaced XML: $NamespacedXmlPath"
        } else {
            Write-Host "`nTesting with namespaced XML: $NamespacedXmlPath" -ForegroundColor Gray
        }
        $nsResult = Test-XmlAgainstSchema -XmlPath $NamespacedXmlPath -SchemaPath $SchemaPath
        # Test with non-namespaced XML
        if (Get-Command "Write-InfoMessage" -ErrorAction SilentlyContinue) {
            Write-InfoMessage "Testing with non-namespaced XML: $NonNamespacedXmlPath"
        } else {
            Write-Host "`nTesting with non-namespaced XML: $NonNamespacedXmlPath" -ForegroundColor Gray
        }
        $nonNsResult = Test-XmlAgainstSchema -XmlPath $NonNamespacedXmlPath -SchemaPath $SchemaPath
        
        # Determine flexibility
        $isFlexible = $nsResult.Success -and $nonNsResult.Success
        
        if ($isFlexible) {
            if (Get-Command "Write-SuccessMessage" -ErrorAction SilentlyContinue) {
                Write-SuccessMessage "Schema is FLEXIBLE - supports both namespaced and non-namespaced XML"
            } else {
                Write-Host "`n✅ Schema is FLEXIBLE - supports both namespaced and non-namespaced XML" -ForegroundColor Green
            }
        } else {
            if (Get-Command "Write-ErrorMessage" -ErrorAction SilentlyContinue) {
                Write-ErrorMessage "Schema is NOT FLEXIBLE"
                if (-not $nsResult.Success) {
                    Write-InfoMessage "- Failed with namespaced XML"
                }
                if (-not $nonNsResult.Success) {
                    Write-InfoMessage "- Failed with non-namespaced XML"
                }
            } else {
                Write-Host "`n❌ Schema is NOT FLEXIBLE" -ForegroundColor Red
                if (-not $nsResult.Success) {
                    Write-Host "   - Failed with namespaced XML" -ForegroundColor Red
                }
                if (-not $nonNsResult.Success) {
                    Write-Host "   - Failed with non-namespaced XML" -ForegroundColor Red
                }
            }
        }
        
        return [PSCustomObject]@{
            IsFlexible = $isFlexible
            NamespacedResult = $nsResult
            NonNamespacedResult = $nonNsResult
        }
    }    catch {
        if (Get-Command "Write-ErrorMessage" -ErrorAction SilentlyContinue) {
            Write-ErrorMessage "Error testing schema flexibility: $($_.Exception.Message)"
        } else {
            Write-Error "Error testing schema flexibility: $($_.Exception.Message)"
        }
        return [PSCustomObject]@{
            IsFlexible = $false
            NamespacedResult = $null
            NonNamespacedResult = $null
            Error = $_.Exception.Message
        }
    }
}

<#
.SYNOPSIS
    Validates an XML file against an XSD schema.
.DESCRIPTION
    Tests if an XML file is valid according to an XSD schema.
.PARAMETER XmlPath
    Path to the XML file to validate.
.PARAMETER SchemaPath
    Path to the XSD schema to validate against.
.EXAMPLE
    Test-XmlAgainstSchema -XmlPath "sample.xml" -SchemaPath "schema.xsd"
#>
function Test-XmlAgainstSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$XmlPath,
        
        [Parameter(Mandatory = $true)]
        [string]$SchemaPath
    )
    
    try {
        # Create settings for validation
        $settings = New-Object System.Xml.XmlReaderSettings
        $settings.ValidationType = [System.Xml.ValidationType]::Schema
        $settings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessIdentityConstraints
          # Add the schema
        try {
            # Check if the schema path exists before adding it
            if (Test-Path $SchemaPath) {
                $settings.Schemas.Add($null, $SchemaPath)
            } else {
                throw "Schema file not found: $SchemaPath"
            }
        }
        catch {
            return [PSCustomObject]@{
                Success = $false
                Errors = @("Failed to add schema: $($_.Exception.Message)")
            }
        }
        
        # Track validation errors
        $validationErrors = @()
        $settings.add_ValidationEventHandler({
            param($sender, $e)
            $validationErrors += $e.Message
        })
          # Validate the XML
        try {
            # Check if the XML path exists before creating the reader
            if (Test-Path $XmlPath) {
                $reader = [System.Xml.XmlReader]::Create($XmlPath, $settings)
                try {
                    while ($reader.Read()) { }
                }
                finally {
                    if ($reader) { $reader.Close() }
                }
            } else {
                throw "XML file not found: $XmlPath"
            }
        }
        catch {
            return [PSCustomObject]@{
                Success = $false
                Errors = @("XML read error: $($_.Exception.Message)")
            }
        }
          if ($validationErrors.Count -eq 0) {
            if (Get-Command "Write-SuccessMessage" -ErrorAction SilentlyContinue) {
                Write-SuccessMessage "Validation successful"
            } else {
                Write-Host "✅ Validation successful" -ForegroundColor Green
            }
            return [PSCustomObject]@{
                Success = $true
                Errors = @()
            }
        }
        else {            if (Get-Command "Write-ErrorMessage" -ErrorAction SilentlyContinue) {
                Write-ErrorMessage "Validation failed with $($validationErrors.Count) errors:"
                foreach ($error in $validationErrors) {
                    Write-InfoMessage "- $error"
                }
            } else {
                Write-Host "❌ Validation failed with $($validationErrors.Count) errors:" -ForegroundColor Red
                foreach ($error in $validationErrors) {
                    Write-Host "   - $error" -ForegroundColor Red
                }
            }
            return [PSCustomObject]@{
                Success = $false
                Errors = $validationErrors
            }
        }
    }
    catch {
        if (Get-Command "Write-ErrorMessage" -ErrorAction SilentlyContinue) {
            Write-ErrorMessage "Error during validation: $($_.Exception.Message)"
        } else {
            Write-Error "Error during validation: $($_.Exception.Message)"
        }
        return [PSCustomObject]@{
            Success = $false
            Errors = @($_.Exception.Message)
        }
    }
}

# Export functions
Export-ModuleMember -Function New-CombinedSchema, Test-SchemaFlexibility, Test-XmlAgainstSchema

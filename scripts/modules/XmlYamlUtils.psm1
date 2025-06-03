# XmlYamlUtils.psm1
# PowerShell module for XML-to-YAML transformation utilities

# Import TerminalOutput module if available
$terminalModulePath = Join-Path $PSScriptRoot "TerminalOutput.psm1"
if (Test-Path $terminalModulePath) {
    Import-Module $terminalModulePath -Force -ErrorAction SilentlyContinue
}

#region Validation Functions

<#
.SYNOPSIS
    Tests XML validation against an XSD schema.
.DESCRIPTION
    Validates an XML file against an XSD schema and returns detailed results.
.PARAMETER XmlFile
    Path to the XML file to validate.
.PARAMETER XsdFile
    Path to the XSD schema file.
.PARAMETER Description
    Optional description of the validation test.
.EXAMPLE
    Test-XmlValidation -XmlFile "sample.xml" -XsdFile "schema.xsd" -Description "Testing sample XML"
#>
function Test-XmlValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$XmlFile,
        
        [Parameter(Mandatory = $true)]
        [string]$XsdFile,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "XML Schema Validation"
    )
    
    # Use TerminalOutput module if available, otherwise fall back to Write-Host
    if (Get-Command "Write-SectionHeader" -ErrorAction SilentlyContinue) {
        Write-SectionHeader -Text $Description -ForegroundColor Yellow -LeadingNewLine $true
    } else {
        Write-Host "`nTesting: $Description" -ForegroundColor Yellow
    }
    
    if (Get-Command "Write-InfoMessage" -ErrorAction SilentlyContinue) {        Write-InfoMessage "XML: $XmlFile" -ForegroundColor Gray -NoPrefix:$true
        Write-InfoMessage "XSD: $XsdFile" -ForegroundColor Gray -NoPrefix:$true
    } else {
        Write-Host "XML: $XmlFile" -ForegroundColor Gray
        Write-Host "XSD: $XsdFile" -ForegroundColor Gray
    }
    
    try {
        # First, analyze the schema to determine if it has a target namespace
        $xsdContent = Get-Content $XsdFile -Raw
        $hasTargetNamespace = $xsdContent -match 'targetNamespace\s*=\s*"([^"]*)"'
        $targetNs = if ($matches) { $matches[1] } else { $null }
        
        if (Get-Command "Write-InfoMessage" -ErrorAction SilentlyContinue) {
            Write-InfoMessage "Schema target namespace: $(if ($targetNs) { $targetNs } else { '(none)' })" -ForegroundColor Gray -NoPrefix:$true
        } else {
            Write-Host "   Schema target namespace: $(if ($targetNs) { $targetNs } else { '(none)' })" -ForegroundColor Gray
        }
        
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
        try {
            $reader = [System.Xml.XmlReader]::Create((Resolve-Path $XmlFile).Path, $settings)
            try {
                while ($reader.Read()) { }
            } finally {
                if ($reader) { $reader.Close() }
            }        } catch {
            if (Get-Command "Write-ErrorMessage" -ErrorAction SilentlyContinue) {
                Write-ErrorMessage "XML READ ERROR: $($_.Exception.Message)"
            } else {
                Write-Host "❌ XML READ ERROR: $($_.Exception.Message)" -ForegroundColor Red
            }
            return [PSCustomObject]@{
                Success = $false
                Errors = @($_.Exception.Message)
            }
        }
        
        if ($validationErrors.Count -eq 0) {
            if (Get-Command "Write-SuccessMessage" -ErrorAction SilentlyContinue) {
                Write-SuccessMessage "VALIDATION PASSED"
            } else {
                Write-Host "✅ VALIDATION PASSED" -ForegroundColor Green
            }
            return [PSCustomObject]@{
                Success = $true
                Errors = @()
            }
        } else {
            if (Get-Command "Write-ErrorMessage" -ErrorAction SilentlyContinue) {
                Write-ErrorMessage "VALIDATION FAILED"
                foreach ($error in $validationErrors) {
                    Write-InfoMessage "Error: $error" -ForegroundColor Red -NoPrefix:$true
                }
            } else {
                Write-Host "❌ VALIDATION FAILED" -ForegroundColor Red
                foreach ($error in $validationErrors) {
                    Write-Host "   Error: $error" -ForegroundColor Red
                }
            }
            return [PSCustomObject]@{
                Success = $false
                Errors = $validationErrors
            }
        }
    } catch {
        if (Get-Command "Write-ErrorMessage" -ErrorAction SilentlyContinue) {
            Write-ErrorMessage "VALIDATION ERROR: $($_.Exception.Message)"
        } else {
            Write-Host "❌ VALIDATION ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }
        return [PSCustomObject]@{
            Success = $false
            Errors = @($_.Exception.Message)
        }
    }
}

#endregion

#region Transformation Functions

<#
.SYNOPSIS
    Transforms XML to YAML using XSLT.
.DESCRIPTION
    Converts an XML file to YAML format using an XSLT stylesheet with proper UTF-8 encoding.
.PARAMETER XmlFile
    Path to the XML file to transform.
.PARAMETER XsltFile
    Path to the XSLT stylesheet file.
.PARAMETER OutputFile
    Path to save the resulting YAML file.
.EXAMPLE
    Convert-XmlToYaml -XmlFile "sample.xml" -XsltFile "transform.xslt" -OutputFile "result.yaml"
#>
function Convert-XmlToYaml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$XmlFile,
        
        [Parameter(Mandatory = $true)]
        [string]$XsltFile,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputFile
    )
    
    try {
        # Use TerminalOutput module if available, otherwise fall back to Write-Host
        if (Get-Command "Write-InfoMessage" -ErrorAction SilentlyContinue) {
            Write-InfoMessage "Loading XML document: $XmlFile" -ForegroundColor Green
        } else {
            Write-Host "Loading XML document: $XmlFile" -ForegroundColor Green
        }
        
        # Create XmlReader settings
        $xmlReaderSettings = New-Object System.Xml.XmlReaderSettings
        $xmlReaderSettings.IgnoreWhitespace = $true
        
        # Load the XSLT stylesheet
        $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
        
        if (Get-Command "Write-InfoMessage" -ErrorAction SilentlyContinue) {
            Write-InfoMessage "Loading XSLT stylesheet: $XsltFile" -ForegroundColor Green
        } else {
            Write-Host "Loading XSLT stylesheet: $XsltFile" -ForegroundColor Green
        }
        
        $xslt.Load((Resolve-Path $XsltFile).Path)
        
        if (Get-Command "Write-InfoMessage" -ErrorAction SilentlyContinue) {
            Write-InfoMessage "Performing transformation..." -ForegroundColor Green
        } else {
            Write-Host "Performing transformation..." -ForegroundColor Green
        }
        
        # Show progress bar if terminal output available
        if (Get-Command "Write-ProgressBar" -ErrorAction SilentlyContinue) {
            Write-ProgressBar -PercentComplete 25
        }
        
        # Create output path - using UTF-8 encoding without BOM
        $outputPath = Join-Path (Get-Location) $OutputFile
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        
        try {
            $xmlReader = [System.Xml.XmlReader]::Create((Resolve-Path $XmlFile).Path, $xmlReaderSettings)
            try {
                $writer = [System.IO.StreamWriter]::new($outputPath, $false, $utf8NoBom)
                try {                # Perform the transformation
                    $xslt.Transform($xmlReader, $null, $writer)
                    
                    # Show progress completion if terminal output available
                    if (Get-Command "Write-ProgressBar" -ErrorAction SilentlyContinue) {
                        Write-ProgressBar -PercentComplete 100
                    }
                    
                    if (Get-Command "Write-SuccessMessage" -ErrorAction SilentlyContinue) {
                        Write-SuccessMessage "Transformation completed successfully!"
                        Write-InfoMessage "Output written to: $OutputFile" -ForegroundColor Cyan
                    } else {
                        Write-Host "Transformation completed successfully!" -ForegroundColor Green
                        Write-Host "Output written to: $OutputFile" -ForegroundColor Cyan
                    }
                    
                    return [PSCustomObject]@{
                        Success = $true
                        OutputFile = $OutputFile
                    }
                } finally {
                    if ($writer) { $writer.Dispose() }
                }
            } finally {
                if ($xmlReader) { $xmlReader.Dispose() }
            }
        } catch {
            if (Get-Command "Write-ErrorMessage" -ErrorAction SilentlyContinue) {
                Write-ErrorMessage "Error during XML/XSLT processing: $($_.Exception.Message)"
            } else {
                Write-Error "Error during XML/XSLT processing: $($_.Exception.Message)"
            }
            return [PSCustomObject]@{
                Success = $false
                Error = $_.Exception.Message
            }
        }
    } catch {
        if (Get-Command "Write-ErrorMessage" -ErrorAction SilentlyContinue) {
            Write-ErrorMessage "Error during transformation: $($_.Exception.Message)"
            Write-InfoMessage "Stack trace: $($_.Exception.StackTrace)" -ForegroundColor Red
        } else {
            Write-Error "Error during transformation: $($_.Exception.Message)"
            Write-Error "Stack trace: $($_.Exception.StackTrace)"
        }
        return [PSCustomObject]@{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

#endregion

#region Output Formatting Functions

<#
.SYNOPSIS
    Displays YAML content with syntax highlighting.
.DESCRIPTION
    Reads a YAML file and displays its contents with basic syntax highlighting.
.PARAMETER YamlFile
    Path to the YAML file to display.
.EXAMPLE
    Show-YamlContent -YamlFile "output.yaml"
#>
function Show-YamlContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$YamlFile
    )
    
    try {
        $content = Get-Content $YamlFile -Raw
        if (-not $content) {
            if (Get-Command "Write-WarningMessage" -ErrorAction SilentlyContinue) {
                Write-WarningMessage "The YAML file appears to be empty"
            } else {
                Write-Warning "The YAML file appears to be empty."
            }
            return
        }
        
        # Use advanced syntax highlighting if available, otherwise use basic highlighting
        if (Get-Command "Write-SyntaxHighlight" -ErrorAction SilentlyContinue) {
            # Use advanced syntax highlighting from TerminalOutput module
            Write-SyntaxHighlight -Text $content -Language yaml
        } else {
            # Fall back to basic syntax highlighting
            Write-Host "`nYAML Output:" -ForegroundColor Yellow
            Write-Host "============" -ForegroundColor Yellow
            
            # Simple syntax highlighting for YAML
            $lines = $content -split "`n"
            foreach ($line in $lines) {
                # Highlight keys
                if ($line -match '^(\s*)([^:]+)(:)(.*)$') {
                    $indent = $matches[1]
                    $key = $matches[2]
                    $colon = $matches[3]
                    $value = $matches[4]
                    
                    Write-Host $indent -NoNewline
                    Write-Host $key -ForegroundColor Cyan -NoNewline
                    Write-Host $colon -NoNewline
                    
                    # Check for special values like aliases, anchors
                    if ($value -match '^\s*\&') {
                        # Anchor
                        Write-Host $value -ForegroundColor Magenta
                    } elseif ($value -match '^\s*\*') {
                        # Alias reference
                        Write-Host $value -ForegroundColor Magenta
                    } else {
                        Write-Host $value
                    }
                }
                # List items
                elseif ($line -match '^(\s*)(-)(.*)$') {
                    $indent = $matches[1]
                    $dash = $matches[2]
                    $value = $matches[3]
                    
                    Write-Host $indent -NoNewline
                    Write-Host $dash -ForegroundColor Green -NoNewline
                    Write-Host $value
                }
                # Other content
                else {
                    Write-Host $line
                }
            }
        }
    } catch {
        if (Get-Command "Write-ErrorMessage" -ErrorAction SilentlyContinue) {
            Write-ErrorMessage "Error displaying YAML content: $($_.Exception.Message)"
        } else {
            Write-Error "Error displaying YAML content: $($_.Exception.Message)"
        }
    }
}

#endregion

# Export all functions
Export-ModuleMember -Function Test-XmlValidation, Convert-XmlToYaml, Show-YamlContent
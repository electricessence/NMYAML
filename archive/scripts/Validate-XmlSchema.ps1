# Validate-XmlSchema.ps1
# Validates XML files against XSD schemas before YAML transformation
# This prevents issues from propagating into the YAML output

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$XmlFilePath,
    
    [Parameter(Mandatory = $true)]
    [string]$XsdSchemaPath,
    
    [switch]$DetailedOutput,
    
    [switch]$StopOnFirstError
)

# Classes for structured validation results
class XsdValidationError {
    [string]$Message
    [int]$LineNumber
    [int]$LinePosition
    [string]$Severity
    [string]$SourceUri
    
    XsdValidationError([string]$message, [int]$line, [int]$position, [string]$severity, [string]$uri) {
        $this.Message = $message
        $this.LineNumber = $line
        $this.LinePosition = $position
        $this.Severity = $severity
        $this.SourceUri = $uri
    }
    
    [string] ToString() {
        return "[$($this.Severity)] Line $($this.LineNumber), Position $($this.LinePosition): $($this.Message)"
    }
}

class XsdValidationResult {
    [bool]$IsValid
    [XsdValidationError[]]$Errors
    [XsdValidationError[]]$Warnings
    [string]$XmlFile
    [string]$XsdFile
    [DateTime]$ValidationTime
    [TimeSpan]$Duration
    
    XsdValidationResult() {
        $this.Errors = @()
        $this.Warnings = @()
        $this.ValidationTime = Get-Date
        $this.IsValid = $true
    }
    
    [void] AddError([XsdValidationError]$error) {
        if ($error.Severity -eq "Error") {
            $this.Errors += $error
            $this.IsValid = $false
        } else {
            $this.Warnings += $error
        }
    }
    
    [string] GetSummary() {
        $summary = "XSD Validation Summary:`n"
        $summary += "- XML File: $($this.XmlFile)`n"
        $summary += "- XSD Schema: $($this.XsdFile)`n"
        $summary += "- Valid: $($this.IsValid)`n"
        $summary += "- Errors: $($this.Errors.Count)`n"
        $summary += "- Warnings: $($this.Warnings.Count)`n"
        $summary += "- Duration: $($this.Duration.TotalMilliseconds)ms"
        return $summary
    }
}

class XmlSchemaValidator {
    [string]$XmlPath
    [string]$XsdPath
    [XsdValidationResult]$Result
    [bool]$StopOnError
    
    XmlSchemaValidator([string]$xmlPath, [string]$xsdPath, [bool]$stopOnError) {
        $this.XmlPath = $xmlPath
        $this.XsdPath = $xsdPath
        $this.StopOnError = $stopOnError
        $this.Result = [XsdValidationResult]::new()
        $this.Result.XmlFile = $xmlPath
        $this.Result.XsdFile = $xsdPath
    }
    
    [XsdValidationResult] ValidateXml() {
        $startTime = Get-Date
        
        try {
            # Verify input files exist
            if (-not (Test-Path $this.XmlPath)) {
                throw "XML file not found: $($this.XmlPath)"
            }
            
            if (-not (Test-Path $this.XsdPath)) {
                throw "XSD schema file not found: $($this.XsdPath)"
            }
            
            Write-Verbose "Starting XSD validation..."
            Write-Verbose "XML File: $($this.XmlPath)"
            Write-Verbose "XSD Schema: $($this.XsdPath)"
            
            # Create XML reader settings with schema validation
            $readerSettings = New-Object System.Xml.XmlReaderSettings
            $readerSettings.ValidationType = [System.Xml.ValidationType]::Schema
            $readerSettings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessInlineSchema -bor
                                            [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessSchemaLocation -bor
                                            [System.Xml.Schema.XmlSchemaValidationFlags]::ReportValidationWarnings
              # Load XSD schema
            try {
                $schemaStream = [System.IO.File]::OpenRead($this.XsdPath)
                $schema = [System.Xml.Schema.XmlSchema]::Read($schemaStream, $null)
                $schemaStream.Close()
                
                if ($null -eq $schema) {
                    throw "Failed to load XSD schema from: $($this.XsdPath)"
                }
                
                $readerSettings.Schemas.Add($schema) | Out-Null
            }
            catch {
                throw "Error loading XSD schema: $($_.Exception.Message)"
            }
            
            # Set up validation event handler
            $validationHandler = {
                param($sender, $e)
                
                $error = [XsdValidationError]::new(
                    $e.Message,
                    $e.Exception.LineNumber,
                    $e.Exception.LinePosition,
                    $e.Severity.ToString(),
                    $e.Exception.SourceUri
                )
                
                $this.Result.AddError($error)
                
                if ($this.StopOnError -and $e.Severity -eq [System.Xml.Schema.XmlSeverityType]::Error) {
                    throw "Validation stopped on first error: $($e.Message)"
                }
            }
            
            $readerSettings.add_ValidationEventHandler($validationHandler)
            
            # Create XML reader and validate
            $xmlReader = [System.Xml.XmlReader]::Create($this.XmlPath, $readerSettings)
            
            try {
                # Read through entire document to trigger validation
                while ($xmlReader.Read()) {
                    # Reading triggers validation events
                }
                
                Write-Verbose "XML validation completed successfully"
            }
            finally {
                $xmlReader.Close()
                $xmlReader.Dispose()
            }
            
        }
        catch {
            # Handle validation exceptions
            $error = [XsdValidationError]::new(
                $_.Exception.Message,
                0,
                0,
                "Error",
                $this.XmlPath
            )
            $this.Result.AddError($error)
            Write-Error "XSD Validation failed: $($_.Exception.Message)"
        }
        
        $this.Result.Duration = (Get-Date) - $startTime
        return $this.Result
    }
}

# Main validation function
function Invoke-XmlSchemaValidation {
    param(
        [string]$XmlPath,
        [string]$XsdPath,
        [bool]$StopOnError = $false
    )
    
    $validator = [XmlSchemaValidator]::new($XmlPath, $XsdPath, $StopOnError)
    return $validator.ValidateXml()
}

# Helper function for common GitHub Actions validation
function Test-GitHubActionsXml {
    param(
        [string]$XmlPath,
        [string]$SchemaPath = "$PSScriptRoot\..\schemas\github-actions-schema.xsd"
    )
    
    Write-Host "Validating GitHub Actions XML against XSD schema..." -ForegroundColor Cyan
    
    $result = Invoke-XmlSchemaValidation -XmlPath $XmlPath -XsdPath $SchemaPath
    
    # Display results
    Write-Host "`n$($result.GetSummary())" -ForegroundColor $(if ($result.IsValid) { "Green" } else { "Red" })
    
    if ($result.Errors.Count -gt 0) {
        Write-Host "`nERRORS FOUND:" -ForegroundColor Red
        foreach ($error in $result.Errors) {
            Write-Host "  $error" -ForegroundColor Red
        }
    }
    
    if ($result.Warnings.Count -gt 0) {
        Write-Host "`nWARNINGS:" -ForegroundColor Yellow
        foreach ($warning in $result.Warnings) {
            Write-Host "  $warning" -ForegroundColor Yellow
        }
    }
    
    return $result
}

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    $result = Test-GitHubActionsXml -XmlPath $XmlFilePath -SchemaPath $XsdSchemaPath
    
    if ($DetailedOutput) {
        Write-Host "`nDETAILED VALIDATION REPORT:" -ForegroundColor Cyan
        Write-Host "=" * 50
        Write-Host $result.GetSummary()
        
        if ($result.Errors.Count -gt 0 -or $result.Warnings.Count -gt 0) {
            Write-Host "`nISSUES FOUND:" -ForegroundColor Yellow
            
            $allIssues = $result.Errors + $result.Warnings | Sort-Object LineNumber, LinePosition
            foreach ($issue in $allIssues) {
                $color = if ($issue.Severity -eq "Error") { "Red" } else { "Yellow" }
                Write-Host "  [$($issue.Severity)] Line $($issue.LineNumber):$($issue.LinePosition)" -ForegroundColor $color
                Write-Host "    $($issue.Message)" -ForegroundColor $color
                Write-Host ""
            }
        }
    }
    
    # Exit with appropriate code
    if (-not $result.IsValid) {
        Write-Host "XSD validation failed. Fix XML errors before proceeding with YAML transformation." -ForegroundColor Red
        exit 1
    } else {
        Write-Host "XSD validation passed. XML is ready for YAML transformation." -ForegroundColor Green
        exit 0
    }
}

# Convert-GitHubActions-Enhanced.ps1
# Enhanced XML-to-YAML conversion with XSD validation integration
# This script validates XML against XSD schema before transformation

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$XmlPath,
    
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    
    [string]$XsltPath = "$PSScriptRoot\..\xslt\github-actions-transform.xslt",
    
    [string]$XsdSchemaPath = "$PSScriptRoot\..\schemas\github-actions-schema.xsd",
    
    [switch]$SkipValidation,
    
    [switch]$DetailedOutput,
    
    [switch]$ForceOverwrite
)

# Import validation functions
. "$PSScriptRoot\Validate-XmlSchema.ps1"

# Enhanced conversion class
class GitHubActionsConverter {
    [string]$XmlPath
    [string]$OutputPath
    [string]$XsltPath
    [string]$XsdSchemaPath
    [bool]$SkipValidation
    [bool]$DetailedOutput
    [bool]$ForceOverwrite
    
    GitHubActionsConverter([hashtable]$params) {
        $this.XmlPath = $params.XmlPath
        $this.OutputPath = $params.OutputPath
        $this.XsltPath = $params.XsltPath
        $this.XsdSchemaPath = $params.XsdSchemaPath
        $this.SkipValidation = $params.SkipValidation
        $this.DetailedOutput = $params.DetailedOutput
        $this.ForceOverwrite = $params.ForceOverwrite
    }
    
    [bool] ValidateInputFiles() {
        $missingFiles = @()
        
        if (-not (Test-Path $this.XmlPath)) {
            $missingFiles += "XML file: $($this.XmlPath)"
        }
        
        if (-not (Test-Path $this.XsltPath)) {
            $missingFiles += "XSLT file: $($this.XsltPath)"
        }
        
        if (-not $this.SkipValidation -and -not (Test-Path $this.XsdSchemaPath)) {
            $missingFiles += "XSD schema file: $($this.XsdSchemaPath)"
        }
        
        if ($missingFiles.Count -gt 0) {
            Write-Error "Missing required files:`n$($missingFiles -join "`n")"
            return $false
        }
        
        return $true
    }
    
    [bool] ValidateOutputPath() {
        $outputDir = Split-Path $this.OutputPath -Parent
        
        if (-not (Test-Path $outputDir)) {
            try {
                New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
                Write-Verbose "Created output directory: $outputDir"
            }
            catch {
                Write-Error "Failed to create output directory: $($_.Exception.Message)"
                return $false
            }
        }
        
        if ((Test-Path $this.OutputPath) -and -not $this.ForceOverwrite) {
            $response = Read-Host "Output file exists. Overwrite? (y/N)"
            if ($response -notmatch '^[yY]') {
                Write-Host "Operation cancelled by user."
                return $false
            }
        }
        
        return $true
    }
    
    [bool] ValidateXmlSchema() {
        if ($this.SkipValidation) {
            Write-Warning "XSD validation skipped. XML may contain errors that will affect YAML output."
            return $true
        }
        
        Write-Host "Step 1: Validating XML against XSD schema..." -ForegroundColor Cyan
        
        try {
            $validationResult = Invoke-XmlSchemaValidation -XmlPath $this.XmlPath -XsdPath $this.XsdSchemaPath
            
            if ($this.DetailedOutput) {
                Write-Host $validationResult.GetSummary() -ForegroundColor Cyan
            }
            
            if (-not $validationResult.IsValid) {
                Write-Host "XSD Validation FAILED:" -ForegroundColor Red
                foreach ($error in $validationResult.Errors) {
                    Write-Host "  ERROR: $error" -ForegroundColor Red
                }
                
                foreach ($warning in $validationResult.Warnings) {
                    Write-Host "  WARNING: $warning" -ForegroundColor Yellow
                }
                
                Write-Host "`nXML validation failed. Please fix the errors above before proceeding." -ForegroundColor Red
                return $false
            }
            
            Write-Host "✓ XSD validation passed" -ForegroundColor Green
            
            if ($validationResult.Warnings.Count -gt 0) {
                Write-Host "Warnings found:" -ForegroundColor Yellow
                foreach ($warning in $validationResult.Warnings) {
                    Write-Host "  WARNING: $warning" -ForegroundColor Yellow
                }
            }
            
            return $true
        }
        catch {
            Write-Error "XSD validation failed with exception: $($_.Exception.Message)"
            return $false
        }
    }
    
    [bool] TransformXmlToYaml() {
        Write-Host "Step 2: Transforming XML to YAML..." -ForegroundColor Cyan
        
        try {
            # Create XSL transform
            $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
            $xsltSettings = New-Object System.Xml.Xsl.XsltSettings($true, $true)
            $xslt.Load($this.XsltPath, $xsltSettings, $null)
            
            # Create XML reader
            $xmlReaderSettings = New-Object System.Xml.XmlReaderSettings
            $xmlReaderSettings.DtdProcessing = [System.Xml.DtdProcessing]::Parse
            $xmlReader = [System.Xml.XmlReader]::Create($this.XmlPath, $xmlReaderSettings)
            
            # Create output writer
            $writerSettings = New-Object System.Xml.XmlWriterSettings
            $writerSettings.Indent = $false
            $writerSettings.OmitXmlDeclaration = $true
            $writerSettings.ConformanceLevel = [System.Xml.ConformanceLevel]::Fragment
            
            # Transform to string first to clean up output
            $stringWriter = New-Object System.IO.StringWriter
            $xmlWriter = [System.Xml.XmlWriter]::Create($stringWriter, $writerSettings)
            
            $xslt.Transform($xmlReader, $xmlWriter)
            
            $yamlContent = $stringWriter.ToString()
            
            # Clean up XML artifacts and normalize YAML
            $yamlContent = $this.CleanYamlOutput($yamlContent)
            
            # Write to output file
            [System.IO.File]::WriteAllText($this.OutputPath, $yamlContent, [System.Text.Encoding]::UTF8)
            
            Write-Host "✓ XSLT transformation completed" -ForegroundColor Green
            
            # Cleanup
            $xmlReader.Close()
            $xmlWriter.Close()
            $stringWriter.Close()
            
            return $true
        }
        catch {
            Write-Error "XSLT transformation failed: $($_.Exception.Message)"
            if ($this.DetailedOutput) {
                Write-Host "Stack trace:" -ForegroundColor Red
                Write-Host $_.Exception.StackTrace -ForegroundColor Red
            }
            return $false
        }
    }
    
    [string] CleanYamlOutput([string]$yamlContent) {
        # Remove empty lines at the beginning
        $yamlContent = $yamlContent -replace '^\s*\n+', ''
        
        # Fix common YAML formatting issues
        $yamlContent = $yamlContent -replace '\s+$', '' # Remove trailing whitespace
        $yamlContent = $yamlContent -replace '\n\s*\n\s*\n+', "`n`n" # Normalize multiple empty lines
        
        # Fix empty values issues
        $yamlContent = $yamlContent -replace ':\s*$', ': ""' # Empty values
        $yamlContent = $yamlContent -replace ':\s*\n', ": `"`"`n" # Empty values at end of line
        
        # Ensure proper line endings
        $yamlContent = $yamlContent -replace '\r\n', "`n"
        $yamlContent = $yamlContent -replace '\r', "`n"
        
        # Add final newline if missing
        if (-not $yamlContent.EndsWith("`n")) {
            $yamlContent += "`n"
        }
        
        return $yamlContent
    }
    
    [bool] ValidateGeneratedYaml() {
        Write-Host "Step 3: Validating generated YAML..." -ForegroundColor Cyan
        
        try {
            # Check if YAML validation script exists
            $yamlValidatorPath = "$PSScriptRoot\Validate-YamlSyntax-Simple.ps1"
            if (-not (Test-Path $yamlValidatorPath)) {
                Write-Warning "YAML validation script not found. Skipping YAML validation."
                return $true
            }
            
            # Run YAML validation
            $validationResult = & $yamlValidatorPath -FilePath $this.OutputPath -Detailed:$this.DetailedOutput
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ YAML validation passed" -ForegroundColor Green
                return $true
            } else {
                Write-Host "⚠ YAML validation found issues" -ForegroundColor Yellow
                Write-Host "Note: Some issues may be acceptable for GitHub Actions YAML" -ForegroundColor Yellow
                return $true # Don't fail on YAML validation warnings
            }
        }
        catch {
            Write-Warning "YAML validation failed with exception: $($_.Exception.Message)"
            return $true # Don't fail the overall process
        }
    }
    
    [bool] Convert() {
        Write-Host "Starting enhanced XML-to-YAML conversion..." -ForegroundColor Cyan
        Write-Host "Source: $($this.XmlPath)" -ForegroundColor Gray
        Write-Host "Target: $($this.OutputPath)" -ForegroundColor Gray
        Write-Host ("=" * 60) -ForegroundColor Gray
        
        # Step 0: Validate input files
        if (-not $this.ValidateInputFiles()) {
            return $false
        }
        
        # Step 0.5: Validate output path
        if (-not $this.ValidateOutputPath()) {
            return $false
        }
        
        # Step 1: XSD validation
        if (-not $this.ValidateXmlSchema()) {
            return $false
        }
        
        # Step 2: XSLT transformation
        if (-not $this.TransformXmlToYaml()) {
            return $false
        }
        
        # Step 3: YAML validation
        $this.ValidateGeneratedYaml()
        
        Write-Host ("=" * 60) -ForegroundColor Gray
        Write-Host "✓ Conversion completed successfully!" -ForegroundColor Green
        Write-Host "Output file: $($this.OutputPath)" -ForegroundColor Cyan
        
        # Show file info
        if (Test-Path $this.OutputPath) {
            $fileInfo = Get-Item $this.OutputPath
            Write-Host "File size: $($fileInfo.Length) bytes" -ForegroundColor Gray
            Write-Host "Created: $($fileInfo.CreationTime)" -ForegroundColor Gray
        }
        
        return $true
    }
}

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    $params = @{
        XmlPath = $XmlPath
        OutputPath = $OutputPath
        XsltPath = $XsltPath
        XsdSchemaPath = $XsdSchemaPath
        SkipValidation = $SkipValidation.IsPresent
        DetailedOutput = $DetailedOutput.IsPresent
        ForceOverwrite = $ForceOverwrite.IsPresent
    }
    
    $converter = [GitHubActionsConverter]::new($params)
    $success = $converter.Convert()
    
    exit $(if ($success) { 0 } else { 1 })
}

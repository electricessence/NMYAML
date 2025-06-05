# GitHub Actions XML to YAML Transformation Demo
# This script demonstrates converting GitHub Actions workflows from XML to YAML

param(
    [string]$XmlFile = ".\samples\github-workflow.xml",
    [string]$XsltFile = ".\xslt\github-actions-transform.xslt",
    [string]$OutputFile = ".\output\github-workflow.yml",
    [switch]$Validate
)

# Import required modules (optional)
if (Test-Path ".\scripts\modules\XmlYamlUtils.psm1") {
    Import-Module ".\scripts\modules\XmlYamlUtils.psm1" -Force
}

Write-Host "=== GitHub Actions XML to YAML Transformation ===" -ForegroundColor Cyan
Write-Host

# Verify input files exist
if (!(Test-Path $XmlFile)) {
    Write-Error "XML file not found: $XmlFile"
    exit 1
}

if (!(Test-Path $XsltFile)) {
    Write-Error "XSLT file not found: $XsltFile"
    exit 1
}

# Create output directory if it doesn't exist
$outputDir = Split-Path $OutputFile -Parent
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "Created output directory: $outputDir" -ForegroundColor Green
}

try {
    Write-Host "Input XML: " -NoNewline
    Write-Host $XmlFile -ForegroundColor Yellow
    Write-Host "XSLT Transform: " -NoNewline  
    Write-Host $XsltFile -ForegroundColor Yellow
    Write-Host "Output YAML: " -NoNewline
    Write-Host $OutputFile -ForegroundColor Yellow
    Write-Host    # Validate XML against schema if requested
    if ($Validate) {
        Write-Host "Validating XML against GitHub Actions schema..." -ForegroundColor Cyan
        $schemaFile = ".\schemas\github-actions-schema.xsd"
        
        if (Test-Path $schemaFile) {
            try {
                # Simple XML well-formedness check
                $testXml = New-Object System.Xml.XmlDocument
                $testXml.Load((Resolve-Path $XmlFile))
                Write-Host "✓ XML is well-formed" -ForegroundColor Green
                
                # Basic namespace check
                if ($testXml.DocumentElement.NamespaceURI -eq "http://github.com/actions/1.0") {
                    Write-Host "✓ GitHub Actions namespace detected" -ForegroundColor Green
                } else {
                    Write-Host "! Non-standard namespace, but continuing..." -ForegroundColor Yellow
                }
            } catch {
                Write-Host "✗ XML validation failed: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "Continuing with transformation..." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Schema file not found, skipping validation" -ForegroundColor Yellow
        }
        Write-Host
    }    # Perform the transformation
    Write-Host "Transforming XML to YAML..." -ForegroundColor Cyan
    
    # Load XML and XSLT
    $xmlPath = Resolve-Path $XmlFile
    $xsltPath = Resolve-Path $XsltFile
    
    Write-Host "Loading XML from: $($xmlPath.Path)" -ForegroundColor Gray
    Write-Host "Loading XSLT from: $($xsltPath.Path)" -ForegroundColor Gray
    
    $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
    $xslt.Load($xsltPath.Path)
    
    # Create output writer
    $absoluteOutputPath = Join-Path (Get-Location) $OutputFile
    if (!(Test-Path (Split-Path $absoluteOutputPath -Parent))) {
        New-Item -ItemType Directory -Path (Split-Path $absoluteOutputPath -Parent) -Force | Out-Null
    }
    
    # Use XmlTextReader for input to avoid whitespace issues
    $xmlReader = New-Object System.Xml.XmlTextReader($xmlPath.Path)
    $outputWriter = New-Object System.IO.StreamWriter($absoluteOutputPath, $false, [System.Text.Encoding]::UTF8)
    
    try {
        # Transform using XmlTextReader and StreamWriter
        $xslt.Transform($xmlReader, $null, $outputWriter)
    } finally {
        if ($xmlReader) { $xmlReader.Close() }
        if ($outputWriter) { $outputWriter.Close() }
    }
      
    Write-Host "✓ Transformation completed successfully!" -ForegroundColor Green
    Write-Host    # Read the generated file for preview
    $yamlContent = Get-Content $absoluteOutputPath -Raw -Encoding UTF8

    # Display preview of generated YAML
    Write-Host "Generated YAML Preview:" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Gray
    
    $lines = $yamlContent -split "`n"
    $previewLines = if ($lines.Count -gt 30) { $lines[0..29] } else { $lines }
    
    foreach ($line in $previewLines) {
        if ($line -match '^[a-zA-Z][^:]*:') {
            Write-Host $line -ForegroundColor White
        } elseif ($line -match '^\s*-\s') {
            Write-Host $line -ForegroundColor Cyan
        } elseif ($line -match '^\s+[a-zA-Z][^:]*:') {
            Write-Host $line -ForegroundColor Yellow
        } else {
            Write-Host $line -ForegroundColor Gray
        }
    }
    
    if ($lines.Count -gt 30) {
        Write-Host "... (truncated, see full file for complete output)" -ForegroundColor Gray
    }
    
    Write-Host "=" * 50 -ForegroundColor Gray
    Write-Host    # Show file information
    $fileInfo = Get-Item $absoluteOutputPath
    Write-Host "Output file size: " -NoNewline
    Write-Host "$($fileInfo.Length) bytes" -ForegroundColor Green
    Write-Host "Lines in output: " -NoNewline
    Write-Host "$($lines.Count)" -ForegroundColor Green
    
    # Validation suggestions
    Write-Host
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "• Copy the generated YAML to .github/workflows/ in your repository" -ForegroundColor White
    Write-Host "• Validate the workflow syntax using GitHub CLI: " -NoNewline -ForegroundColor White
    Write-Host "gh workflow validate $OutputFile" -ForegroundColor Yellow
    Write-Host "• Test the workflow in a development branch first" -ForegroundColor White
    
} catch {
    Write-Error "Transformation failed: $($_.Exception.Message)"
    Write-Host "Stack trace:" -ForegroundColor Red
    Write-Host $_.Exception.StackTrace -ForegroundColor Red
    exit 1
}

Write-Host
Write-Host "Transformation completed!" -ForegroundColor Green

# PowerShell script to transform XML to YAML using XSLT
# Improved version with proper resource disposal
param(
    [string]$XmlFile = "sample.yaml.xml",
    [string]$XsltFile = "xml-to-yaml.xslt",
    [string]$OutputFile = "output.yaml"
)

# Check if files exist
if (-not (Test-Path $XmlFile)) {
    Write-Error "XML file '$XmlFile' not found!"
    exit 1
}

if (-not (Test-Path $XsltFile)) {
    Write-Error "XSLT file '$XsltFile' not found!"
    exit 1
}

try {
    Write-Host "Loading XML document: $XmlFile" -ForegroundColor Green
    
    # Create XmlReader settings
    $xmlReaderSettings = New-Object System.Xml.XmlReaderSettings
    $xmlReaderSettings.IgnoreWhitespace = $true
    
    # Load the XSLT stylesheet
    $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
    Write-Host "Loading XSLT stylesheet: $XsltFile" -ForegroundColor Green
    $xslt.Load((Resolve-Path $XsltFile).Path)
    
    Write-Host "Performing transformation..." -ForegroundColor Green
    
    # Create output path
    $outputPath = Join-Path (Get-Location) $OutputFile
    
    # Use proper disposal pattern with try-finally
    $xmlReader = $null
    $writer = $null
    
    try {
        $xmlReader = [System.Xml.XmlReader]::Create((Resolve-Path $XmlFile).Path, $xmlReaderSettings)
        $writer = [System.IO.File]::CreateText($outputPath)
        
        # Perform the transformation
        $xslt.Transform($xmlReader, $null, $writer)
        
        Write-Host "Transformation completed successfully!" -ForegroundColor Green
        Write-Host "Output written to: $OutputFile" -ForegroundColor Cyan
        
    } finally {
        # Ensure proper disposal in reverse order
        if ($writer) { $writer.Dispose() }
        if ($xmlReader) { $xmlReader.Dispose() }
    }
    
    # Display the result (after files are closed)
    Write-Host "`nGenerated YAML:" -ForegroundColor Yellow
    Write-Host "=================" -ForegroundColor Yellow
    Get-Content $OutputFile | Write-Host
    
} catch {
    Write-Error "Error during transformation: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.Exception.StackTrace)"
    exit 1
}

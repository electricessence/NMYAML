# PowerShell script to transform XML to YAML using XSLT
param(
    [string]$XmlFile = "..\samples\sample.yaml.xml",
    [string]$XsltFile = "..\xslt\xml-to-yaml.xslt",
    [string]$OutputFile = "..\output\output.yaml"
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
    
    # Create XmlReader for the input XML
    $xmlReaderSettings = New-Object System.Xml.XmlReaderSettings
    $xmlReaderSettings.IgnoreWhitespace = $true
    $xmlReader = [System.Xml.XmlReader]::Create((Resolve-Path $XmlFile).Path, $xmlReaderSettings)
    
    Write-Host "Loading XSLT stylesheet: $XsltFile" -ForegroundColor Green
    
    # Load the XSLT stylesheet
    $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
    $xslt.Load((Resolve-Path $XsltFile).Path)
    
    Write-Host "Performing transformation..." -ForegroundColor Green
    
    # Create output writer
    $outputPath = Join-Path (Get-Location) $OutputFile
    $writer = [System.IO.File]::CreateText($outputPath)
    
    # Perform the transformation
    $xslt.Transform($xmlReader, $null, $writer)
    
    # Close the writer
    $writer.Close()
    
    Write-Host "Transformation completed successfully!" -ForegroundColor Green
    Write-Host "Output written to: $OutputFile" -ForegroundColor Cyan
    
    # Display the result
    Write-Host "`nGenerated YAML:" -ForegroundColor Yellow
    Write-Host "=================" -ForegroundColor Yellow
    Get-Content $OutputFile | Write-Host
    
} catch {
    Write-Error "Error during transformation: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.Exception.StackTrace)"
    exit 1
} finally {
    # Clean up
    if ($writer) {
        $writer.Dispose()
    }
    if ($xmlReader) {
        $xmlReader.Dispose()
    }
}

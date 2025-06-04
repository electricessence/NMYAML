# Simple XML to YAML transform with proper UTF-8 encoding
param(
    [string]$XmlFile = "sample-no-namespace.yaml.xml",
    [string]$XsltFile = "xml-to-yaml-simple.xslt",
    [string]$OutputFile = "output-utf8.yaml"
)

Write-Host "Starting transformation..." -ForegroundColor Green

# Load XML and XSLT
$xml = New-Object System.Xml.XmlDocument
$xml.Load($XmlFile)

$xslt = New-Object System.Xml.Xsl.XslCompiledTransform
$xslt.Load($XsltFile)

# Transform to string
$stringWriter = New-Object System.IO.StringWriter
$xslt.Transform($xml, $null, $stringWriter)

# Write to file with UTF-8 encoding
$result = $stringWriter.ToString()
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($OutputFile, $result, $utf8)

Write-Host "Transformation complete!" -ForegroundColor Green
Write-Host "Output:" -ForegroundColor Yellow
Write-Host $result

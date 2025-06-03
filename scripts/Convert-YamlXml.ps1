# Convert-YamlXml.ps1
# Main script for transforming between YAML and XML formats
param(
    [Parameter(Mandatory=$false)]
    [string]$Mode = "xml-to-yaml", # Options: xml-to-yaml, yaml-to-xml
    
    [Parameter(Mandatory=$false)]
    [string]$XmlFile = "..\samples\sample.yaml.xml",
    
    [Parameter(Mandatory=$false)]
    [string]$XsltFile = "..\xslt\xml-to-yaml-universal.xslt",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "..\output.yaml",
    
    [Parameter(Mandatory=$false)]
    [switch]$ValidateInput,
    
    [Parameter(Mandatory=$false)]
    [string]$XsdFile = "..\schemas\yaml-schema-no-namespace.xsd",
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowOutput,
    
    [Parameter(Mandatory=$false)]
    [switch]$UseNamespaces
)

# Import the modules
$modulesPath = Join-Path $PSScriptRoot "modules"
$utilsModulePath = Join-Path $modulesPath "XmlYamlUtils.psm1"
$terminalModulePath = Join-Path $modulesPath "TerminalOutput.psm1"

if (Test-Path $utilsModulePath) {
    Import-Module $utilsModulePath -Force
} else {
    Write-Error "Module not found at path: $utilsModulePath"
    exit 1
}

if (Test-Path $terminalModulePath) {
    Import-Module $terminalModulePath -Force
} else {
    Write-Error "Module not found at path: $terminalModulePath"
    exit 1
}

# Banner
Write-Banner -Text "XML-YAML Transformation Tool" -ForegroundColor Cyan

# Display mode info
Write-SectionHeader -Text "Configuration" -ForegroundColor Yellow
Write-InfoMessage "Mode: $Mode"

if ($UseNamespaces) {
    Write-InfoMessage "Using XML namespaces: Yes"
} else {
    Write-InfoMessage "Using XML namespaces: No"
}

# Determine default file paths based on namespace preference
if ($UseNamespaces -and $XsdFile -eq "yaml-schema-no-namespace.xsd") {
    $XsdFile = "yaml-schema.xsd"
    Write-InfoMessage "Using namespaced schema: $XsdFile" -NoPrefix $true -ForegroundColor Gray
}

# Validate the input XML if requested
if ($ValidateInput) {
    Write-SectionHeader -Text "XML Validation" -ForegroundColor Magenta
    $validationResult = Test-XmlValidation -XmlFile $XmlFile -XsdFile $XsdFile -Description "Input validation"
    
    if (-not $validationResult.Success) {
        Write-WarningMessage "Validation failed"
        $response = Read-Host "Continue anyway? (y/n)"
        if ($response -ne "y") {
            Write-ErrorMessage "Exiting due to validation failure"
            exit 1
        }
    } else {
        Write-SuccessMessage "XML validation passed"
    }
}

# Perform the transformation
Write-SectionHeader -Text "Transformation" -ForegroundColor Magenta

switch ($Mode) {
    "xml-to-yaml" {
        $result = Convert-XmlToYaml -XmlFile $XmlFile -XsltFile $XsltFile -OutputFile $OutputFile
        
        if ($result.Success) {
            Write-SuccessMessage "Transformation completed successfully"
            if ($ShowOutput) {
                Write-SectionHeader -Text "YAML Output" -ForegroundColor Yellow
                if (Test-Path $OutputFile) {
                    $yamlContent = Get-Content $OutputFile -Raw
                    Write-SyntaxHighlight -Text $yamlContent -Language yaml
                } else {
                    Write-WarningMessage "Output file not found: $OutputFile"
                }
            }
        } else {
            Write-ErrorMessage "Transformation failed: $($result.Error)"
        }
    }
    "yaml-to-xml" {
        Write-WarningMessage "YAML to XML transformation not yet implemented"
        # Future implementation will go here
    }
    default {
        Write-ErrorMessage "Unknown mode: $Mode. Supported modes are: xml-to-yaml, yaml-to-xml"
        exit 1
    }
}

Write-Banner -Text "Operation Completed" -ForegroundColor Green -Width 40 -Character '-'

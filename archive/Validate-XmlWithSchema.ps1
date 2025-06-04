# Validate-XmlWithSchema.ps1
# Simple XML validation script that shows direct validation with XSD schemas

param(
    [Parameter(Mandatory=$false)]
    [string]$XmlFilePath = "..\samples\sample.yaml.xml",
    
    [Parameter(Mandatory=$false)]
    [string]$SchemaFilePath = "..\schemas\yaml-schema.xsd"
)

# Helper function to validate XML against a schema
function Test-XmlWithSchema {
    param(
        [string]$XmlPath,
        [string]$SchemaPath,
        [string]$TargetNamespace = $null
    )
    
    Write-Host "Validating: $XmlPath" -ForegroundColor Yellow
    Write-Host "Against schema: $SchemaPath" -ForegroundColor Yellow
    if ($TargetNamespace) {
        Write-Host "With namespace: $TargetNamespace" -ForegroundColor Yellow
    }
    Write-Host
    
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
        
        # Report results
        if ($validationErrors.Count -eq 0) {
            Write-Host "✅ Validation SUCCESSFUL" -ForegroundColor Green
        } else {
            Write-Host "❌ Validation FAILED" -ForegroundColor Red
            foreach ($error in $validationErrors) {
                Write-Host "  - $error" -ForegroundColor Red
            }
        }
        
        return ($validationErrors.Count -eq 0)
    }
    catch {
        Write-Host "❌ Validation ERROR: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main script starts here
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "               XML Schema Validation" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host

# Resolve paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

# If relative paths are provided, make them absolute
if (-not [System.IO.Path]::IsPathRooted($XmlFilePath)) {
    $XmlFilePath = Join-Path $projectRoot $XmlFilePath.TrimStart("..\")
}
if (-not [System.IO.Path]::IsPathRooted($SchemaFilePath)) {
    $SchemaFilePath = Join-Path $projectRoot $SchemaFilePath.TrimStart("..\")
}

# Determine if schema has namespace
$schemaHasNs = $false
$schemaContent = Get-Content -Path $SchemaFilePath -Raw
if ($schemaContent -match 'targetNamespace\s*=\s*"([^"]+)"') {
    $targetNs = $matches[1]
    $schemaHasNs = $true
}

# Validate the XML
if ($schemaHasNs) {
    Write-Host "Schema has target namespace: $targetNs" -ForegroundColor Yellow
    $result = Test-XmlWithSchema -XmlPath $XmlFilePath -SchemaPath $SchemaFilePath -TargetNamespace $targetNs
} else {
    Write-Host "Schema has no target namespace" -ForegroundColor Yellow
    $result = Test-XmlWithSchema -XmlPath $XmlFilePath -SchemaPath $SchemaFilePath
}

Write-Host
if ($result) {
    Write-Host "XML validation against the schema was successful." -ForegroundColor Green
} else {
    Write-Host "XML validation against the schema failed." -ForegroundColor Red
}

Write-Host
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "               Validation Complete" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# Manage-YamlSchema.ps1
# Script for managing YAML XML schemas
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("test", "combine")]
    [string]$Action = "test",
    
    [Parameter(Mandatory=$false)]
    [string]$NamespacedSchemaPath = "..\schemas\yaml-schema.xsd",
    
    [Parameter(Mandatory=$false)]
    [string]$NonNamespacedSchemaPath = "..\schemas\yaml-schema-no-namespace.xsd",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputSchemaPath = "..\schemas\yaml-schema-combined.xsd",
    
    [Parameter(Mandatory=$false)]
    [string]$NamespacedXmlPath = "..\samples\sample.yaml.xml",
    
    [Parameter(Mandatory=$false)]
    [string]$NonNamespacedXmlPath = "..\samples\sample-no-namespace.yaml.xml"
)

# Import the modules
$modulesPath = Join-Path $PSScriptRoot "modules"
$schemaModulePath = Join-Path $modulesPath "XmlYamlSchema.psm1"
$terminalModulePath = Join-Path $modulesPath "TerminalOutput.psm1"

if (Test-Path $schemaModulePath) {
    Import-Module $schemaModulePath -Force
} else {
    Write-Error "Module not found at path: $schemaModulePath"
    exit 1
}

if (Test-Path $terminalModulePath) {
    Import-Module $terminalModulePath -Force
} else {
    Write-Error "Module not found at path: $terminalModulePath"
    exit 1
}

# Banner
Write-Banner -Text "YAML XML Schema Manager" -ForegroundColor Cyan
Write-InfoMessage "Action: $Action" -ForegroundColor Yellow

# Perform the requested action
switch ($Action) {
    "test" {
        Write-SectionHeader -Text "Schema Flexibility Testing" -ForegroundColor Magenta
          # Test the namespaced schema
        Write-SectionHeader -Text "[1] Testing Namespaced Schema" -ForegroundColor Yellow -LeadingNewLine:$false
        $nsSchemaResult = Test-SchemaFlexibility -SchemaPath $NamespacedSchemaPath -NamespacedXmlPath $NamespacedXmlPath -NonNamespacedXmlPath $NonNamespacedXmlPath
        
        # Test the non-namespaced schema
        Write-SectionHeader -Text "[2] Testing Non-namespaced Schema" -ForegroundColor Yellow
        $nonNsSchemaResult = Test-SchemaFlexibility -SchemaPath $NonNamespacedSchemaPath -NamespacedXmlPath $NamespacedXmlPath -NonNamespacedXmlPath $NonNamespacedXmlPath
        
        # Test the combined schema if it exists
        if (Test-Path $OutputSchemaPath) {
            Write-SectionHeader -Text "[3] Testing Combined Schema" -ForegroundColor Yellow
            $combinedSchemaResult = Test-SchemaFlexibility -SchemaPath $OutputSchemaPath -NamespacedXmlPath $NamespacedXmlPath -NonNamespacedXmlPath $NonNamespacedXmlPath
        }
        
        # Prepare data for table output
        $tableData = @(
            [PSCustomObject]@{
                SchemaType = "Namespaced"
                SchemaPath = $NamespacedSchemaPath
                IsFlexible = $nsSchemaResult.IsFlexible
                Status = if ($nsSchemaResult.IsFlexible) { "Flexible" } else { "Not Flexible" }
            },
            [PSCustomObject]@{
                SchemaType = "Non-namespaced"
                SchemaPath = $NonNamespacedSchemaPath
                IsFlexible = $nonNsSchemaResult.IsFlexible
                Status = if ($nonNsSchemaResult.IsFlexible) { "Flexible" } else { "Not Flexible" }
            }
        )
        
        if (Test-Path $OutputSchemaPath) {
            $tableData += [PSCustomObject]@{
                SchemaType = "Combined"
                SchemaPath = $OutputSchemaPath
                IsFlexible = $combinedSchemaResult.IsFlexible
                Status = if ($combinedSchemaResult.IsFlexible) { "Flexible" } else { "Not Flexible" }
            }
        }
        
        # Summary
        Write-SectionHeader -Text "Schema Flexibility Summary" -ForegroundColor Cyan
        Write-ConsoleTable -Data $tableData -Properties SchemaType,SchemaPath,Status -Title "Schema Flexibility Results"
    }    "combine" {
        Write-SectionHeader -Text "Schema Combination" -ForegroundColor Magenta
        
        # Show activity spinner for combining schemas
        $result = Show-ActivitySpinner -Message "Combining schemas..." -ScriptBlock {
            param($ns, $nonNs, $out)
            New-CombinedSchema -NamespacedSchemaPath $ns -NonNamespacedSchemaPath $nonNs -OutputSchemaPath $out
        } 
        
        if ($result) {
            Write-SuccessMessage "Schemas combined successfully to $OutputSchemaPath"
            
            Write-InfoMessage "Would you like to test the combined schema now? (y/n)" -ForegroundColor Yellow
            $response = Read-Host
            if ($response -eq "y") {                Write-SectionHeader -Text "Combined Schema Testing" -ForegroundColor Magenta
                $combinedSchemaResult = Test-SchemaFlexibility -SchemaPath $OutputSchemaPath -NamespacedXmlPath $NamespacedXmlPath -NonNamespacedXmlPath $NonNamespacedXmlPath
                
                # Show test results
                if ($combinedSchemaResult.IsFlexible) {
                    Write-SuccessMessage "Combined schema is flexible - can validate both namespaced and non-namespaced XML"
                } else {
                    Write-ErrorMessage "Combined schema is not flexible - validation issues detected"
                    Write-InfoMessage "See detailed results above" -ForegroundColor Gray
                }
            }
        } else {
            Write-ErrorMessage "Failed to create combined schema"
        }
    }
    default {
        Write-ErrorMessage "Unknown action: $Action. Supported actions are: test, combine"
    }
}

Write-Banner -Text "Operation Completed" -ForegroundColor Green -Width 40 -Character '-'

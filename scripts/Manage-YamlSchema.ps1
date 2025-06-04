# Manage-YamlSchema.ps1
# Script for managing YAML XML schemas
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("test", "combine", "convert")]
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

Import-Module $schemaModulePath -ErrorAction Stop
Import-Module $terminalModulePath -ErrorAction Stop

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
        }    }
    "convert" {
        Write-SectionHeader -Text "Schema Namespace Conversion" -ForegroundColor Magenta
        
        # Check if Convert-NamespacedSchema.ps1 exists
        $converterScript = Join-Path $PSScriptRoot "Convert-NamespacedSchema.ps1"
        if (-not (Test-Path $converterScript)) {
            Write-ErrorMessage "Schema converter script not found at: $converterScript"
            exit 1
        }
          # Get absolute paths for schema files
        $projectRoot = Split-Path -Parent $PSScriptRoot
        $absNamespacedPath = Join-Path $projectRoot $NamespacedSchemaPath.TrimStart("..\")
        $absNonNamespacedPath = Join-Path $projectRoot $NonNamespacedSchemaPath.TrimStart("..\")
          # Ask if the user wants to generate a conversion report
        Write-InfoMessage "Would you like to generate a detailed conversion report? (y/n)" -ForegroundColor Yellow
        $generateReport = Read-Host
        
        # Set up report parameters
        $reportParams = @{}
        if ($generateReport -eq "y") {
            $reportParams = @{
                GenerateReport = $true
                ReportPath = Join-Path $projectRoot "schemas\conversion-report.xml"
            }
        }
        
        # Run the conversion script with absolute paths
        Write-InfoMessage "Converting namespaced schema to non-namespaced version..."
        & $converterScript -InputSchemaPath $absNamespacedPath -OutputSchemaPath $absNonNamespacedPath @reportParams
        
        # Ask if user wants to test the schemas after conversion
        Write-InfoMessage "Would you like to test the schemas now? (y/n)" -ForegroundColor Yellow
        $response = Read-Host
        if ($response -eq "y") {
            Write-SectionHeader -Text "Schema Testing After Conversion" -ForegroundColor Yellow
              # Get absolute paths for XML files
            $absNamespacedXmlPath = Join-Path $projectRoot $NamespacedXmlPath.TrimStart("..\")
            $absNonNamespacedXmlPath = Join-Path $projectRoot $NonNamespacedXmlPath.TrimStart("..\")
            
            # Run the test action logic with absolute paths
            $nsSchemaResult = Test-SchemaFlexibility -SchemaPath $absNamespacedPath -NamespacedXmlPath $absNamespacedXmlPath -NonNamespacedXmlPath $absNonNamespacedXmlPath
            $nonNsSchemaResult = Test-SchemaFlexibility -SchemaPath $absNonNamespacedPath -NamespacedXmlPath $absNamespacedXmlPath -NonNamespacedXmlPath $absNonNamespacedXmlPath
            
            # Prepare data for table output            # For display, use relative paths
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
            
            # Summary
            Write-SectionHeader -Text "Schema Flexibility Summary" -ForegroundColor Cyan
            Write-ConsoleTable -Data $tableData -Properties SchemaType,SchemaPath,Status -Title "Schema Flexibility Results"
        }
    }
    default {
        Write-ErrorMessage "Unknown action: $Action. Supported actions are: test, combine, convert"
    }
}

Write-Banner -Text "Operation Completed" -ForegroundColor Green -Width 40 -Character '-'

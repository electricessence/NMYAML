# Compare-XmlSchemas.ps1
# Script for comparing XML Schema files to verify equivalence

param(
    [Parameter(Mandatory=$true)]
    [string]$Schema1Path,
    
    [Parameter(Mandatory=$true)]
    [string]$Schema2Path,
    
    [Parameter(Mandatory=$false)]
    [switch]$CompareStructureOnly = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$IgnoreNamespaces = $true
)

# Import modules
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesDir = Join-Path $scriptDir "modules"
$terminalOutputModule = Join-Path $modulesDir "TerminalOutput.psm1"

if (Test-Path $terminalOutputModule) {
    Import-Module $terminalOutputModule -Force
} else {
    Write-Error "Terminal Output module not found at $terminalOutputModule"
    exit 1
}

Write-Banner -Text "XML Schema Comparison Tool" -ForegroundColor Cyan

# Check if files exist
if (-not (Test-Path $Schema1Path)) {
    Write-ErrorMessage "Schema file not found: $Schema1Path"
    exit 1
}

if (-not (Test-Path $Schema2Path)) {
    Write-ErrorMessage "Schema file not found: $Schema2Path"
    exit 1
}

# Load the schemas
try {
    Write-InfoMessage "Loading schema files..."
    [xml]$schema1 = Get-Content -Path $Schema1Path -Raw
    [xml]$schema2 = Get-Content -Path $Schema2Path -Raw
    Write-SuccessMessage "Schemas loaded successfully"
} catch {
    Write-ErrorMessage "Failed to load schema files: $($_.Exception.Message)"
    exit 1
}

# Helper function to create a normalized representation of a schema
function Get-NormalizedSchemaStructure {
    param (
        [Parameter(Mandatory=$true)]
        [System.Xml.XmlDocument]$Schema,
        
        [Parameter(Mandatory=$false)]
        [switch]$IgnoreNamespaces = $false
    )
    
    # Create a hashtable to store schema elements and their properties
    $schemaStructure = @{
        RootElements = @()
        ComplexTypes = @{}
        SimpleTypes = @{}
        Groups = @{}
        AttributeGroups = @{}
    }
    
    # Extract root elements
    $elements = $Schema.GetElementsByTagName("element") | Where-Object { $_.ParentNode.LocalName -eq "schema" }
    foreach ($element in $elements) {
        $name = $element.GetAttribute("name")
        if (-not [string]::IsNullOrEmpty($name)) {
            # If ignoring namespaces, remove any namespace prefix
            if ($IgnoreNamespaces) {
                $name = $name -replace ".*:", ""
            }
            
            $schemaStructure.RootElements += @{
                Name = $name
                Type = $element.GetAttribute("type")
                HasComplexType = ($element.GetElementsByTagName("complexType").Count -gt 0)
                HasSimpleType = ($element.GetElementsByTagName("simpleType").Count -gt 0)
            }
        }
    }
    
    # Extract complex types
    $complexTypes = $Schema.GetElementsByTagName("complexType") | Where-Object { $_.ParentNode.LocalName -eq "schema" }
    foreach ($complexType in $complexTypes) {
        $name = $complexType.GetAttribute("name")
        if (-not [string]::IsNullOrEmpty($name)) {
            # If ignoring namespaces, remove any namespace prefix
            if ($IgnoreNamespaces) {
                $name = $name -replace ".*:", ""
            }
            
            $sequenceElements = @()
            $choiceElements = @()
            $attributes = @()
            
            # Get sequence elements
            $sequences = $complexType.GetElementsByTagName("sequence")
            foreach ($sequence in $sequences) {
                $sequenceElements += $sequence.GetElementsByTagName("element") | ForEach-Object {
                    @{
                        Name = $_.GetAttribute("name")
                        Type = $_.GetAttribute("type")
                        Ref = $_.GetAttribute("ref") -replace ".*:", ""
                        MinOccurs = $_.GetAttribute("minOccurs")
                        MaxOccurs = $_.GetAttribute("maxOccurs")
                    }
                }
            }
            
            # Get choice elements
            $choices = $complexType.GetElementsByTagName("choice")
            foreach ($choice in $choices) {
                $choiceElements += $choice.GetElementsByTagName("element") | ForEach-Object {
                    @{
                        Name = $_.GetAttribute("name")
                        Type = $_.GetAttribute("type")
                        Ref = $_.GetAttribute("ref") -replace ".*:", ""
                        MinOccurs = $_.GetAttribute("minOccurs")
                        MaxOccurs = $_.GetAttribute("maxOccurs")
                    }
                }
            }
            
            # Get attributes
            $attributeList = $complexType.GetElementsByTagName("attribute")
            foreach ($attribute in $attributeList) {
                $attributes += @{
                    Name = $attribute.GetAttribute("name")
                    Type = $attribute.GetAttribute("type")
                    Use = $attribute.GetAttribute("use")
                }
            }
            
            $schemaStructure.ComplexTypes[$name] = @{
                SequenceElements = $sequenceElements
                ChoiceElements = $choiceElements
                Attributes = $attributes
            }
        }
    }
    
    # Extract simple types
    $simpleTypes = $Schema.GetElementsByTagName("simpleType") | Where-Object { $_.ParentNode.LocalName -eq "schema" }
    foreach ($simpleType in $simpleTypes) {
        $name = $simpleType.GetAttribute("name")
        if (-not [string]::IsNullOrEmpty($name)) {
            # If ignoring namespaces, remove any namespace prefix
            if ($IgnoreNamespaces) {
                $name = $name -replace ".*:", ""
            }
            
            $restrictions = @()
            
            # Get restrictions
            $restrictionList = $simpleType.GetElementsByTagName("restriction")
            foreach ($restriction in $restrictionList) {
                $base = $restriction.GetAttribute("base")
                $enumerations = $restriction.GetElementsByTagName("enumeration") | ForEach-Object {
                    $_.GetAttribute("value")
                }
                
                $patterns = $restriction.GetElementsByTagName("pattern") | ForEach-Object {
                    $_.GetAttribute("value")
                }
                
                $restrictions += @{
                    Base = $base
                    Enumerations = $enumerations
                    Patterns = $patterns
                }
            }
            
            $schemaStructure.SimpleTypes[$name] = @{
                Restrictions = $restrictions
            }
        }
    }
    
    return $schemaStructure
}

# Compare schemas
Write-SectionHeader -Text "Comparing Schema Structures" -ForegroundColor Yellow

$schema1Structure = Get-NormalizedSchemaStructure -Schema $schema1 -IgnoreNamespaces:$IgnoreNamespaces
$schema2Structure = Get-NormalizedSchemaStructure -Schema $schema2 -IgnoreNamespaces:$IgnoreNamespaces

# Compare root elements
Write-InfoMessage "Comparing root elements..."
$rootElements1 = ($schema1Structure.RootElements | ForEach-Object { $_.Name }) | Sort-Object
$rootElements2 = ($schema2Structure.RootElements | ForEach-Object { $_.Name }) | Sort-Object

$rootElementsEqual = $null -eq (Compare-Object -ReferenceObject $rootElements1 -DifferenceObject $rootElements2)

if ($rootElementsEqual) {
    Write-SuccessMessage "Root elements match"
} else {
    Write-WarningMessage "Root elements differ"
    $differences = Compare-Object -ReferenceObject $rootElements1 -DifferenceObject $rootElements2
    
    $onlyInSchema1 = $differences | Where-Object { $_.SideIndicator -eq "<=" } | ForEach-Object { $_.InputObject }
    $onlyInSchema2 = $differences | Where-Object { $_.SideIndicator -eq "=>" } | ForEach-Object { $_.InputObject }
    
    if ($onlyInSchema1.Count -gt 0) {
        Write-InfoMessage "Elements only in $Schema1Path:" -NoPrefix:$true -ForegroundColor Yellow
        foreach ($element in $onlyInSchema1) {
            Write-InfoMessage "  - $element" -NoPrefix:$true -ForegroundColor Gray
        }
    }
    
    if ($onlyInSchema2.Count -gt 0) {
        Write-InfoMessage "Elements only in $Schema2Path:" -NoPrefix:$true -ForegroundColor Yellow
        foreach ($element in $onlyInSchema2) {
            Write-InfoMessage "  - $element" -NoPrefix:$true -ForegroundColor Gray
        }
    }
}

# Compare complex types
Write-InfoMessage "Comparing complex types..."
$complexTypes1 = $schema1Structure.ComplexTypes.Keys | Sort-Object
$complexTypes2 = $schema2Structure.ComplexTypes.Keys | Sort-Object

$complexTypesEqual = $null -eq (Compare-Object -ReferenceObject $complexTypes1 -DifferenceObject $complexTypes2)

if ($complexTypesEqual) {
    Write-SuccessMessage "Complex types match"
} else {
    Write-WarningMessage "Complex types differ"
    $differences = Compare-Object -ReferenceObject $complexTypes1 -DifferenceObject $complexTypes2
    
    $onlyInSchema1 = $differences | Where-Object { $_.SideIndicator -eq "<=" } | ForEach-Object { $_.InputObject }
    $onlyInSchema2 = $differences | Where-Object { $_.SideIndicator -eq "=>" } | ForEach-Object { $_.InputObject }
    
    if ($onlyInSchema1.Count -gt 0) {
        Write-InfoMessage "Complex types only in $Schema1Path:" -NoPrefix:$true -ForegroundColor Yellow
        foreach ($type in $onlyInSchema1) {
            Write-InfoMessage "  - $type" -NoPrefix:$true -ForegroundColor Gray
        }
    }
    
    if ($onlyInSchema2.Count -gt 0) {
        Write-InfoMessage "Complex types only in $Schema2Path:" -NoPrefix:$true -ForegroundColor Yellow
        foreach ($type in $onlyInSchema2) {
            Write-InfoMessage "  - $type" -NoPrefix:$true -ForegroundColor Gray
        }
    }
}

# Compare simple types
Write-InfoMessage "Comparing simple types..."
$simpleTypes1 = $schema1Structure.SimpleTypes.Keys | Sort-Object
$simpleTypes2 = $schema2Structure.SimpleTypes.Keys | Sort-Object

$simpleTypesEqual = $null -eq (Compare-Object -ReferenceObject $simpleTypes1 -DifferenceObject $simpleTypes2)

if ($simpleTypesEqual) {
    Write-SuccessMessage "Simple types match"
} else {
    Write-WarningMessage "Simple types differ"
    $differences = Compare-Object -ReferenceObject $simpleTypes1 -DifferenceObject $simpleTypes2
    
    $onlyInSchema1 = $differences | Where-Object { $_.SideIndicator -eq "<=" } | ForEach-Object { $_.InputObject }
    $onlyInSchema2 = $differences | Where-Object { $_.SideIndicator -eq "=>" } | ForEach-Object { $_.InputObject }
    
    if ($onlyInSchema1.Count -gt 0) {
        Write-InfoMessage "Simple types only in $Schema1Path:" -NoPrefix:$true -ForegroundColor Yellow
        foreach ($type in $onlyInSchema1) {
            Write-InfoMessage "  - $type" -NoPrefix:$true -ForegroundColor Gray
        }
    }
    
    if ($onlyInSchema2.Count -gt 0) {
        Write-InfoMessage "Simple types only in $Schema2Path:" -NoPrefix:$true -ForegroundColor Yellow
        foreach ($type in $onlyInSchema2) {
            Write-InfoMessage "  - $type" -NoPrefix:$true -ForegroundColor Gray
        }
    }
}

# Overall comparison result
$overallEqual = $rootElementsEqual -and $complexTypesEqual -and $simpleTypesEqual

Write-SectionHeader -Text "Comparison Summary" -ForegroundColor Cyan

if ($overallEqual) {
    Write-SuccessMessage "The schemas are equivalent in structure"
} else {
    Write-WarningMessage "The schemas differ in structure"
    
    # Create a summary table
    $summaryData = @(
        [PSCustomObject]@{
            Component = "Root Elements"
            Status = if ($rootElementsEqual) { "Match" } else { "Different" }
            Schema1Count = $rootElements1.Count
            Schema2Count = $rootElements2.Count
        },
        [PSCustomObject]@{
            Component = "Complex Types"
            Status = if ($complexTypesEqual) { "Match" } else { "Different" }
            Schema1Count = $complexTypes1.Count
            Schema2Count = $complexTypes2.Count
        },
        [PSCustomObject]@{
            Component = "Simple Types"
            Status = if ($simpleTypesEqual) { "Match" } else { "Different" }
            Schema1Count = $simpleTypes1.Count
            Schema2Count = $simpleTypes2.Count
        }
    )
    
    Write-ConsoleTable -Data $summaryData -Properties Component,Status,Schema1Count,Schema2Count -Title "Comparison Summary"
}

Write-Banner -Text "Comparison Completed" -ForegroundColor Green -Width 40 -Character '-'

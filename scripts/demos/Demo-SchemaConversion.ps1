# Demo-SchemaConversion.ps1
# A simplified demonstration of schema conversion with minimal dependencies

param(
    [Parameter(Mandatory=$false)]
    [string]$InputSchemaPath = "..\schemas\yaml-schema.xsd",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputSchemaPath = "..\schemas\yaml-schema-no-namespace.xsd",
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowDifferences = $true
)

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "      XML SCHEMA NAMESPACE CONVERSION DEMO" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host

# Resolve full paths
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

# Resolve input path
if (-not [System.IO.Path]::IsPathRooted($InputSchemaPath)) {
    $InputSchemaPath = Join-Path $projectRoot $InputSchemaPath.TrimStart("..\")
}

# Resolve output path
if (-not [System.IO.Path]::IsPathRooted($OutputSchemaPath)) {
    $OutputSchemaPath = Join-Path $projectRoot $OutputSchemaPath.TrimStart("..\")
}

Write-Host "Input Schema: $InputSchemaPath" -ForegroundColor Yellow
Write-Host "Output Schema: $OutputSchemaPath" -ForegroundColor Yellow
Write-Host

# Create backup of the output file
$backupFile = "$OutputSchemaPath.backup"
Write-Host "Creating backup: $backupFile" -ForegroundColor Gray
Copy-Item -Path $OutputSchemaPath -Destination $backupFile -Force

# Load the schema
try {
    Write-Host "LOADING SOURCE SCHEMA" -ForegroundColor Green
    [xml]$schema = Get-Content -Path $InputSchemaPath -Raw
    Write-Host "Schema loaded successfully" -ForegroundColor Green
} 
catch {
    Write-Host "Failed to load schema: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Track changes
$changes = @()

# Process the schema
try {
    Write-Host "`nCONVERTING SCHEMA" -ForegroundColor Green
    
    # Remove targetNamespace attribute from root element
    if ($schema.schema.targetNamespace) {
        $targetNs = $schema.schema.targetNamespace
        Write-Host "Removing targetNamespace attribute" -ForegroundColor Yellow
        $schema.schema.RemoveAttribute("targetNamespace")
        
        # Track the change
        $changes += @{
            ChangeType = "RemoveTargetNamespace"
            Element = "schema"
            OriginalValue = $targetNs
        }
    }
    
    # Remove namespace prefix from the xmlns declaration
    if ($schema.schema.GetAttribute("xmlns:yaml")) {
        $yamlNs = $schema.schema.GetAttribute("xmlns:yaml")
        Write-Host "Removing namespace prefix declaration" -ForegroundColor Yellow
        $schema.schema.RemoveAttribute("xmlns:yaml")
        
        # Track the change
        $changes += @{
            ChangeType = "RemoveNamespaceDeclaration"
            Element = "schema"
            OriginalValue = "xmlns:yaml='$yamlNs'"
        }
    }
    
    # Process all element references with namespace prefixes
    Write-Host "Processing element references and names..." -ForegroundColor Yellow
    
    # Recursive function to process nodes
    function ProcessNodes($node, $nodePath = "/xs:schema") {
        # Process this node's attributes
        if ($node.Attributes -ne $null) {
            # Handle 'ref' attributes that use the namespace
            if ($node.Attributes["ref"] -ne $null) {
                $refValue = $node.Attributes["ref"].Value
                if ($refValue.Contains("yaml:")) {
                    $newRefValue = $refValue -replace "yaml:", ""
                    $node.Attributes["ref"].Value = $newRefValue
                    Write-Host "  Converted ref: $refValue → $newRefValue" -ForegroundColor Gray
                    
                    # Track the change
                    $changes += @{
                        ChangeType = "ConvertReference"
                        Element = $node.LocalName
                        OriginalValue = $refValue
                        NewValue = $newRefValue
                        Path = $nodePath
                    }
                }
            }
            
            # Handle 'name' attributes for elements that had namespace prefixes
            # This is specific to this schema conversion and may need adjustments for other schemas
            if ($node.LocalName -eq "element" -and $node.Attributes["name"] -ne $null -and $node.ParentNode.LocalName -eq "schema") {
                $elemName = $node.Attributes["name"].Value
                Write-Host "  Processing root element: $elemName" -ForegroundColor Gray
                
                # Track the change
                $changes += @{
                    ChangeType = "ProcessRootElement"
                    Element = "element"
                    OriginalValue = $elemName
                    Path = "$nodePath/xs:element[@name='$elemName']"
                }
            }
        }
        
        # Process child nodes recursively
        if ($node.HasChildNodes) {
            foreach ($child in $node.ChildNodes) {
                # Skip text/comment nodes
                if ($child.NodeType -eq [System.Xml.XmlNodeType]::Element) {
                    # Calculate child path for better reporting
                    $childPath = "$nodePath/$($child.LocalName)"
                    if ($child.Attributes["name"] -ne $null) {
                        $childPath += "[@name='$($child.Attributes["name"].Value)']"
                    }
                    
                    ProcessNodes $child $childPath
                }
            }
        }
    }
    
    # Start the recursive processing with the root
    ProcessNodes $schema.DocumentElement
    
    # Save the modified schema
    Write-Host "`nSAVING NON-NAMESPACED SCHEMA" -ForegroundColor Green
    
    # Create XmlWriterSettings
    $writerSettings = New-Object System.Xml.XmlWriterSettings
    $writerSettings.Indent = $true
    $writerSettings.IndentChars = "  "
    $writerSettings.Encoding = [System.Text.UTF8Encoding]::new($false) # UTF8 without BOM
    
    # Use XmlWriter to save the document
    $writer = [System.Xml.XmlWriter]::Create($OutputSchemaPath, $writerSettings)
    try {
        $schema.Save($writer)
        Write-Host "Schema saved to $OutputSchemaPath" -ForegroundColor Green
    }
    finally {
        $writer.Close()
    }
    
    # Additional post-processing to fix any remaining namespace issues
    Write-Host "Performing post-processing to clean up remaining namespace references" -ForegroundColor Yellow
    $content = Get-Content -Path $OutputSchemaPath -Raw
    
    # Replace any remaining yaml: namespace references
    $content = $content -replace "yaml:", ""
    
    # Save the final cleaned content
    $utf8NoBomEncoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($OutputSchemaPath, $content, $utf8NoBomEncoding)
    
    Write-Host "Post-processing completed" -ForegroundColor Green
    
} catch {
    Write-Host "Error during schema conversion: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Final validation check
Write-Host "`nVALIDATING OUTPUT SCHEMA" -ForegroundColor Green
try {
    [xml]$outputSchema = Get-Content -Path $OutputSchemaPath -Raw
    Write-Host "Output schema is valid XML" -ForegroundColor Green
    
    # Count elements in both schemas as a sanity check
    $inputElemCount = ($schema.GetElementsByTagName("*") | Measure-Object).Count
    $outputElemCount = ($outputSchema.GetElementsByTagName("*") | Measure-Object).Count
    
    Write-Host "Source schema element count: $inputElemCount" -ForegroundColor Yellow
    Write-Host "Output schema element count: $outputElemCount" -ForegroundColor Yellow
    
    if ($inputElemCount -eq $outputElemCount) {
        Write-Host "Element counts match" -ForegroundColor Green
    } else {
        Write-Host "Element counts differ. This might be expected due to namespace changes, but verify the output." -ForegroundColor DarkYellow
    }
    
} catch {
    Write-Host "Output schema validation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Generate conversion report
Write-Host "`nCONVERSION REPORT" -ForegroundColor Green
Write-Host "Total changes made: $($changes.Count)" -ForegroundColor Yellow

# Group changes by type
$changesByType = $changes | Group-Object -Property ChangeType

# Display summary
Write-Host "`nChanges by type:" -ForegroundColor Yellow
foreach ($changeGroup in $changesByType) {
    Write-Host "  $($changeGroup.Name): $($changeGroup.Count) changes" -ForegroundColor Cyan
    
    # Show a sample of changes for each type (limited to 3)
    $sampleChanges = $changeGroup.Group | Select-Object -First 3
    foreach ($change in $sampleChanges) {
        Write-Host "    - $($change.Element)" -ForegroundColor Gray -NoNewline
        
        if ($change.OriginalValue -and $change.NewValue) {
            Write-Host ": $($change.OriginalValue) → $($change.NewValue)" -ForegroundColor Gray
        }
        elseif ($change.OriginalValue) {
            Write-Host ": $($change.OriginalValue)" -ForegroundColor Gray
        }
        else {
            Write-Host "" -ForegroundColor Gray
        }
    }
    
    # Show if there are more changes
    if ($changeGroup.Count -gt 3) {
        Write-Host "    (and $($changeGroup.Count - 3) more...)" -ForegroundColor DarkGray
    }
}

Write-Host "`n======================================================" -ForegroundColor Green
Write-Host "          CONVERSION COMPLETE" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green

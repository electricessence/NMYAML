# Convert-NamespacedSchema.ps1
# Converts a namespaced XML Schema to a non-namespaced version

param(
    [Parameter(Mandatory=$false)]
    [string]$InputSchemaPath = "..\schemas\yaml-schema.xsd",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputSchemaPath = "..\schemas\yaml-schema-no-namespace.xsd",
    
    [Parameter(Mandatory=$false)]
    [switch]$Backup = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]$GenerateReport = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$ReportPath = ""
)

# Import modules
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulesDir = Join-Path $scriptDir "modules"
$terminalOutputModule = Join-Path $modulesDir "TerminalOutput.psm1"
$reportModulePath = Join-Path $modulesDir "SchemaConversionReport.psm1"

Import-Module $terminalOutputModule -ErrorAction Stop

# Import the schema conversion report module if it exists
Import-Module $reportModulePath -ErrorAction Stop
if (Get-Command "Clear-ConversionLog" -ErrorAction SilentlyContinue) {
    Clear-ConversionLog  # Initialize a clean log
} else {
    Write-Warning "Schema Conversion Report module not found. Detailed reporting will be disabled."
    $GenerateReport = $false
}

# Display banner
Write-Banner -Text "Namespaced to Non-Namespaced Schema Converter" -ForegroundColor Cyan

# Resolve full paths - ensure they are resolved relative to the script directory
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

Write-InfoMessage "Input Schema: $InputSchemaPath"
Write-InfoMessage "Output Schema: $OutputSchemaPath"

# Create backup if requested
if ($Backup -and (Test-Path $OutputSchemaPath)) {
    $backupFile = "$OutputSchemaPath.backup"
    Write-InfoMessage "Creating backup: $backupFile"
    Copy-Item -Path $OutputSchemaPath -Destination $backupFile -Force
}

# Load the schema
try {
    Write-SectionHeader -Text "Loading Source Schema" -ForegroundColor Yellow
    [xml]$schema = Get-Content -Path $InputSchemaPath -Raw
    Write-SuccessMessage "Schema loaded successfully"
} catch {
    Write-ErrorMessage "Failed to load schema: $($_.Exception.Message)"
    exit 1
}

# Process the schema
try {
    Write-SectionHeader -Text "Converting Schema" -ForegroundColor Yellow
      # Remove targetNamespace attribute from root element
    if ($schema.schema.targetNamespace) {
        $targetNs = $schema.schema.targetNamespace
        Write-InfoMessage "Removing targetNamespace attribute"
        $schema.schema.RemoveAttribute("targetNamespace")
        
        # Log the change if reporting is enabled
        if ($GenerateReport -and (Get-Command "Add-ConversionLogEntry" -ErrorAction SilentlyContinue)) {
            Add-ConversionLogEntry -ChangeType "RemoveTargetNamespace" -Element "schema" -OriginalValue $targetNs -Path "/xs:schema"
        }
    }
    
    # Remove namespace prefix from the xmlns declaration
    if ($schema.schema.GetAttribute("xmlns:yaml")) {
        $yamlNs = $schema.schema.GetAttribute("xmlns:yaml")
        Write-InfoMessage "Removing namespace prefix declaration"
        $schema.schema.RemoveAttribute("xmlns:yaml")
        
        # Log the change if reporting is enabled
        if ($GenerateReport -and (Get-Command "Add-ConversionLogEntry" -ErrorAction SilentlyContinue)) {
            Add-ConversionLogEntry -ChangeType "RemoveNamespaceDeclaration" -Element "schema" -OriginalValue "xmlns:yaml='$yamlNs'" -Path "/xs:schema"
        }
    }
    
    # Process all element references with namespace prefixes
    Write-InfoMessage "Processing element references and names..."    # Function to recursively process nodes
    function ProcessNodes($node, $nodePath = "/xs:schema") {
        # Process this node's attributes
        if ($node.Attributes -ne $null) {
            # Handle 'ref' attributes that use the namespace
            if ($node.Attributes["ref"] -ne $null) {
                $refValue = $node.Attributes["ref"].Value
                if ($refValue.Contains("yaml:")) {
                    $newRefValue = $refValue -replace "yaml:", ""
                    $node.Attributes["ref"].Value = $newRefValue
                    Write-InfoMessage "  Converted ref: $refValue → $newRefValue"
                    
                    # Log the change if reporting is enabled
                    if ($GenerateReport -and (Get-Command "Add-ConversionLogEntry" -ErrorAction SilentlyContinue)) {
                        $elemType = $node.LocalName
                        Add-ConversionLogEntry -ChangeType "ConvertReference" -Element $elemType -OriginalValue $refValue -NewValue $newRefValue -Path $nodePath
                    }
                }
            }
            
            # Handle 'name' attributes for elements that had namespace prefixes
            # This is specific to this schema conversion and may need adjustments for other schemas
            if ($node.LocalName -eq "element" -and $node.Attributes["name"] -ne $null -and $node.ParentNode.LocalName -eq "schema") {
                $elemName = $node.Attributes["name"].Value
                Write-InfoMessage "  Processing root element: $elemName"
                
                # Log the processing of root elements if reporting is enabled
                if ($GenerateReport -and (Get-Command "Add-ConversionLogEntry" -ErrorAction SilentlyContinue)) {
                    Add-ConversionLogEntry -ChangeType "ProcessRootElement" -Element "element" -OriginalValue $elemName -Path "$nodePath/xs:element[@name='$elemName']"
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
    Write-SectionHeader -Text "Saving Non-namespaced Schema" -ForegroundColor Yellow
    
    # Create XmlWriterSettings
    $writerSettings = New-Object System.Xml.XmlWriterSettings
    $writerSettings.Indent = $true
    $writerSettings.IndentChars = "  "
    $writerSettings.Encoding = [System.Text.UTF8Encoding]::new($false) # UTF8 without BOM
    
    # Use XmlWriter to save the document
    $writer = [System.Xml.XmlWriter]::Create($OutputSchemaPath, $writerSettings)
    try {
        $schema.Save($writer)
        Write-SuccessMessage "Schema saved to $OutputSchemaPath"
    }
    finally {
        $writer.Close()
    }
    
    # Additional post-processing to fix any remaining namespace issues
    Write-InfoMessage "Performing post-processing to clean up remaining namespace references"
    $content = Get-Content -Path $OutputSchemaPath -Raw
    
    # Replace any remaining yaml: namespace references
    $content = $content -replace "yaml:", ""
    
    # Replace xmlns:xs with just xmlns if needed
    # $content = $content -replace "xmlns:xs=", "xmlns="
    
    # Save the final cleaned content
    $utf8NoBomEncoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($OutputSchemaPath, $content, $utf8NoBomEncoding)
    
    Write-SuccessMessage "Post-processing completed"
    
} catch {
    Write-ErrorMessage "Error during schema conversion: $($_.Exception.Message)"
    exit 1
}

# Final validation check
Write-SectionHeader -Text "Validating Output Schema" -ForegroundColor Yellow
try {
    [xml]$outputSchema = Get-Content -Path $OutputSchemaPath -Raw
    Write-SuccessMessage "Output schema is valid XML"
    
    # Count elements in both schemas as a sanity check
    $inputElemCount = ($schema.GetElementsByTagName("*") | Measure-Object).Count
    $outputElemCount = ($outputSchema.GetElementsByTagName("*") | Measure-Object).Count
    
    Write-InfoMessage "Source schema element count: $inputElemCount"
    Write-InfoMessage "Output schema element count: $outputElemCount"
    
    if ($inputElemCount -eq $outputElemCount) {
        Write-InfoMessage "Element counts match" -ForegroundColor Green
    } else {
        Write-WarningMessage "Element counts differ. This might be expected due to namespace changes, but verify the output."
    }
    
} catch {
    Write-ErrorMessage "Output schema validation failed: $($_.Exception.Message)"
}

# Generate conversion report if requested
if ($GenerateReport -and (Get-Command "Get-ConversionSummary" -ErrorAction SilentlyContinue)) {
    Write-SectionHeader -Text "Generating Conversion Report" -ForegroundColor Yellow
    
    # Get summary of changes
    $summary = Get-ConversionSummary
    
    # Display summary
    Write-InfoMessage "Total changes made: $($summary.TotalChanges)"
    
    # Prepare data for table output
    $tableData = $summary.ChangesByType
    Write-ConsoleTable -Data $tableData -Properties Type,Count,Elements -Title "Schema Conversion Changes"
    
    # Export report to XML if path specified
    if (-not [string]::IsNullOrWhiteSpace($ReportPath)) {
        $reportFile = $ReportPath
    } else {
        # Default report path based on output schema
        $reportFile = "$OutputSchemaPath.conversion-report.xml"
    }
    
    Write-InfoMessage "Saving detailed conversion report to: $reportFile"
    Export-ConversionLog -OutputPath $reportFile
    Write-SuccessMessage "Report saved successfully"
}

Write-Banner -Text "Conversion Complete" -ForegroundColor Green -Width 40 -Character '-'

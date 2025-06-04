# Enhanced-Validate-XmlWithSchema.ps1
# Advanced XML validation script with improved error handling for edge cases

param(
    [Parameter(Mandatory=$false)]
    [string]$XmlFilePath = "..\..\samples\sample.yaml.xml",
    
    [Parameter(Mandatory=$false)]
    [string]$SchemaFilePath = "..\..\schemas\yaml-schema.xsd",
    
    [Parameter(Mandatory=$false)]
    [switch]$ForceNamespace = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ForceNoNamespace = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

# Banner
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "        Enhanced XML Schema Validation Utility" -ForegroundColor Cyan  
Write-Host "=========================================================" -ForegroundColor Cyan

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

# Verify files exist
if (-not (Test-Path -Path $XmlFilePath)) {
    Write-Host "Error: XML file not found at path: $XmlFilePath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -Path $SchemaFilePath)) {
    Write-Host "Error: Schema file not found at path: $SchemaFilePath" -ForegroundColor Red
    exit 1
}

# Helper function to check if XML has namespace
function Test-XmlHasNamespace {
    param([string]$XmlPath)
    
    try {
        [xml]$xmlContent = Get-Content -Path $XmlPath -Raw
        $rootElement = $xmlContent.DocumentElement
        
        # Check for any namespace declarations
        $hasNamespace = $rootElement.GetAttribute("xmlns") -or 
                       ($rootElement.Attributes | Where-Object { $_.Name -like "xmlns:*" }).Count -gt 0
                       
        # Also check if any elements use a prefix
        if (-not $hasNamespace) {
            $hasNamespace = $rootElement.OuterXml -match "<[^>]+:"
        }
        
        return $hasNamespace
    }
    catch {
        Write-Host "Error checking namespace in XML: $_" -ForegroundColor Red
        return $false
    }
}

# Helper function to get namespace from XML
function Get-XmlNamespace {
    param([string]$XmlPath)
    
    try {
        [xml]$xmlContent = Get-Content -Path $XmlPath -Raw
        $rootElement = $xmlContent.DocumentElement
        
        # Look for namespace declarations
        $ns = $null
        
        # First check for default namespace
        $defaultNs = $rootElement.GetAttribute("xmlns")
        if ($defaultNs) {
            return $defaultNs
        }
        
        # Then check for any prefixed namespaces
        foreach ($attr in $rootElement.Attributes) {
            if ($attr.Name -like "xmlns:*") {
                return $attr.Value
            }
        }
        
        return $null
    }
    catch {
        Write-Host "Error extracting namespace from XML: $_" -ForegroundColor Red
        return $null
    }
}

# Helper function to get target namespace from schema
function Get-SchemaTargetNamespace {
    param([string]$SchemaPath)
    
    try {
        $schemaContent = Get-Content -Path $SchemaPath -Raw
        if ($schemaContent -match 'targetNamespace\s*=\s*"([^"]+)"') {
            return $matches[1]
        }
        return $null
    }
    catch {
        Write-Host "Error extracting target namespace from schema: $_" -ForegroundColor Red
        return $null
    }
}

# Enhanced validation function with better error handling
function Test-XmlWithSchemaEnhanced {
    param(
        [string]$XmlPath,
        [string]$SchemaPath,
        [string]$TargetNamespace = $null,
        [switch]$VerboseLogging = $false
    )
    
    # Verify the XSD is a valid schema
    try {
        $reader = [System.Xml.XmlReader]::Create($SchemaPath)
        $schema = [System.Xml.Schema.XmlSchema]::Read($reader, {
            param($sender, $e)
            Write-Host "Schema Error: $($e.Message)" -ForegroundColor Red
        })
        $reader.Close()
    }
    catch {
        Write-Host "Critical Schema Error: The schema file could not be read or parsed" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return [PSCustomObject]@{
            Success = $false
            Errors = @("Schema file could not be loaded: $($_.Exception.Message)")
            Details = $null
        }
    }
    
    # Check if XML is well-formed before validation
    try {
        [xml]$testXml = Get-Content -Path $XmlPath -Raw
    }
    catch {
        Write-Host "XML Parsing Error: The XML file is not well-formed" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return [PSCustomObject]@{
            Success = $false
            Errors = @("XML is not well-formed: $($_.Exception.Message)")
            Details = $null
        }
    }
    
    if ($VerboseLogging) {
        Write-Host "Validating: $XmlPath" -ForegroundColor Yellow
        Write-Host "Against schema: $SchemaPath" -ForegroundColor Yellow
        if ($TargetNamespace) {
            Write-Host "With namespace: $TargetNamespace" -ForegroundColor Yellow
        }
        else {
            Write-Host "Without namespace" -ForegroundColor Yellow
        }
    }
    
    try {
        $settings = New-Object System.Xml.XmlReaderSettings
        $settings.ValidationType = [System.Xml.ValidationType]::Schema
        $settings.ValidationFlags = [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessIdentityConstraints -bor [System.Xml.Schema.XmlSchemaValidationFlags]::ReportValidationWarnings
        
        # Create and configure schema set
        $schemaSet = New-Object System.Xml.Schema.XmlSchemaSet
        try {
            if ($TargetNamespace) {
                $schema = $schemaSet.Add($TargetNamespace, $SchemaPath)
            } else {
                $schema = $schemaSet.Add($null, $SchemaPath)
            }
        }
        catch {
            Write-Host "Schema Addition Error: Unable to add schema to schema set" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            return [PSCustomObject]@{
                Success = $false
                Errors = @("Schema could not be added to schema set: $($_.Exception.Message)")
                Details = $null
            }
        }
        
        # Try to compile the schemas
        try {
            $schemaSet.Compile()
        }
        catch {
            Write-Host "Schema Compilation Error: The schema could not be compiled" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            return [PSCustomObject]@{
                Success = $false
                Errors = @("Schema compilation failed: $($_.Exception.Message)")
                Details = $null
            }
        }
        
        $settings.Schemas = $schemaSet
        
        # Track validation errors
        $validationErrors = @()
        $validationDetails = @()
        
        $settings.add_ValidationEventHandler({
            param($sender, $e)
            $validationErrors += $e.Message
            
            $lineInfo = ""
            if ($e.Exception -is [System.Xml.Schema.XmlSchemaException]) {
                $lineNumber = $e.Exception.LineNumber
                $linePosition = $e.Exception.LinePosition
                $lineInfo = " (Line: $lineNumber, Position: $linePosition)"
            }
            
            $severity = if ($e.Severity -eq [System.Xml.Schema.XmlSeverityType]::Error) { "Error" } else { "Warning" }
            $validationDetails += [PSCustomObject]@{
                Severity = $severity
                Message = $e.Message
                LineNumber = $lineNumber
                LinePosition = $linePosition
                SourceObject = $e.Exception.SourceObject
            }
            
            if ($VerboseLogging) {
                $color = if ($severity -eq "Error") { "Red" } else { "Yellow" }
                Write-Host "$severity$lineInfo : $($e.Message)" -ForegroundColor $color
            }
        })
        
        # Validate the XML
        $reader = $null
        try {
            $reader = [System.Xml.XmlReader]::Create($XmlPath, $settings)
            while ($reader.Read()) { }
        }
        catch {
            $validationErrors += $_.Exception.Message
            $validationDetails += [PSCustomObject]@{
                Severity = "Error"
                Message = $_.Exception.Message
                LineNumber = 0
                LinePosition = 0
                SourceObject = $null
            }
            
            if ($VerboseLogging) {
                Write-Host "Validation Exception: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        finally {
            if ($reader) { $reader.Close() }
        }
        
        # Prepare result
        $result = [PSCustomObject]@{
            Success = ($validationErrors.Count -eq 0)
            Errors = $validationErrors
            Details = $validationDetails
        }
        
        return $result
    }
    catch {
        if ($VerboseLogging) {
            Write-Host "Unexpected Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host $_.Exception.StackTrace -ForegroundColor Gray
        }
        
        return [PSCustomObject]@{
            Success = $false
            Errors = @($_.Exception.Message)
            Details = $null
        }
    }
}

Write-Host "Analyzing XML and Schema files..." -ForegroundColor Yellow
Write-Host

# Determine XML namespace status
$xmlHasNamespace = Test-XmlHasNamespace -XmlPath $XmlFilePath
$xmlNamespace = if ($xmlHasNamespace) { Get-XmlNamespace -XmlPath $XmlFilePath } else { $null }

# Determine schema namespace status
$schemaTargetNamespace = Get-SchemaTargetNamespace -SchemaPath $SchemaFilePath

# Process parameters that force namespace usage
if ($ForceNamespace -and $ForceNoNamespace) {
    Write-Host "Error: Cannot specify both -ForceNamespace and -ForceNoNamespace" -ForegroundColor Red
    exit 1
}

if ($ForceNamespace) {
    $targetNs = $schemaTargetNamespace
    Write-Host "Forcing namespace validation with: $targetNs" -ForegroundColor Yellow
} 
elseif ($ForceNoNamespace) {
    $targetNs = $null
    Write-Host "Forcing non-namespaced validation" -ForegroundColor Yellow
}
else {
    # Auto-detect based on XML
    $targetNs = if ($xmlHasNamespace) { $schemaTargetNamespace } else { $null }
}

# Display analysis results
Write-Host "XML Analysis:" -ForegroundColor White
Write-Host "  File: $XmlFilePath"
if ($xmlHasNamespace) {
    Write-Host "  Has Namespace: Yes"
    Write-Host "  Namespace: $xmlNamespace"
} else {
    Write-Host "  Has Namespace: No"
}

Write-Host
Write-Host "Schema Analysis:" -ForegroundColor White
Write-Host "  File: $SchemaFilePath"
if ($schemaTargetNamespace) {
    Write-Host "  Target Namespace: $schemaTargetNamespace"
} else {
    Write-Host "  Target Namespace: None"
}

Write-Host
Write-Host "Validation Strategy:" -ForegroundColor White
if ($targetNs) {
    Write-Host "  Using namespace: $targetNs"
} else {
    Write-Host "  Using non-namespaced validation"
}

if ($xmlHasNamespace -and -not $schemaTargetNamespace -and -not $ForceNoNamespace) {
    Write-Host
    Write-Host "Warning: XML has namespace but schema has no target namespace." -ForegroundColor Yellow
    Write-Host "         This may cause validation issues." -ForegroundColor Yellow
}
elseif (-not $xmlHasNamespace -and $schemaTargetNamespace -and -not $ForceNamespace) {
    Write-Host
    Write-Host "Warning: XML has no namespace but schema has target namespace." -ForegroundColor Yellow
    Write-Host "         This may cause validation issues." -ForegroundColor Yellow
}

# Perform validation
Write-Host
Write-Host "Running Validation..." -ForegroundColor Yellow
$validationResult = Test-XmlWithSchemaEnhanced -XmlPath $XmlFilePath -SchemaPath $SchemaFilePath -TargetNamespace $targetNs -VerboseLogging:$Verbose

# Report results
Write-Host
if ($validationResult.Success) {
    Write-Host "✅ Validation SUCCESSFUL" -ForegroundColor Green
} else {
    Write-Host "❌ Validation FAILED" -ForegroundColor Red
    Write-Host
    Write-Host "Validation Errors:" -ForegroundColor Red
    
    # Group errors by line number if available
    if ($validationResult.Details) {
        $sortedDetails = $validationResult.Details | Sort-Object LineNumber, LinePosition
        $currentLine = -1
        
        foreach ($detail in $sortedDetails) {
            if ($detail.LineNumber -ne $currentLine) {
                if ($currentLine -ne -1) {
                    Write-Host ""
                }
                
                if ($detail.LineNumber -gt 0) {
                    Write-Host "Line $($detail.LineNumber):" -ForegroundColor Yellow
                }
                $currentLine = $detail.LineNumber
            }
            
            $prefix = if ($detail.Severity -eq "Error") { "  ERROR: " } else { "  WARNING: " }
            $color = if ($detail.Severity -eq "Error") { "Red" } else { "Yellow" }
            Write-Host "$prefix$($detail.Message)" -ForegroundColor $color
        }
    } else {
        foreach ($error in $validationResult.Errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
    }
}

# Check if mismatched namespace/no-namespace might be the issue
if (-not $validationResult.Success -and -not $ForceNamespace -and -not $ForceNoNamespace) {
    Write-Host
    Write-Host "Suggestion:" -ForegroundColor Yellow
    
    if ($xmlHasNamespace -and $schemaTargetNamespace) {
        Write-Host "  Try validating without namespace using -ForceNoNamespace"
    }
    elseif (-not $xmlHasNamespace -and -not $schemaTargetNamespace) {
        Write-Host "  Try validating with namespace using -ForceNamespace"
    }
    elseif ($xmlHasNamespace -and -not $schemaTargetNamespace) {
        Write-Host "  Your XML has a namespace but your schema doesn't have a target namespace."
        Write-Host "  Consider using a namespaced schema or removing namespaces from your XML."
    }
    elseif (-not $xmlHasNamespace -and $schemaTargetNamespace) {
        Write-Host "  Your XML has no namespace but your schema has a target namespace."
        Write-Host "  Consider adding namespaces to your XML or using a non-namespaced schema."
    }
}

Write-Host
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "                 Validation Complete" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

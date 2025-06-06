#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Complete XML-to-YAML pipeline validation and transformation.

.DESCRIPTION
    This script provides a complete pipeline that validates XML against the GitHub Actions schema,
    transforms it to YAML, and validates the resulting YAML. This is the full end-to-end process.

.PARAMETER XmlPath
    Path to the XML file to process. Can be relative or absolute.

.PARAMETER OutputPath
    Path for the output YAML file. If not specified, uses the same name as input with .yml extension.

.PARAMETER SkipXmlValidation
    Skip XML schema validation step.

.PARAMETER SkipYamlValidation
    Skip YAML syntax validation step.

.PARAMETER Force
    Force overwrite existing output file.

.PARAMETER Detailed
    Show detailed validation results including line numbers and specific error messages.

.PARAMETER VerboseOutput
    Enable verbose output showing all pipeline steps.

.PARAMETER NoColor
    Disable colored output for compatibility with terminals that don't support ANSI colors.

.EXAMPLE
    .\Run-FullPipeline.ps1 -XmlPath "samples\dotnet-library-workflow.xml"
    
    Runs the complete pipeline: validate XML → transform to YAML → validate YAML.

.EXAMPLE
    .\Run-FullPipeline.ps1 -XmlPath "samples\github-workflow.xml" -OutputPath "output\my-workflow.yml" -Detailed -VerboseOutput
    
    Runs the pipeline with custom output path and detailed logging.

.NOTES
    This script requires the NMYAML CLI tool to be built.
    This demonstrates the complete XML validation and transformation workflow.
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$XmlPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipXmlValidation,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipYamlValidation,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$Detailed,
      [Parameter(Mandatory = $false)]
    [switch]$VerboseOutput,
    
    [Parameter(Mandatory = $false)]
    [switch]$NoColor
)

# Script configuration
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

# Resolve paths
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRoot
$CliProject = Join-Path $ProjectRoot "CLI\NMYAML.CLI\NMYAML.CLI.csproj"

# Validate inputs
if (-not (Test-Path $XmlPath)) {
    Write-Error "XML file not found: $XmlPath"
    exit 1
}

if (-not (Test-Path $CliProject)) {
    Write-Error "NMYAML CLI project not found: $CliProject"
    exit 1
}

# Determine output path if not specified
if (-not $OutputPath) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($XmlPath)
    $outputDir = Split-Path -Parent $XmlPath
    $OutputPath = Join-Path $outputDir "$baseName.yml"
}

Write-Information "🚀 Running Full XML-to-YAML Pipeline"
Write-Information "   Input XML:  $XmlPath"
Write-Information "   Output YAML: $OutputPath"
Write-Information ""

$overallSuccess = $true

# Step 1: XML Schema Validation (optional)
if (-not $SkipXmlValidation) {
    Write-Information "📋 Step 1: XML Schema Validation"
    
    $xmlValidationArgs = @("validate", $XmlPath, "--schema", (Join-Path $ProjectRoot "schemas\github-actions-schema.xsd"))
    if ($Detailed) { $xmlValidationArgs += "--detailed" }
    if ($VerboseOutput) { $xmlValidationArgs += "--verbose" }
    if ($NoColor) { $xmlValidationArgs += "--no-color" }
    
    try {
        $xmlResult = & dotnet run --project $CliProject --configuration Release -- @xmlValidationArgs
        $xmlExitCode = $LASTEXITCODE
        
        Write-Output $xmlResult
        
        if ($xmlExitCode -ne 0) {
            Write-Warning "XML validation failed, but continuing with transformation..."
            $overallSuccess = $false
        } else {
            Write-Information "✅ XML validation passed"
        }
    }
    catch {
        Write-Warning "XML validation error: $($_.Exception.Message)"
        $overallSuccess = $false
    }
    
    Write-Information ""
} else {
    Write-Information "⏭️  Step 1: XML Schema Validation (skipped)"
    Write-Information ""
}

# Step 2: XML to YAML Transformation
Write-Information "🔄 Step 2: XML to YAML Transformation"

$transformArgs = @("convert", $XmlPath, $OutputPath)
if ($SkipXmlValidation) { $transformArgs += "--skip-xml-validation" }
if ($SkipYamlValidation) { $transformArgs += "--skip-yaml-validation" }
if ($Force) { $transformArgs += "--force" }
if ($Detailed) { $transformArgs += "--detailed" }
if ($VerboseOutput) { $transformArgs += "--verbose" }
if ($NoColor) { $transformArgs += "--no-color" }

try {
    $transformResult = & dotnet run --project $CliProject --configuration Release -- @transformArgs
    $transformExitCode = $LASTEXITCODE
    
    Write-Output $transformResult
    
    if ($transformExitCode -ne 0) {
        Write-Error "Transformation failed"
        exit $transformExitCode
    } else {
        Write-Information "✅ Transformation completed successfully"
    }
}
catch {
    Write-Error "Transformation error: $($_.Exception.Message)"
    exit 1
}

Write-Information ""

# Step 3: YAML Syntax Validation (optional)
if (-not $SkipYamlValidation -and (Test-Path $OutputPath)) {
    Write-Information "📋 Step 3: YAML Syntax Validation"
    
    $yamlValidationArgs = @("yaml", "validate", $OutputPath, "--github-actions")
    if ($Detailed) { $yamlValidationArgs += "--detailed" }
    if ($Verbose) { $yamlValidationArgs += "--verbose" }
    if ($NoColor) { $yamlValidationArgs += "--no-color" }
    
    try {
        $yamlResult = & dotnet run --project $CliProject --configuration Release -- @yamlValidationArgs
        $yamlExitCode = $LASTEXITCODE
        
        Write-Output $yamlResult
        
        if ($yamlExitCode -ne 0) {
            Write-Warning "YAML validation failed"
            $overallSuccess = $false
        } else {
            Write-Information "✅ YAML validation passed"
        }
    }
    catch {
        Write-Warning "YAML validation error: $($_.Exception.Message)"
        $overallSuccess = $false
    }
} else {
    Write-Information "⏭️  Step 3: YAML Syntax Validation (skipped)"
}

Write-Information ""

# Final summary
if ($overallSuccess) {
    Write-Information "🎉 Pipeline completed successfully!"
    Write-Information "   📄 Generated YAML: $OutputPath"
    exit 0
} else {
    Write-Warning "⚠️  Pipeline completed with warnings"
    Write-Information "   📄 Generated YAML: $OutputPath"
    exit 0  # Still exit 0 since we generated output
}

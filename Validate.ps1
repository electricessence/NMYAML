#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates XML or YAML files with automatic file type detection.

.DESCRIPTION
    This script validates XML and YAML files with automatic file type detection.
    For XML files, it performs syntax validation by default, with optional schema validation.
    For YAML files, it validates syntax and structure, checking for formatting issues,
    duplicate keys, and general YAML compliance.

.PARAMETER Path
    Path to the file to validate. Can be relative or absolute.
    Supports both XML (.xml, .xsd) and YAML (.yml, .yaml) files.

.PARAMETER Schema
    Optional path to XSD schema file for XML validation. Only applicable to XML files.
    If not specified for XML files, only syntax validation is performed.

.PARAMETER Detailed
    Show detailed validation results including line numbers and specific error messages.

.PARAMETER VerboseOutput
    Enable verbose output showing validation steps.

.PARAMETER NoColor
    Disable colored output for compatibility with terminals that don't support ANSI colors.

.EXAMPLE
    .\Validate.ps1 "samples\dotnet-library-workflow.xml"
    
    Validates XML syntax only (auto-detected as XML file).

.EXAMPLE
    .\Validate.ps1 "samples\dotnet-library-workflow.xml" -Schema "schemas\github-actions-schema.xsd"
    
    Validates XML against the GitHub Actions schema.

.EXAMPLE
    .\Validate.ps1 "output\dotnet-library-workflow.yml"
    
    Validates YAML syntax and structure (auto-detected as YAML file).

.EXAMPLE
    .\Validate.ps1 "output\dotnet-library-workflow.yml" -Detailed -VerboseOutput
    
    Validates YAML with detailed output and verbose logging.

.NOTES
    This script requires the NMYAML CLI tool to be built.
    File type detection is automatic based on file extension:
    - XML files: .xml, .xsd
    - YAML files: .yml, .yaml
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Path,
    
    [Parameter(Mandatory = $false)]
    [string]$Schema,
    
    [Parameter(Mandatory = $false)]
    [switch]$Detailed,
    
    [Parameter(Mandatory = $false)]
    [switch]$VerboseOutput,
    
    [Parameter(Mandatory = $false)]
    [switch]$NoColor
)

# Script configuration
$ErrorActionPreference = "Stop"

# Resolve paths
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$CliProject = Join-Path $ScriptRoot "CLI\NMYAML.CLI\NMYAML.CLI.csproj"

# Check if file exists
if (-not (Test-Path $Path)) {
    Write-Error "File not found: $Path"
    exit 1
}

# Get file extension to determine type
$fileExtension = [System.IO.Path]::GetExtension($Path).ToLower()
$isXmlFile = $fileExtension -in @('.xml', '.xsd')
$isYamlFile = $fileExtension -in @('.yml', '.yaml')

# Validate file type
if (-not ($isXmlFile -or $isYamlFile)) {
    Write-Error "Unsupported file type. Only XML (.xml, .xsd) and YAML (.yml, .yaml) files are supported."
    exit 1
}

# Warn if schema is provided for non-XML files
if ($Schema -and -not $isXmlFile) {
    Write-Warning "Schema validation is only applicable to XML files. The -Schema parameter will be ignored for YAML files."
}

# Build validation arguments
$validationArgs = @("validate", $Path)

# Add schema parameter only for XML files
if ($Schema -and $isXmlFile) {
    $validationArgs += "--schema"
    $validationArgs += $Schema
}

# Add common optional parameters
if ($Detailed) { $validationArgs += "--detailed" }
if ($VerboseOutput) { $validationArgs += "--verbose" }
if ($NoColor) { $validationArgs += "--no-color" }

# Run validation - let the CLI handle all validation logic with smart file-type detection
& dotnet run --project $CliProject --configuration Release -- @validationArgs
exit $LASTEXITCODE

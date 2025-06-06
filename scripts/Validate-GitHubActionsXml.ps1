#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates XML files against the GitHub Actions schema.

.DESCRIPTION
    This script provides a convenient way to validate GitHub Actions workflow XML files
    against the github-actions-schema.xsd using the NMYAML CLI tool.

.PARAMETER XmlPath
    Path to the XML file to validate. Can be relative or absolute.

.PARAMETER Detailed
    Show detailed validation results including line numbers and specific error messages.

.PARAMETER Verbose
    Enable verbose output showing validation progress.

.PARAMETER NoColor
    Disable colored output for compatibility with terminals that don't support ANSI colors.

.EXAMPLE
    .\Validate-GitHubActionsXml.ps1 -XmlPath "samples\dotnet-library-workflow.xml"
    
    Validates the dotnet library workflow XML against the GitHub Actions schema.

.EXAMPLE
    .\Validate-GitHubActionsXml.ps1 -XmlPath "samples\github-workflow.xml" -Detailed -Verbose
    
    Validates with detailed output and verbose logging.

.NOTES
    This script requires the NMYAML CLI tool to be built.
    The github-actions-schema.xsd file must exist in the schemas folder.
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$XmlPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$Detailed,
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose,
    
    [Parameter(Mandatory = $false)]
    [switch]$NoColor
)

# Script configuration
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

# Resolve paths
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRoot
$SchemaPath = Join-Path $ProjectRoot "schemas\github-actions-schema.xsd"
$CliProject = Join-Path $ProjectRoot "CLI\NMYAML.CLI\NMYAML.CLI.csproj"

# Validate inputs
if (-not (Test-Path $XmlPath)) {
    Write-Error "XML file not found: $XmlPath"
    exit 1
}

if (-not (Test-Path $SchemaPath)) {
    Write-Error "GitHub Actions schema not found: $SchemaPath"
    exit 1
}

if (-not (Test-Path $CliProject)) {
    Write-Error "NMYAML CLI project not found: $CliProject"
    exit 1
}

# Build CLI arguments
$CliArgs = @("validate", $XmlPath, "--schema", $SchemaPath)

if ($Detailed) { $CliArgs += "--detailed" }
if ($Verbose) { $CliArgs += "--verbose" }
if ($NoColor) { $CliArgs += "--no-color" }

# Display what we're doing
Write-Information "🔍 Validating GitHub Actions XML"
Write-Information "   XML File: $XmlPath"
Write-Information "   Schema:   $SchemaPath"
Write-Information ""

# Run the validation
try {
    $result = & dotnet run --project $CliProject --configuration Release -- @CliArgs
    $exitCode = $LASTEXITCODE
    
    # Output the result
    Write-Output $result
    
    # Exit with the same code as the CLI tool
    exit $exitCode
}
catch {
    Write-Error "Failed to run validation: $($_.Exception.Message)"
    exit 1
}

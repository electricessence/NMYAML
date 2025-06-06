#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates XML syntax without schema validation.

.DESCRIPTION
    This script provides a convenient way to validate XML files for syntax errors only,
    without performing schema validation. Useful for checking if XML is well-formed.

.PARAMETER XmlPath
    Path to the XML file to validate. Can be relative or absolute.

.PARAMETER Detailed
    Show detailed validation results including line numbers and specific error messages.

.PARAMETER Verbose
    Enable verbose output showing validation progress.

.PARAMETER NoColor
    Disable colored output for compatibility with terminals that don't support ANSI colors.

.EXAMPLE
    .\Validate-XmlSyntax.ps1 -XmlPath "samples\dotnet-library-workflow.xml"
    
    Validates the XML file for syntax errors only.

.EXAMPLE
    .\Validate-XmlSyntax.ps1 -XmlPath "samples\github-workflow.xml" -Detailed -Verbose
    
    Validates with detailed output and verbose logging.

.NOTES
    This script requires the NMYAML CLI tool to be built.
    This only checks XML syntax, not schema compliance.
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
if ($Verbose) { $InformationPreference = "Continue" }

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

# Build CLI arguments (no schema parameter = syntax-only validation)
$CliArgs = @("validate", $XmlPath)

if ($Detailed) { $CliArgs += "--detailed" }
if ($Verbose) { $CliArgs += "--verbose" }
if ($NoColor) { $CliArgs += "--no-color" }

# Display what we're doing
Write-Information "🔍 Validating XML Syntax"
Write-Information "   XML File: $XmlPath"
Write-Information "   Mode:     Syntax-only (no schema validation)"
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

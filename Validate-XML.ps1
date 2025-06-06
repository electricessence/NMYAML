#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates XML file with optional schema validation.

.DESCRIPTION
    This script validates XML files. By default, it performs syntax validation only.
    Use the -Schema parameter to perform schema validation against a specific XSD file.

.PARAMETER Path
    Path to the XML file to validate. Can be relative or absolute.

.PARAMETER Schema
    Optional path to XSD schema file for validation. If not specified, only syntax validation is performed.

.PARAMETER Detailed
    Show detailed validation results including line numbers and specific error messages.

.PARAMETER VerboseOutput
    Enable verbose output showing validation steps.

.PARAMETER NoColor
    Disable colored output for compatibility with terminals that don't support ANSI colors.

.EXAMPLE
    .\Validate-XML.ps1 "samples\dotnet-library-workflow.xml"
    
    Validates XML syntax only.

.EXAMPLE
    .\Validate-XML.ps1 "samples\dotnet-library-workflow.xml" -Schema "schemas\github-actions-schema.xsd"
    
    Validates XML against the GitHub Actions schema.

.NOTES
    This script requires the NMYAML CLI tool to be built.
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

# Build validation arguments
$validationArgs = @("validate", $Path)

if ($Schema) {
    $validationArgs += "--schema"
    $validationArgs += $Schema
}

if ($Detailed) { $validationArgs += "--detailed" }
if ($VerboseOutput) { $validationArgs += "--verbose" }
if ($NoColor) { $validationArgs += "--no-color" }

# Run validation - let the CLI handle all validation logic
& dotnet run --project $CliProject --configuration Release -- @validationArgs
exit $LASTEXITCODE

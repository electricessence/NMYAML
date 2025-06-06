#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates YAML file for syntax and structure.

.DESCRIPTION
    This script validates YAML files for proper syntax and structure.
    It checks for formatting issues, duplicate keys, and general YAML compliance.

.PARAMETER Path
    Path to the YAML file to validate. Can be relative or absolute.

.PARAMETER Detailed
    Show detailed validation results including line numbers and specific error messages.

.PARAMETER VerboseOutput
    Enable verbose output showing validation steps.

.PARAMETER NoColor
    Disable colored output for compatibility with terminals that don't support ANSI colors.

.EXAMPLE
    .\Validate-YAML.ps1 "output\dotnet-library-workflow.yml"
    
    Validates YAML syntax and structure.

.EXAMPLE
    .\Validate-YAML.ps1 "output\dotnet-library-workflow.yml" -Detailed -VerboseOutput
    
    Validates YAML with detailed output and verbose logging.

.NOTES
    This script requires the NMYAML CLI tool to be built.
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Path,
    
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

if ($Detailed) { $validationArgs += "--detailed" }
if ($VerboseOutput) { $validationArgs += "--verbose" }
if ($NoColor) { $validationArgs += "--no-color" }

# Run validation - let the CLI handle all validation logic
& dotnet run --project $CliProject --configuration Release -- @validationArgs
exit $LASTEXITCODE

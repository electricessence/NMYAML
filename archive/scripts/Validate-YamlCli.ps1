#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Validates YAML files using the NMYAML CLI tool.

.DESCRIPTION
    This script provides a convenient wrapper around the NMYAML CLI tool's YAML validation
    functionality. It validates YAML files for syntax errors and optionally checks
    GitHub Actions specific structure and conventions.

.PARAMETER YamlPath
    Path to the YAML file to validate. Can be relative or absolute.

.PARAMETER GitHubActions
    Enable GitHub Actions specific validation checks.

.PARAMETER Detailed
    Show detailed validation results including line numbers and specific error messages.

.PARAMETER Verbose
    Enable verbose output showing validation progress.

.PARAMETER NoColor
    Disable colored output for compatibility with terminals that don't support ANSI colors.

.PARAMETER ExportReport
    Export validation report to a JSON file.

.EXAMPLE
    .\Validate-YamlCli.ps1 -YamlPath "output\dotnet-library-workflow.yml"
    
    Validates the YAML file for syntax errors using the CLI tool.

.EXAMPLE
    .\Validate-YamlCli.ps1 -YamlPath "output\github-workflow.yml" -GitHubActions -Detailed
    
    Validates with GitHub Actions specific checks and detailed output.

.NOTES
    This script requires the NMYAML CLI tool to be built.
    This is a wrapper around the CLI tool's yaml validate command.
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$YamlPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$GitHubActions,
    
    [Parameter(Mandatory = $false)]
    [switch]$Detailed,
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose,
    
    [Parameter(Mandatory = $false)]
    [switch]$NoColor,
    
    [Parameter(Mandatory = $false)]
    [switch]$ExportReport
)

# Script configuration
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

# Resolve paths
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptRoot
$CliProject = Join-Path $ProjectRoot "CLI\NMYAML.CLI\NMYAML.CLI.csproj"

# Validate inputs
if (-not (Test-Path $YamlPath)) {
    Write-Error "YAML file not found: $YamlPath"
    exit 1
}

if (-not (Test-Path $CliProject)) {
    Write-Error "NMYAML CLI project not found: $CliProject"
    exit 1
}

# Build CLI arguments
$CliArgs = @("yaml", "validate", $YamlPath)

if ($GitHubActions) { $CliArgs += "--github-actions" }
if ($Detailed) { $CliArgs += "--detailed" }
if ($Verbose) { $CliArgs += "--verbose" }
if ($NoColor) { $CliArgs += "--no-color" }
if ($ExportReport) { $CliArgs += "--export-report" }

# Display what we're doing
Write-Information "🔍 Validating YAML with CLI Tool"
Write-Information "   YAML File: $YamlPath"
if ($GitHubActions) {
    Write-Information "   Mode:      YAML syntax + GitHub Actions validation"
} else {
    Write-Information "   Mode:      YAML syntax only"
}
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

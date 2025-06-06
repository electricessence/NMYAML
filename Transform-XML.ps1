#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Transform XML to YAML using XSLT transformations.

.DESCRIPTION
    This script is a simple wrapper around the NMYAML CLI transform command.
    It transforms XML files to YAML format using XSLT stylesheets.

.PARAMETER InputPath
    Path to the input XML file to transform. Can be relative or absolute.

.PARAMETER OutputPath
    Path where the transformed YAML file will be saved. Can be relative or absolute.

.PARAMETER StylesheetPath
    Optional path to the XSLT stylesheet. If not specified, uses the default transformation.

.PARAMETER Validate
    If specified, validates the input XML against its schema before transformation.

.PARAMETER VerboseOutput
    Enable verbose output showing transformation steps.

.PARAMETER NoColor
    Disable colored output for compatibility with terminals that don't support ANSI colors.

.EXAMPLE
    .\Transform-XML.ps1 -InputPath "samples\dotnet-library-workflow.xml" -OutputPath "output\workflow.yml"
    
    Transforms XML to YAML using default stylesheet.

.EXAMPLE
    .\Transform-XML.ps1 -InputPath "samples\dotnet-library-workflow.xml" -OutputPath "output\workflow.yml" -Validate
    
    Validates XML first, then transforms to YAML.

.EXAMPLE
    .\Transform-XML.ps1 -InputPath "samples\dotnet-library-workflow.xml" -OutputPath "output\workflow.yml" -StylesheetPath "xslt\custom-transform.xslt"
    
    Transforms using a custom XSLT stylesheet.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$InputPath,
    
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [string]$StylesheetPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$Validate,
    
    [Parameter(Mandatory = $false)]
    [switch]$VerboseOutput,
    
    [Parameter(Mandatory = $false)]
    [switch]$NoColor
)

# Set error action preference
$ErrorActionPreference = "Stop"

try {
    # Build the CLI project path
    $ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $CliProject = Join-Path $ScriptRoot "CLI\NMYAML.CLI\NMYAML.CLI.csproj"
    
    # Verify CLI project exists
    if (-not (Test-Path $CliProject)) {
        Write-Error "NMYAML CLI project not found at: $CliProject`nPlease ensure the project structure is correct."
        exit 1
    }
    
    # Build the command arguments
    $arguments = @("transform", $InputPath, $OutputPath)
    
    # Add optional parameters
    if ($StylesheetPath) {
        $arguments += "--xslt-path"
        $arguments += $StylesheetPath
    }
    
    if ($Validate) {
        $arguments += "--validate-xml"
    }
    
    if ($VerboseOutput) {
        $arguments += "--verbose"
    }
    
    if ($NoColor) {
        $arguments += "--no-color"
    }
    
    # Execute the CLI command using dotnet run
    # Write-Host "🔄 Executing: dotnet run --project CLI\NMYAML.CLI -- $($arguments -join ' ')" -ForegroundColor Cyan
    & dotnet run --project $CliProject --configuration Release -- @arguments
    
    # Return the CLI exit code
    exit $LASTEXITCODE
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}

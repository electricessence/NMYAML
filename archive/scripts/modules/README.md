# Terminal Output Module

The `TerminalOutput.psm1` module provides enhanced terminal output formatting capabilities for PowerShell scripts. This module is designed to improve the visual presentation of your script outputs with consistent styling, colored formatting, and advanced visualization tools.

## Features

- **Banners and Headers**: Create visually distinct sections in your console output
- **Status Messages**: Standardized info, success, warning, and error messages
- **Progress Indicators**: Visual progress bars and activity spinners
- **Advanced Formatting**: Tables, tree views, and syntax highlighting
- **Consistent Styling**: Unified look and feel across all scripts

## Usage

### Importing the Module

```powershell
# Add this to your script to import the module
$terminalModulePath = Join-Path $PSScriptRoot "path\to\TerminalOutput.psm1"
Import-Module $terminalModulePath -Force
```

### Basic Functions

#### Banners and Headers

```powershell
# Create a full-width banner
Write-Banner -Text "Application Name" -ForegroundColor Cyan

# Create a section header
Write-SectionHeader -Text "Configuration" -ForegroundColor Yellow
```

#### Status Messages

```powershell
# Display different types of messages
Write-InfoMessage "Processing file: example.xml"
Write-SuccessMessage "File processed successfully"
Write-WarningMessage "File size exceeds recommended limit"
Write-ErrorMessage "Failed to process file"
```

### Progress Indicators

```powershell
# Display a progress bar
Write-ProgressBar -PercentComplete 75

# Show an activity spinner for a long-running task
$result = Show-ActivitySpinner -Message "Processing..." -ScriptBlock {
    # Your long-running code here
    Start-Sleep -Seconds 5
    return "Operation completed"
}
```

### Advanced Formatting

#### Tables

```powershell
$data = @(
    [PSCustomObject]@{Name="Item1"; Status="Active"; Count=42},
    [PSCustomObject]@{Name="Item2"; Status="Inactive"; Count=18}
)
Write-ConsoleTable -Data $data -Properties Name,Status,Count -Title "Items"
```

#### Tree Views

```powershell
$rootObject = [PSCustomObject]@{
    Name = "Project"
    Children = @(
        [PSCustomObject]@{
            Name = "src"
            Children = @(
                [PSCustomObject]@{ Name = "main.ps1"; Children = @() },
                [PSCustomObject]@{ Name = "utils.ps1"; Children = @() }
            )
        },
        [PSCustomObject]@{
            Name = "docs"
            Children = @(
                [PSCustomObject]@{ Name = "README.md"; Children = @() }
            )
        }
    )
}

Write-TreeView -Node $rootObject -ChildrenProperty "Children" -DisplayProperty "Name"
```

#### Syntax Highlighting

```powershell
# Highlight XML syntax
$xmlContent = Get-Content "example.xml" -Raw
Write-SyntaxHighlight -Text $xmlContent -Language xml

# Highlight YAML syntax
$yamlContent = Get-Content "example.yaml" -Raw
Write-SyntaxHighlight -Text $yamlContent -Language yaml

# Highlight JSON syntax
$jsonContent = Get-Content "example.json" -Raw
Write-SyntaxHighlight -Text $jsonContent -Language json

# Highlight PowerShell syntax
$psContent = Get-Content "example.ps1" -Raw
Write-SyntaxHighlight -Text $psContent -Language powershell
```

## Function Reference

### Console Styling Functions

- `Write-Banner`: Creates a visually distinct banner with customizable text and colors
- `Write-SectionHeader`: Creates a section header with customizable text and colors

### Status Message Functions

- `Write-InfoMessage`: Displays an information message with customizable prefix and color
- `Write-SuccessMessage`: Displays a success message with a checkmark and green color
- `Write-WarningMessage`: Displays a warning message with a warning symbol and yellow color
- `Write-ErrorMessage`: Displays an error message with an error symbol and red color

### Progress Indicator Functions

- `Write-ProgressBar`: Shows a progress bar with customizable appearance
- `Show-ActivitySpinner`: Displays a spinning activity indicator while executing a script block

### Advanced Formatting Functions

- `Write-ConsoleTable`: Displays data in a table format with customizable column widths and colors
- `Write-TreeView`: Renders hierarchical data as a tree in the console with customizable formatting
- `Write-SyntaxHighlight`: Applies basic syntax highlighting to code blocks for XML, YAML, JSON, and PowerShell

## Examples

Check out the `test-terminal-formatting.ps1` script for comprehensive examples of all the terminal output formatting capabilities.

## Integration with Other Modules

This module is designed to be used alongside other modules like `XmlYamlUtils.psm1` and `XmlYamlSchema.psm1`. The modules are designed to check for the presence of TerminalOutput functions and will use them when available, falling back to standard PowerShell output if not.

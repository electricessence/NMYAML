# TerminalOutput.psm1
# PowerShell module for terminal output formatting and utilities

#region Console Colors and Styling

<#
.SYNOPSIS
    Writes a colored banner to the console.
.DESCRIPTION
    Creates a visually distinct banner with customizable text and colors.
.PARAMETER Text
    The text to display in the banner.
.PARAMETER Width
    The total width of the banner (including padding). Defaults to 53.
.PARAMETER ForegroundColor
    The text color. Defaults to Cyan.
.PARAMETER Character
    The character used for the border. Defaults to '='.
.EXAMPLE
    Write-Banner -Text "XML Validation" -ForegroundColor Green
#>
function Write-Banner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 53,
        
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::Cyan,
        
        [Parameter(Mandatory = $false)]
        [char]$Character = '='
    )
      # Create the border line
    $border = ""
    for ($i = 0; $i -lt $Width; $i++) {
        $border += $Character
    }
    
    # Calculate padding for centering the text
    $padding = [Math]::Max(0, ($Width - $Text.Length) / 2)
    $leftPadding = " " * [Math]::Floor($padding) 
    $rightPadding = " " * [Math]::Ceiling($padding)
    $paddedText = $leftPadding + $Text + $rightPadding
    
    # Ensure the padded text is exactly the right width
    if ($paddedText.Length -gt $Width) {
        $paddedText = $paddedText.Substring(0, $Width)
    }
    elseif ($paddedText.Length -lt $Width) {
        $paddedText += " " * ($Width - $paddedText.Length)
    }
    
    # Write the banner    # Make sure width is honored for the text line
    if ($paddedText.Length -gt $Width) {
        $paddedText = $paddedText.Substring(0, $Width)
    } elseif ($paddedText.Length -lt $Width) {
        $paddedText = $paddedText.PadRight($Width)
    }
    
    Write-Host $border -ForegroundColor $ForegroundColor
    Write-Host $paddedText -ForegroundColor $ForegroundColor
    Write-Host $border -ForegroundColor $ForegroundColor
}

<#
.SYNOPSIS
    Writes a section header to the console.
.DESCRIPTION
    Creates a visually distinct section header with customizable text and colors.
.PARAMETER Text
    The text to display in the header.
.PARAMETER ForegroundColor
    The text color. Defaults to Yellow.
.PARAMETER LeadingNewLine
    Whether to include a leading newline. Defaults to true.
.EXAMPLE
    Write-SectionHeader -Text "Processing Files" -ForegroundColor Magenta
#>
function Write-SectionHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::Yellow,
        
        [Parameter(Mandatory = $false)]
        [switch]$LeadingNewLine = $true
    )
    
    if ($LeadingNewLine) {
        Write-Host ""
    }
      Write-Host $Text -ForegroundColor $ForegroundColor
    
    # Create the underline without using string multiplication
    $underline = ""
    for ($i = 0; $i -lt $Text.Length; $i++) {
        $underline += "-"
    }
    
    Write-Host $underline -ForegroundColor $ForegroundColor
}

<#
.SYNOPSIS
    Writes an information message to the console.
.DESCRIPTION
    Displays an information message with a customizable prefix and color.
.PARAMETER Message
    The message to display.
.PARAMETER ForegroundColor
    The text color. Defaults to White.
.PARAMETER NoPrefix
    Whether to omit the "INFO:" prefix. Defaults to false.
.EXAMPLE
    Write-InfoMessage -Message "Processing file: example.xml"
#>
function Write-InfoMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoPrefix = $false
    )
    
    if ($NoPrefix) {
        Write-Host $Message -ForegroundColor $ForegroundColor
    }
    else {
        Write-Host "INFO: $Message" -ForegroundColor $ForegroundColor
    }
}

<#
.SYNOPSIS
    Writes a success message to the console.
.DESCRIPTION
    Displays a success message with a checkmark and green color.
.PARAMETER Message
    The success message to display.
.PARAMETER NoCheckmark
    Whether to omit the checkmark. Defaults to false.
.EXAMPLE
    Write-SuccessMessage -Message "File processed successfully"
#>
function Write-SuccessMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoCheckmark = $false
    )
    
    if ($NoCheckmark) {
        Write-Host $Message -ForegroundColor Green
    }
    else {
        Write-Host "✅ $Message" -ForegroundColor Green
    }
}

<#
.SYNOPSIS
    Writes a warning message to the console.
.DESCRIPTION
    Displays a warning message with a customizable symbol and yellow color.
.PARAMETER Message
    The warning message to display.
.PARAMETER NoWarningSymbol
    Whether to omit the warning symbol. Defaults to false.
.EXAMPLE
    Write-WarningMessage -Message "File might be corrupted"
#>
function Write-WarningMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoWarningSymbol = $false
    )
    
    if ($NoWarningSymbol) {
        Write-Host $Message -ForegroundColor Yellow
    }
    else {
        Write-Host "⚠️ $Message" -ForegroundColor Yellow
    }
}

<#
.SYNOPSIS
    Writes an error message to the console.
.DESCRIPTION
    Displays an error message with a customizable symbol and red color.
.PARAMETER Message
    The error message to display.
.PARAMETER NoErrorSymbol
    Whether to omit the error symbol. Defaults to false.
.EXAMPLE
    Write-ErrorMessage -Message "Failed to process file"
#>
function Write-ErrorMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoErrorSymbol = $false
    )
    
    if ($NoErrorSymbol) {
        Write-Host $Message -ForegroundColor Red
    }
    else {
        Write-Host "❌ $Message" -ForegroundColor Red
    }
}

#endregion

#region Progress Indicators

<#
.SYNOPSIS
    Displays a simple progress bar.
.DESCRIPTION
    Shows a progress bar with customizable appearance.
.PARAMETER PercentComplete
    The percentage of completion (0-100).
.PARAMETER Width
    The width of the progress bar. Defaults to 50.
.PARAMETER ProgressChar
    The character used for the progress indicator. Defaults to '█'.
.PARAMETER EmptyChar
    The character used for the empty part of the progress bar. Defaults to '░'.
.EXAMPLE
    Write-ProgressBar -PercentComplete 75
#>
function Write-ProgressBar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int]$PercentComplete,
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 50,
        
        [Parameter(Mandatory = $false)]
        [char]$ProgressChar = '█',
        
        [Parameter(Mandatory = $false)]
        [char]$EmptyChar = '░'
    )
      # Calculate how many blocks to fill
    $blocksToFill = [Math]::Round($Width * ($PercentComplete / 100))
    
    # Create the progress bar string
    $progressBar = ""
    for ($i = 0; $i -lt $blocksToFill; $i++) {
        $progressBar += $ProgressChar
    }
    
    for ($i = 0; $i -lt ($Width - $blocksToFill); $i++) {
        $progressBar += $EmptyChar
    }
    
    # Determine the color based on completion percentage
    $color = if ($PercentComplete -lt 30) {
        [System.ConsoleColor]::Red
    } elseif ($PercentComplete -lt 70) {
        [System.ConsoleColor]::Yellow
    } else {
        [System.ConsoleColor]::Green
    }
    
    # Write the progress bar
    Write-Host -NoNewline "["
    Write-Host -NoNewline $progressBar -ForegroundColor $color
    Write-Host -NoNewline "] "
    Write-Host "$PercentComplete%" -NoNewline
    
    # Move cursor to beginning of line to update in place
    Write-Host -NoNewline "`r"
}

<#
.SYNOPSIS
    Creates an activity spinner for long-running operations.
.DESCRIPTION
    Displays an animated spinner while a scriptblock executes.
.PARAMETER ScriptBlock
    The code to execute while displaying the spinner.
.PARAMETER Message
    Optional message to display next to the spinner.
.EXAMPLE
    Show-ActivitySpinner -Message "Processing..." -ScriptBlock { Start-Sleep -Seconds 5 }
#>
function Show-ActivitySpinner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [string]$Message = "Working..."
    )
      # Spinner characters for animation
    $spinnerChars = @('|', '/', '-', '\\')
    $cursorPosition = $host.UI.RawUI.CursorPosition
    $spinnerIndex = 0
    $jobDone = $false
    
    # Start the job
    $job = Start-Job -ScriptBlock $ScriptBlock
    
    # Show spinner until job completes
    while (-not $jobDone) {
        $spinnerChar = $spinnerChars[$spinnerIndex % $spinnerChars.Length]
        Write-Host "$spinnerChar $Message" -NoNewline
        Start-Sleep -Milliseconds 100
        [Console]::SetCursorPosition($cursorPosition.X, $cursorPosition.Y)
        Write-Host (" " * ($Message.Length + 2)) -NoNewline
        [Console]::SetCursorPosition($cursorPosition.X, $cursorPosition.Y)
        $spinnerIndex++
        
        if ($job.State -eq "Completed") {
            $jobDone = $true
        }
    }
    
    # Get job results
    $result = Receive-Job -Job $job
    Remove-Job -Job $job
    
    # Clear the spinner line
    [Console]::SetCursorPosition($cursorPosition.X, $cursorPosition.Y)
    Write-Host (" " * ($Message.Length + 2))
    [Console]::SetCursorPosition($cursorPosition.X, $cursorPosition.Y)
    
    return $result
}

#endregion

#region Advanced Formatting

<#
.SYNOPSIS
    Creates a formatted table for console output.
.DESCRIPTION
    Displays data in a table format with customizable column widths and colors.
.PARAMETER Data
    An array of objects to display in the table.
.PARAMETER Properties
    The object properties to include as columns.
.PARAMETER Title
    Optional table title.
.PARAMETER TitleColor
    Color for the table title. Defaults to Cyan.
.PARAMETER HeaderColor
    Color for the column headers. Defaults to White.
.PARAMETER BorderColor
    Color for the table borders. Defaults to Gray.
.EXAMPLE
    Write-ConsoleTable -Data $results -Properties Name,Status,Count -Title "Test Results"
#>
function Write-ConsoleTable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Data,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Properties,
        
        [Parameter(Mandatory = $false)]
        [string]$Title = "",
        
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]$TitleColor = [System.ConsoleColor]::Cyan,
        
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]$HeaderColor = [System.ConsoleColor]::White,
        
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]$BorderColor = [System.ConsoleColor]::Gray
    )
    
    # Get the maximum width for each property
    $columnWidths = @{}
    foreach ($prop in $Properties) {
        $columnWidths[$prop] = [Math]::Max($prop.Length, ($Data | ForEach-Object { "$($_.$prop)".Length } | Measure-Object -Maximum).Maximum) + 2
    }
    
    # Calculate total width for borders
    $totalWidth = ($columnWidths.Values | Measure-Object -Sum).Sum + $Properties.Count + 1
    
    # Write title if provided
    if ($Title) {
        Write-Host ("-" * $totalWidth) -ForegroundColor $BorderColor
        $centeredTitle = $Title.PadLeft([Math]::Floor(($totalWidth + $Title.Length) / 2)).PadRight($totalWidth)
        Write-Host $centeredTitle -ForegroundColor $TitleColor
    }
    
    # Write top border
    Write-Host ("-" * $totalWidth) -ForegroundColor $BorderColor
    
    # Write header row
    Write-Host -NoNewline "|" -ForegroundColor $BorderColor
    foreach ($prop in $Properties) {
        $headerText = " $prop ".PadRight($columnWidths[$prop])
        Write-Host -NoNewline $headerText -ForegroundColor $HeaderColor
        Write-Host -NoNewline "|" -ForegroundColor $BorderColor
    }
    Write-Host ""
    
    # Write header separator
    Write-Host ("-" * $totalWidth) -ForegroundColor $BorderColor
    
    # Write data rows
    foreach ($item in $Data) {
        Write-Host -NoNewline "|" -ForegroundColor $BorderColor
        foreach ($prop in $Properties) {
            $cellValue = " $($item.$prop) ".PadRight($columnWidths[$prop])
            Write-Host -NoNewline $cellValue -ForegroundColor White
            Write-Host -NoNewline "|" -ForegroundColor $BorderColor
        }
        Write-Host ""
    }
    
    # Write bottom border
    Write-Host ("-" * $totalWidth) -ForegroundColor $BorderColor
}

<#
.SYNOPSIS
    Displays a hierarchical tree view.
.DESCRIPTION
    Renders hierarchical data as a tree in the console with customizable formatting.
.PARAMETER Node
    The root node to display.
.PARAMETER ChildrenProperty
    The property name that contains child nodes.
.PARAMETER DisplayProperty
    The property name to use for node display text.
.PARAMETER Indent
    Current indentation level (used for recursion).
.PARAMETER LastChild
    Whether this is the last child node (used for recursion).
.PARAMETER NoColor
    Disable colored output.
.EXAMPLE
    Write-TreeView -Node $rootObject -ChildrenProperty "Children" -DisplayProperty "Name"
#>
function Write-TreeView {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Node,
        
        [Parameter(Mandatory = $true)]
        [string]$ChildrenProperty,
        
        [Parameter(Mandatory = $true)]
        [string]$DisplayProperty,
        
        [Parameter(Mandatory = $false)]
        [string]$Indent = "",
        
        [Parameter(Mandatory = $false)]
        [bool]$LastChild = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoColor = $false
    )
    
    # Get the display text
    $displayText = $Node.$DisplayProperty
    $connectorColor = if ($NoColor) { "White" } else { "DarkGray" }
    $textColor = if ($NoColor) { "White" } else { "Cyan" }
    
    # Write the current node
    $connector = if ($Indent -eq "") {
        ""
    } elseif ($LastChild) {
        "└── "
    } else {
        "├── "
    }
    
    Write-Host -NoNewline $Indent -ForegroundColor $connectorColor
    Write-Host -NoNewline $connector -ForegroundColor $connectorColor
    Write-Host $displayText -ForegroundColor $textColor
    
    # Get the children
    $children = $Node.$ChildrenProperty
    
    # Process children if they exist
    if ($children -and $children.Count -gt 0) {
        $nextIndent = if ($Indent -eq "") {
            ""
        } elseif ($LastChild) {
            "$Indent    "
        } else {
            "$Indent│   "
        }
        
        for ($i = 0; $i -lt $children.Count; $i++) {
            $isLastChild = ($i -eq ($children.Count - 1))
            Write-TreeView -Node $children[$i] -ChildrenProperty $ChildrenProperty -DisplayProperty $DisplayProperty `
                          -Indent $nextIndent -LastChild $isLastChild -NoColor:$NoColor
        }
    }
}

<#
.SYNOPSIS
    Highlights syntax in console output.
.DESCRIPTION
    Applies basic syntax highlighting to code blocks.
.PARAMETER Text
    The text to highlight.
.PARAMETER Language
    The language for syntax highlighting. Supported: xml, yaml, json, powershell
.EXAMPLE
    Write-SyntaxHighlight -Text $xmlContent -Language xml
#>
function Write-SyntaxHighlight {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("xml", "yaml", "json", "powershell")]
        [string]$Language
    )
    
    $lines = $Text -split "`n"
    
    switch ($Language) {
        "xml" {
            foreach ($line in $lines) {
                # Highlight XML tags
                if ($line -match '^(\s*)(<[\/\?]?)([^>\s]+)([^>]*)>(.*)$') {
                    $indent = $matches[1]
                    $tagStart = $matches[2]
                    $tagName = $matches[3] 
                    $attributes = $matches[4]
                    $rest = $matches[5]
                    
                    Write-Host -NoNewline $indent
                    Write-Host -NoNewline $tagStart -ForegroundColor DarkCyan
                    Write-Host -NoNewline $tagName -ForegroundColor Cyan
                    
                    # Highlight attributes
                    $attributes = $attributes -replace '(\w+)=("[^"]*")', '$1@$2'
                    $attributeParts = $attributes -split '@'
                    
                    foreach ($part in $attributeParts) {
                        if ($part -match '^(\w+)=(".+")$') {
                            Write-Host -NoNewline $matches[1] -ForegroundColor Yellow
                            Write-Host -NoNewline "=" -ForegroundColor Gray
                            Write-Host -NoNewline $matches[2] -ForegroundColor Green
                        } else {
                            Write-Host -NoNewline $part -ForegroundColor Gray
                        }
                    }
                    
                    Write-Host -NoNewline ">" -ForegroundColor DarkCyan
                    Write-Host $rest
                }
                # Comment lines
                elseif ($line -match '^\s*<!--.*-->') {
                    Write-Host $line -ForegroundColor DarkGreen
                }
                # Other lines
                else {
                    Write-Host $line
                }
            }
        }
        "yaml" {
            foreach ($line in $lines) {
                # Highlight keys
                if ($line -match '^(\s*)([^:]+)(:)(.*)$') {
                    $indent = $matches[1]
                    $key = $matches[2]
                    $colon = $matches[3]
                    $value = $matches[4]
                    
                    Write-Host -NoNewline $indent
                    Write-Host -NoNewline $key -ForegroundColor Cyan
                    Write-Host -NoNewline $colon -ForegroundColor Gray
                    
                    # Check for special values
                    if ($value -match '^\s*\&\w+') {
                        Write-Host $value -ForegroundColor Magenta
                    } elseif ($value -match '^\s*\*\w+') {
                        Write-Host $value -ForegroundColor Magenta
                    } else {
                        Write-Host $value
                    }
                }
                # List items
                elseif ($line -match '^(\s*)(-)(.*)$') {
                    $indent = $matches[1]
                    $dash = $matches[2]
                    $value = $matches[3]
                    
                    Write-Host -NoNewline $indent
                    Write-Host -NoNewline $dash -ForegroundColor Green
                    Write-Host $value
                }
                # Comments
                elseif ($line -match '^(\s*)(#.*)$') {
                    $indent = $matches[1]
                    $comment = $matches[2]
                    
                    Write-Host -NoNewline $indent
                    Write-Host $comment -ForegroundColor DarkGreen
                }
                # Other lines
                else {
                    Write-Host $line
                }
            }
        }
        "json" {
            foreach ($line in $lines) {
                # Quoted strings with keys
                if ($line -match '^(\s*)(".*?")(\s*:\s*)(.*)$') {
                    $indent = $matches[1]
                    $key = $matches[2]
                    $separator = $matches[3]
                    $value = $matches[4]
                    
                    Write-Host -NoNewline $indent
                    Write-Host -NoNewline $key -ForegroundColor Cyan
                    Write-Host -NoNewline $separator -ForegroundColor Gray
                    
                    # Check for string values
                    if ($value -match '^".*"') {
                        Write-Host $value -ForegroundColor Green
                    } 
                    # Numeric values
                    elseif ($value -match '^-?\d+(\.\d+)?') {
                        Write-Host $value -ForegroundColor Magenta
                    }
                    # Boolean or null
                    elseif ($value -match '^(true|false|null)') {
                        Write-Host $value -ForegroundColor Blue
                    }
                    # Other values
                    else {
                        Write-Host $value
                    }
                }
                # Brackets and commas
                elseif ($line -match '^(\s*)([\[\]{},])(.*)$') {
                    $indent = $matches[1]
                    $bracket = $matches[2]
                    $rest = $matches[3]
                    
                    Write-Host -NoNewline $indent
                    Write-Host -NoNewline $bracket -ForegroundColor DarkCyan
                    Write-Host $rest
                }
                # Other lines
                else {
                    Write-Host $line
                }
            }
        }
        "powershell" {
            foreach ($line in $lines) {
                # Comments
                if ($line -match '^(\s*)(#.*)$') {
                    $indent = $matches[1]
                    $comment = $matches[2]
                    
                    Write-Host -NoNewline $indent
                    Write-Host $comment -ForegroundColor DarkGreen
                }
                # Function declarations
                elseif ($line -match '^(\s*)(function)\s+([^\s\(]+)(.*)$') {
                    $indent = $matches[1]
                    $keyword = $matches[2]
                    $name = $matches[3]
                    $rest = $matches[4]
                    
                    Write-Host -NoNewline $indent
                    Write-Host -NoNewline $keyword -ForegroundColor Blue
                    Write-Host -NoNewline " "
                    Write-Host -NoNewline $name -ForegroundColor Yellow
                    Write-Host $rest
                }
                # Parameters
                elseif ($line -match '^(\s*)(\[Parameter.+\])(.*)$') {
                    $indent = $matches[1]
                    $param = $matches[2]
                    $rest = $matches[3]
                    
                    Write-Host -NoNewline $indent
                    Write-Host -NoNewline $param -ForegroundColor DarkCyan
                    Write-Host $rest
                }
                # Variable assignments
                elseif ($line -match '^(\s*)(\$\w+)(\s*=\s*)(.*)$') {
                    $indent = $matches[1]
                    $var = $matches[2]
                    $equals = $matches[3]
                    $value = $matches[4]
                    
                    Write-Host -NoNewline $indent
                    Write-Host -NoNewline $var -ForegroundColor Magenta
                    Write-Host -NoNewline $equals -ForegroundColor Gray
                    Write-Host $value
                }
                # Keywords
                elseif ($line -match '\b(if|else|for|foreach|while|switch|try|catch|finally|param|begin|process|end|return|exit)\b') {
                    $formattedLine = $line
                    foreach ($keyword in @('if', 'else', 'for', 'foreach', 'while', 'switch', 'try', 'catch', 'finally', 'param', 'begin', 'process', 'end', 'return', 'exit')) {
                        $formattedLine = $formattedLine -replace "\b$keyword\b", "~~$keyword~~"
                    }
                    
                    $parts = $formattedLine -split "~~"
                    for ($i = 0; $i -lt $parts.Length; $i++) {
                        if ($i % 2 -eq 0) {
                            Write-Host -NoNewline $parts[$i]
                        } else {
                            Write-Host -NoNewline $parts[$i] -ForegroundColor Blue
                        }
                    }
                    Write-Host ""
                }
                # Other lines
                else {
                    Write-Host $line
                }
            }
        }
    }
}

#endregion

# Export all functions
Export-ModuleMember -Function Write-Banner, Write-SectionHeader, Write-InfoMessage, Write-SuccessMessage, 
    Write-WarningMessage, Write-ErrorMessage, Write-ProgressBar, Show-ActivitySpinner,
    Write-ConsoleTable, Write-TreeView, Write-SyntaxHighlight

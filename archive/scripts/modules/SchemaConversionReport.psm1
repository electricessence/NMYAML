# SchemaConversionReport.psm1
# Module for tracking and reporting changes during schema conversion

# Maintains a detailed log of all changes made during schema conversion
$script:conversionLog = @()

<#
.SYNOPSIS
    Adds an entry to the conversion log
.DESCRIPTION
    Records an individual change made during the schema conversion process
.PARAMETER ChangeType
    Type of change made (e.g., RemoveNamespace, ConvertReference, etc.)
.PARAMETER Element
    The element where the change was made
.PARAMETER OriginalValue
    The original value before conversion
.PARAMETER NewValue
    The new value after conversion
.PARAMETER Path
    XPath or description of where in the document the change occurred
#>
function Add-ConversionLogEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ChangeType,
        
        [Parameter(Mandatory=$true)]
        [string]$Element,
        
        [Parameter(Mandatory=$false)]
        [string]$OriginalValue = "",
        
        [Parameter(Mandatory=$false)]
        [string]$NewValue = "",
        
        [Parameter(Mandatory=$false)]
        [string]$Path = ""
    )
    
    $script:conversionLog += [PSCustomObject]@{
        ChangeType = $ChangeType
        Element = $Element
        OriginalValue = $OriginalValue
        NewValue = $NewValue
        Path = $Path
        Timestamp = Get-Date
    }
}

<#
.SYNOPSIS
    Clears the conversion log
.DESCRIPTION
    Resets the conversion log to prepare for a new conversion
#>
function Clear-ConversionLog {
    $script:conversionLog = @()
}

<#
.SYNOPSIS
    Gets all entries from the conversion log
.DESCRIPTION
    Returns the entire conversion log for analysis
.OUTPUTS
    Array of conversion log entries
#>
function Get-ConversionLog {
    return $script:conversionLog
}

<#
.SYNOPSIS
    Summarizes the conversion changes by type
.DESCRIPTION
    Provides a summary of all changes made during conversion, grouped by type
.OUTPUTS
    PSObject with change summary information
#>
function Get-ConversionSummary {
    $changeTypes = $script:conversionLog | Group-Object -Property ChangeType
    $summary = [PSCustomObject]@{
        TotalChanges = $script:conversionLog.Count
        ChangesByType = $changeTypes | ForEach-Object {
            [PSCustomObject]@{
                Type = $_.Name
                Count = $_.Count
                Elements = ($_.Group | Select-Object -ExpandProperty Element | Sort-Object -Unique) -join ", "
            }
        }
    }
    
    return $summary
}

<#
.SYNOPSIS
    Exports the conversion log to an XML file
.DESCRIPTION
    Saves the detailed conversion log as an XML file for later analysis
.PARAMETER OutputPath
    Path where to save the XML file
#>
function Export-ConversionLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    # Create wrapper object
    $report = [PSCustomObject]@{
        ConversionReport = [PSCustomObject]@{
            GeneratedOn = Get-Date
            TotalChanges = $script:conversionLog.Count
            Changes = $script:conversionLog
        }
    }
    
    # Export to XML
    $report | ConvertTo-Xml -Depth 5 -As Document | Save-Xml -Path $OutputPath
}

<#
.SYNOPSIS
    Helper function to save an XML document
.DESCRIPTION
    Saves an XML document with proper formatting
.PARAMETER XmlDoc
    The XML document to save
.PARAMETER Path
    Path where to save the XML file
#>
function Save-Xml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [System.Xml.XmlDocument]$XmlDoc,
        
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    # Create writer settings
    $writerSettings = New-Object System.Xml.XmlWriterSettings
    $writerSettings.Indent = $true
    $writerSettings.IndentChars = "  "
    $writerSettings.Encoding = [System.Text.UTF8Encoding]::new($false) # UTF8 without BOM
    
    # Use XmlWriter to save the document with formatting
    $writer = [System.Xml.XmlWriter]::Create($Path, $writerSettings)
    try {
        $XmlDoc.Save($writer)
    }
    finally {
        $writer.Close()
    }
}

# Export functions
Export-ModuleMember -Function Add-ConversionLogEntry, Clear-ConversionLog, Get-ConversionLog, Get-ConversionSummary, Export-ConversionLog

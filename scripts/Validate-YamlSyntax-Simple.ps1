# Simple YAML Validation Script
# This script performs basic YAML syntax and GitHub Actions workflow validation

param(
    [string]$YamlFile = ".\output\dotnet-library-workflow.yml",
    [switch]$Detailed,
    [switch]$ExportReport
)

# Simple validation class
class SimpleValidationResult {
    [string]$Type
    [string]$Severity
    [string]$Message
    [int]$LineNumber
    [string]$Context
    
    SimpleValidationResult([string]$type, [string]$severity, [string]$message, [int]$lineNumber, [string]$context) {
        $this.Type = $type
        $this.Severity = $severity
        $this.Message = $message
        $this.LineNumber = $lineNumber
        $this.Context = $context
    }
}

function Test-YamlFile {
    param([string]$FilePath)
    
    $results = @()
    
    if (-not (Test-Path $FilePath)) {
        $results += [SimpleValidationResult]::new("File", "Error", "YAML file not found: $FilePath", 0, "")
        return $results
    }
    
    try {
        $lines = Get-Content $FilePath
        Write-Host "Read $($lines.Count) lines from file" -ForegroundColor Green
        
        if ($lines.Count -eq 0) {
            $results += [SimpleValidationResult]::new("File", "Error", "YAML file is empty", 0, "")
            return $results
        }
        
        # Detect GitHub Actions workflow
        $isGitHubWorkflow = $false
        foreach ($line in $lines) {
            if ($line -match '^\s*(name|on|jobs):\s*' -or $line -match 'runs-on:|uses:') {
                $isGitHubWorkflow = $true
                break
            }
        }
        
        Write-Host "GitHub Actions workflow detected: $isGitHubWorkflow" -ForegroundColor $(if($isGitHubWorkflow) {"Green"} else {"Yellow"})
        
        # Basic syntax validation
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            $lineNum = $i + 1
            
            # Check for tab characters
            if ($line -match '\t') {
                $results += [SimpleValidationResult]::new("Indentation", "Warning", "Tab characters found - use spaces instead", $lineNum, $line.Trim())
            }
            
            # Check for trailing whitespace
            if ($line -match '\s+$' -and $line.Trim() -ne '') {
                $results += [SimpleValidationResult]::new("Formatting", "Info", "Trailing whitespace", $lineNum, $line.Trim())
            }
            
            # Check for unmatched quotes (simple check)
            $singleQuotes = ($line.ToCharArray() | Where-Object { $_ -eq "'" }).Count
            $doubleQuotes = ($line.ToCharArray() | Where-Object { $_ -eq '"' }).Count
            
            if ($singleQuotes % 2 -ne 0) {
                $results += [SimpleValidationResult]::new("Syntax", "Error", "Unmatched single quote", $lineNum, $line.Trim())
            }
            
            if ($doubleQuotes % 2 -ne 0) {
                $results += [SimpleValidationResult]::new("Syntax", "Error", "Unmatched double quote", $lineNum, $line.Trim())
            }
            
            # Check for empty list items
            if ($line -match '^\s*-\s*$') {
                $results += [SimpleValidationResult]::new("Syntax", "Warning", "Empty list item", $lineNum, $line.Trim())
            }
        }
        
        # GitHub Actions specific checks
        if ($isGitHubWorkflow) {
            $hasName = $false
            $hasOn = $false
            $hasJobs = $false
            
            foreach ($line in $lines) {
                if ($line -match '^\s*name:\s*') { $hasName = $true }
                if ($line -match '^\s*on:\s*') { $hasOn = $true }
                if ($line -match '^\s*jobs:\s*') { $hasJobs = $true }
            }
            
            if (-not $hasName) {
                $results += [SimpleValidationResult]::new("Structure", "Warning", "GitHub Actions workflow missing 'name' field", 1, "")
            }
            
            if (-not $hasOn) {
                $results += [SimpleValidationResult]::new("Structure", "Error", "GitHub Actions workflow missing 'on' trigger field", 1, "")
            }
            
            if (-not $hasJobs) {
                $results += [SimpleValidationResult]::new("Structure", "Error", "GitHub Actions workflow missing 'jobs' section", 1, "")
            }
        }
        
        Write-Host "Validation completed. Found $($results.Count) issues." -ForegroundColor Blue
        
    } catch {
        $results += [SimpleValidationResult]::new("File", "Error", "Failed to read YAML file: $($_.Exception.Message)", 0, "")
    }
    
    return $results
}

function Show-ValidationReport {
    param($Results, [bool]$Detailed, [bool]$ExportToFile)
    
    $summary = @{
        TotalIssues = $Results.Count
        Errors = ($Results | Where-Object { $_.Severity -eq "Error" }).Count
        Warnings = ($Results | Where-Object { $_.Severity -eq "Warning" }).Count
        Info = ($Results | Where-Object { $_.Severity -eq "Info" }).Count
    }
    
    Write-Host "`n=== YAML Validation Report ===" -ForegroundColor Cyan
    Write-Host "Total Issues: $($summary.TotalIssues)" -ForegroundColor White
    Write-Host "Errors: $($summary.Errors)" -ForegroundColor Red
    Write-Host "Warnings: $($summary.Warnings)" -ForegroundColor Yellow
    Write-Host "Info: $($summary.Info)" -ForegroundColor Blue
    
    if ($Detailed -and $Results.Count -gt 0) {
        Write-Host "`n=== Issues by Category ===" -ForegroundColor Cyan
        
        $categories = $Results | Group-Object Type | Sort-Object Name
        foreach ($category in $categories) {
            Write-Host "`n[$($category.Name)]" -ForegroundColor Magenta
            
            foreach ($issue in ($category.Group | Sort-Object LineNumber)) {
                $color = switch ($issue.Severity) {
                    "Error" { "Red" }
                    "Warning" { "Yellow" }
                    "Info" { "Blue" }
                    default { "White" }
                }
                
                Write-Host "  Line $($issue.LineNumber): $($issue.Message)" -ForegroundColor $color
                if ($issue.Context -and $issue.Context.Trim() -ne '') {
                    Write-Host "    Context: $($issue.Context)" -ForegroundColor DarkGray
                }
            }
        }
    }
    
    if ($ExportToFile) {
        $reportData = @{
            Summary = $summary
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Issues = $Results | ForEach-Object {
                @{
                    Type = $_.Type
                    Severity = $_.Severity
                    Message = $_.Message
                    LineNumber = $_.LineNumber
                    Context = $_.Context
                }
            }
        }
        
        $reportPath = "validation-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $reportData | ConvertTo-Json -Depth 3 | Out-File $reportPath -Encoding UTF8
        Write-Host "`nReport exported to: $reportPath" -ForegroundColor Green
    }
    
    # Return appropriate exit code
    if ($summary.Errors -gt 0) {
        Write-Host "`nValidation failed with errors!" -ForegroundColor Red
        return 1
    } elseif ($summary.Warnings -gt 0) {
        Write-Host "`nValidation completed with warnings." -ForegroundColor Yellow
        return 0
    } else {
        Write-Host "`nValidation passed!" -ForegroundColor Green
        return 0
    }
}

# Main execution
Write-Host "Simple YAML Validation Tool" -ForegroundColor Cyan
Write-Host "Validating file: $YamlFile" -ForegroundColor White

$validationResults = Test-YamlFile -FilePath $YamlFile
$exitCode = Show-ValidationReport -Results $validationResults -Detailed:$Detailed -ExportToFile:$ExportReport

exit $exitCode

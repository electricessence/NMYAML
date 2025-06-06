# Comprehensive YAML Validation Script
# This script performs extensive YAML syntax and GitHub Actions workflow validation

param(
    [string]$YamlFile = ".\output\dotnet-library-workflow.yml",
    [switch]$Detailed,
    [switch]$GitHubActions,
    [switch]$ExportReport
)

class ValidationResult {
    [string]$Type
    [string]$Severity
    [string]$Message
    [int]$LineNumber
    [string]$Context
    
    ValidationResult([string]$type, [string]$severity, [string]$message, [int]$lineNumber, [string]$context) {
        $this.Type = $type
        $this.Severity = $severity
        $this.Message = $message
        $this.LineNumber = $lineNumber
        $this.Context = $context
    }
}

class YamlValidator {
    [System.Collections.Generic.List[ValidationResult]]$Results
    [string[]]$Lines
    [hashtable]$GitHubActionsSchema
    [bool]$IsGitHubActionsWorkflow
    
    YamlValidator() {
        $this.Results = [System.Collections.Generic.List[ValidationResult]]::new()
        $this.InitializeGitHubActionsSchema()
    }
    
    [void] InitializeGitHubActionsSchema() {
        $this.GitHubActionsSchema = @{
            RequiredTopLevel = @('name', 'on')
            OptionalTopLevel = @('env', 'defaults', 'concurrency', 'jobs', 'permissions', 'run-name')
            JobProperties = @('runs-on', 'steps', 'needs', 'if', 'name', 'permissions', 'environment', 'concurrency', 'outputs', 'env', 'defaults', 'timeout-minutes', 'strategy', 'continue-on-error', 'container', 'services')
            StepProperties = @('name', 'id', 'if', 'run', 'uses', 'with', 'env', 'continue-on-error', 'timeout-minutes', 'shell', 'working-directory')
            TriggerEvents = @('push', 'pull_request', 'pull_request_target', 'workflow_dispatch', 'workflow_call', 'schedule', 'repository_dispatch', 'release', 'issues', 'issue_comment', 'watch', 'fork', 'create', 'delete', 'deployment', 'deployment_status', 'page_build', 'public', 'status', 'gollum', 'member', 'membership', 'project', 'project_card', 'project_column', 'milestone', 'label', 'discussion', 'discussion_comment', 'check_run', 'check_suite')
            RunnerLabels = @('ubuntu-latest', 'ubuntu-20.04', 'ubuntu-18.04', 'ubuntu-22.04', 'windows-latest', 'windows-2022', 'windows-2019', 'macos-latest', 'macos-12', 'macos-11', 'self-hosted')
            Shells = @('bash', 'pwsh', 'powershell', 'cmd', 'sh', 'python')
            SecurityPatterns = @('secrets\.', '\$\{\{\s*secrets\.')
            ReservedWords = @('env', 'secrets', 'github', 'runner', 'job', 'steps', 'matrix', 'strategy', 'needs', 'inputs', 'outputs')
        }
    }
    
    [void] ValidateFile([string]$filePath) {
        if (-not (Test-Path $filePath)) {
            $this.Results.Add([ValidationResult]::new("File", "Error", "YAML file not found: $filePath", 0, ""))
            return
        }
        
        try {
            $this.Lines = Get-Content $filePath
            if ($this.Lines.Count -eq 0) {
                $this.Results.Add([ValidationResult]::new("File", "Error", "YAML file is empty", 0, ""))
                return
            }
            
            # Detect if this is a GitHub Actions workflow
            $this.IsGitHubActionsWorkflow = $this.DetectGitHubActionsWorkflow()
            
            # Run all validations
            $this.ValidateBasicSyntax()
            $this.ValidateIndentation()
            $this.ValidateQuoting()
            $this.ValidateKeys()
            $this.ValidateValues()
            $this.ValidateStructure()
            $this.ValidateSpecialCharacters()
            $this.ValidateComments()
            
            if ($this.IsGitHubActionsWorkflow) {
                $this.ValidateGitHubActions()
            }
            
        } catch {
            $this.Results.Add([ValidationResult]::new("File", "Error", "Failed to read YAML file: $($_.Exception.Message)", 0, ""))
        }
    }
    
    [bool] DetectGitHubActionsWorkflow() {
        foreach ($line in $this.Lines) {
            if ($line -match '^\s*(name|on|jobs):\s*' -or $line -match 'runs-on:|uses:|github\.') {
                return $true
            }
        }
        return $false
    }
    
    [void] ValidateBasicSyntax() {
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            # Check for basic YAML syntax issues
            if ($line -match '^\s*-\s*$') {
                $this.Results.Add([ValidationResult]::new("Syntax", "Warning", "Empty list item", $lineNum, $line.Trim()))
            }
            
            if ($line -match ':\s*$' -and $line -notmatch '^\s*#' -and $line -notmatch '^\s*-') {
                # Check if next line is properly indented
                if ($i + 1 -lt $this.Lines.Count) {
                    $nextLine = $this.Lines[$i + 1]
                    $currentIndent = ($line -replace '^(\s*).*', '$1').Length
                    $nextIndent = ($nextLine -replace '^(\s*).*', '$1').Length
                    
                    if ($nextLine.Trim() -ne '' -and $nextLine -notmatch '^\s*#' -and $nextIndent -le $currentIndent) {
                        $this.Results.Add([ValidationResult]::new("Syntax", "Warning", "Possible missing value for key", $lineNum, $line.Trim()))
                    }
                }
            }
            
            # Check for invalid characters in keys
            if ($line -match '^(\s*)([^:\s#]+):\s*') {
                $key = $matches[2]
                if ($key -match '[^\w\-_.]') {
                    $this.Results.Add([ValidationResult]::new("Syntax", "Warning", "Key contains potentially problematic characters: $key", $lineNum, $line.Trim()))
                }
            }
        }
    }
    
    [void] ValidateIndentation() {
        $indentStack = @()
        
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            if ($line.Trim() -eq '' -or $line -match '^\s*#') {
                continue
            }
            
            $indent = ($line -replace '^(\s*).*', '$1').Length
            
            # Check for tab characters
            if ($line -match '\t') {
                $this.Results.Add([ValidationResult]::new("Indentation", "Error", "Tab characters found - use spaces instead", $lineNum, $line))
            }
            
            # Validate indentation consistency
            if ($indentStack.Count -gt 0) {
                $lastIndent = $indentStack[-1]
                if ($indent -gt $lastIndent -and ($indent - $lastIndent) -ne 2) {
                    $this.Results.Add([ValidationResult]::new("Indentation", "Warning", "Inconsistent indentation - expected 2 spaces", $lineNum, $line.Trim()))
                }
            }
            
            # Update indent stack
            while ($indentStack.Count -gt 0 -and $indent -le $indentStack[-1]) {
                $indentStack = $indentStack[0..($indentStack.Count - 2)]
            }
            
            if ($line -match ':' -or $line -match '^\s*-') {
                $indentStack += $indent
            }
        }
    }
    
    [void] ValidateQuoting() {
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            # Check for unmatched quotes
            $singleQuotes = ([regex]::Matches($line, "'")).Count
            $doubleQuotes = ([regex]::Matches($line, '"')).Count
            
            if ($singleQuotes % 2 -ne 0) {
                $this.Results.Add([ValidationResult]::new("Quoting", "Error", "Unmatched single quote", $lineNum, $line.Trim()))
            }
            
            if ($doubleQuotes % 2 -ne 0) {
                $this.Results.Add([ValidationResult]::new("Quoting", "Error", "Unmatched double quote", $lineNum, $line.Trim()))
            }
            
            # Check for values that should be quoted
            if ($line -match ':\s*([^"#\n\r]+)$') {
                $value = $matches[1].Trim()
                if ($value -match '^[0-9]+\.[0-9]+$' -and $value -notmatch '^\d{4}-\d{2}-\d{2}') {
                    $this.Results.Add([ValidationResult]::new("Quoting", "Info", "Version number should be quoted to preserve as string: $value", $lineNum, $line.Trim()))
                }
                
                if ($value -match '^(true|false|yes|no|on|off)$' -and $line -notmatch 'boolean|flag') {
                    $this.Results.Add([ValidationResult]::new("Quoting", "Info", "Boolean-like value might need quoting if intended as string: $value", $lineNum, $line.Trim()))
                }
            }
        }
    }
    
    [void] ValidateKeys() {
        $keyUsage = @{}
        
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            if ($line -match '^(\s*)([^:\s#]+):\s*') {
                $indent = $matches[1].Length
                $key = $matches[2]
                
                # Track key usage at same indentation level
                $levelKey = "$indent`:$key"
                if ($keyUsage.ContainsKey($levelKey)) {
                    $this.Results.Add([ValidationResult]::new("Keys", "Error", "Duplicate key at same level: $key", $lineNum, $line.Trim()))
                } else {
                    $keyUsage[$levelKey] = $lineNum
                }
                
                # Check for reserved words in inappropriate contexts
                if ($this.IsGitHubActionsWorkflow -and $this.GitHubActionsSchema.ReservedWords -contains $key) {
                    if ($line -notmatch '(env|with|inputs|outputs):') {
                        $this.Results.Add([ValidationResult]::new("Keys", "Warning", "Using GitHub Actions reserved word as key: $key", $lineNum, $line.Trim()))
                    }
                }
            }
        }
    }
    
    [void] ValidateValues() {
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            # Check for potentially problematic values
            if ($line -match ':\s*(.+)$') {
                $value = $matches[1].Trim()
                
                # Check for unescaped special characters
                if ($value -match '[<>&]' -and $value -notmatch '^["''].*["'']$') {
                    $this.Results.Add([ValidationResult]::new("Values", "Warning", "Value contains special characters that might need escaping: $value", $lineNum, $line.Trim()))
                }
                
                # Check for very long lines
                if ($value.Length -gt 120) {
                    $this.Results.Add([ValidationResult]::new("Values", "Info", "Very long value - consider using multi-line format", $lineNum, $line.Trim()))
                }
                
                # Check for potential security issues
                foreach ($pattern in $this.GitHubActionsSchema.SecurityPatterns) {
                    if ($value -match $pattern) {
                        $this.Results.Add([ValidationResult]::new("Security", "Warning", "Potential security issue - secrets reference found", $lineNum, $line.Trim()))
                    }
                }
            }
        }
    }
    
    [void] ValidateStructure() {
        $structure = @{}
        $currentPath = @()
        
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            if ($line.Trim() -eq '' -or $line -match '^\s*#') {
                continue
            }
            
            $indent = ($line -replace '^(\s*).*', '$1').Length
            
            # Adjust current path based on indentation
            while ($currentPath.Count -gt 0 -and $indent -le $currentPath[-1].Indent) {
                $currentPath = $currentPath[0..($currentPath.Count - 2)]
            }
            
            if ($line -match '^(\s*)([^:\s#]+):\s*') {
                $key = $matches[2]
                $pathItem = @{ Key = $key; Indent = $indent; Line = $lineNum }
                $currentPath += $pathItem
                
                # Build full path
                $fullPath = ($currentPath | ForEach-Object { $_.Key }) -join '.'
                $structure[$fullPath] = $lineNum
            }
        }
        
        # Check for common structural issues
        if ($this.IsGitHubActionsWorkflow) {
            if (-not $structure.ContainsKey('name')) {
                $this.Results.Add([ValidationResult]::new("Structure", "Warning", "GitHub Actions workflow missing 'name' field", 1, ""))
            }
            
            if (-not $structure.ContainsKey('on')) {
                $this.Results.Add([ValidationResult]::new("Structure", "Error", "GitHub Actions workflow missing 'on' trigger field", 1, ""))
            }
            
            if (-not $structure.ContainsKey('jobs')) {
                $this.Results.Add([ValidationResult]::new("Structure", "Error", "GitHub Actions workflow missing 'jobs' section", 1, ""))
            }
        }
    }
    
    [void] ValidateSpecialCharacters() {
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            # Check for non-ASCII characters
            if ($line -match '[^\x00-\x7F]') {
                $this.Results.Add([ValidationResult]::new("Characters", "Info", "Non-ASCII characters found", $lineNum, $line.Trim()))
            }
            
            # Check for invisible characters
            if ($line -match '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]') {
                $this.Results.Add([ValidationResult]::new("Characters", "Warning", "Invisible/control characters found", $lineNum, $line.Trim()))
            }
            
            # Check for trailing whitespace
            if ($line -match '\s+$') {
                $this.Results.Add([ValidationResult]::new("Characters", "Info", "Trailing whitespace", $lineNum, $line))
            }
        }
    }
    
    [void] ValidateComments() {
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            if ($line -match '^\s*#') {
                # Check comment format
                if ($line -match '^\s*#[^\s]' -and $line -notmatch '^\s*#[\w\-_#]') {
                    $this.Results.Add([ValidationResult]::new("Comments", "Info", "Consider adding space after # in comment", $lineNum, $line.Trim()))
                }
            }
            
            # Check for inline comments (simplified regex)
            if ($line -match '#' -and $line -notmatch '^\s*#') {
                $this.Results.Add([ValidationResult]::new("Comments", "Info", "Inline comment found - ensure it doesn't interfere with values", $lineNum, $line.Trim()))
            }
        }
    }
    
    [void] ValidateGitHubActions() {
        $inJobsSection = $false
        $currentJob = ""
        $inStepsSection = $false
        
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            # Track sections
            if ($line -match '^\s*jobs:\s*$') {
                $inJobsSection = $true
                continue
            }
            
            if ($inJobsSection -and $line -match '^\s{2}([^:\s]+):\s*$') {
                $currentJob = $matches[1]
                $inStepsSection = $false
            }
            
            if ($line -match '^\s{4}steps:\s*$') {
                $inStepsSection = $true
            }
            
            # Validate trigger events
            if ($line -match '^\s*on:\s*$') {
                # Check next lines for valid events
                for ($j = $i + 1; $j -lt $this.Lines.Count -and $this.Lines[$j] -match '^\s{2}'; $j++) {
                    $eventLine = $this.Lines[$j]
                    if ($eventLine -match '^\s{2}([^:\s]+):') {
                        $event = $matches[1]
                        if ($this.GitHubActionsSchema.TriggerEvents -notcontains $event) {
                            $this.Results.Add([ValidationResult]::new("GitHub Actions", "Warning", "Unknown trigger event: $event", $j + 1, $eventLine.Trim()))
                        }
                    }
                }
            }
            
            # Validate runner labels
            if ($line -match 'runs-on:\s*(.+)$') {
                $runner = $matches[1].Trim()
                $runner = $runner -replace '["'']', ''
                
                if ($this.GitHubActionsSchema.RunnerLabels -notcontains $runner -and $runner -notmatch '^\$\{\{') {
                    $this.Results.Add([ValidationResult]::new("GitHub Actions", "Warning", "Non-standard runner label: $runner", $lineNum, $line.Trim()))
                }
            }
            
            # Validate shell types
            if ($line -match 'shell:\s*(.+)$') {
                $shell = $matches[1].Trim()
                $shell = $shell -replace '["'']', ''
                
                if ($this.GitHubActionsSchema.Shells -notcontains $shell) {
                    $this.Results.Add([ValidationResult]::new("GitHub Actions", "Warning", "Unknown shell type: $shell", $lineNum, $line.Trim()))
                }
            }
            
            # Check for required job properties
            if ($currentJob -ne "" -and $line -match '^\s{4}([^:\s]+):\s*') {
                $prop = $matches[1]
                if ($this.GitHubActionsSchema.JobProperties -notcontains $prop -and $prop -ne "steps") {
                    $this.Results.Add([ValidationResult]::new("GitHub Actions", "Info", "Non-standard job property: $prop", $lineNum, $line.Trim()))
                }
            }
            
            # Validate step properties
            if ($inStepsSection -and $line -match '^\s{8}([^:\s]+):\s*') {
                $prop = $matches[1]
                if ($this.GitHubActionsSchema.StepProperties -notcontains $prop) {
                    $this.Results.Add([ValidationResult]::new("GitHub Actions", "Info", "Non-standard step property: $prop", $lineNum, $line.Trim()))
                }
            }
            
            # Check for common GitHub Actions patterns
            if ($line -match '\$\{\{\s*([^}]+)\s*\}\}') {
                $expression = $matches[1]
                # Validate expression syntax (simplified)
                if ($expression -match '[^A-Za-z0-9\.\-_\(\)\s\|&!=<>]') {
                    $this.Results.Add([ValidationResult]::new("GitHub Actions", "Warning", "Complex expression - verify syntax: $expression", $lineNum, $line.Trim()))
                }
            }
        }
    }
    
    [void] GenerateReport([bool]$detailed, [bool]$exportToFile) {
        $summary = @{
            TotalIssues = $this.Results.Count
            Errors = ($this.Results | Where-Object { $_.Severity -eq "Error" }).Count
            Warnings = ($this.Results | Where-Object { $_.Severity -eq "Warning" }).Count
            Info = ($this.Results | Where-Object { $_.Severity -eq "Info" }).Count
        }
        
        Write-Host "`n=== YAML Validation Report ===" -ForegroundColor Cyan
        Write-Host "Total Issues: $($summary.TotalIssues)" -ForegroundColor White
        Write-Host "Errors: $($summary.Errors)" -ForegroundColor Red
        Write-Host "Warnings: $($summary.Warnings)" -ForegroundColor Yellow
        Write-Host "Info: $($summary.Info)" -ForegroundColor Blue
        
        if ($this.IsGitHubActionsWorkflow) {
            Write-Host "Detected: GitHub Actions Workflow" -ForegroundColor Green
        }
        
        if ($detailed -and $this.Results.Count -gt 0) {
            Write-Host "`n=== Issues by Category ===" -ForegroundColor Cyan
            
            $categories = $this.Results | Group-Object Type | Sort-Object Name
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
                    if ($issue.Context) {
                        Write-Host "    Context: $($issue.Context)" -ForegroundColor DarkGray
                    }
                }
            }
        }
        
        if ($exportToFile) {
            $reportData = @{
                Summary = $summary
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                IsGitHubActionsWorkflow = $this.IsGitHubActionsWorkflow
                Issues = $this.Results | ForEach-Object {
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
        
        # Exit with appropriate code
        if ($summary.Errors -gt 0) {
            Write-Host "`nValidation failed with errors!" -ForegroundColor Red
            exit 1
        } elseif ($summary.Warnings -gt 0) {
            Write-Host "`nValidation completed with warnings." -ForegroundColor Yellow
            exit 0
        } else {
            Write-Host "`nValidation passed!" -ForegroundColor Green
            exit 0
        }
    }
}

# Main execution
Write-Host "YAML Comprehensive Validation Tool" -ForegroundColor Cyan
Write-Host "Validating file: $YamlFile" -ForegroundColor White

$validator = [YamlValidator]::new()
$validator.ValidateFile($YamlFile)
$validator.GenerateReport($Detailed, $ExportReport)

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
            ReservedWords = @('env', 'secrets', 'github', 'runner', 'job', 'steps', 'matrix', 'strategy', 'needs', 'inputs', 'outputs')
        }
    }
    
    [void] ValidateFile([string]$filePath, [bool]$enableGitHubActions) {
        if (-not (Test-Path $filePath)) {
            $this.Results.Add([ValidationResult]::new("File", "Error", "File not found: $filePath", 0, ""))
            return
        }
        
        try {
            $this.Lines = Get-Content -Path $filePath
            $content = Get-Content -Path $filePath -Raw
            
            # Detect if this is a GitHub Actions workflow
            $this.IsGitHubActionsWorkflow = $content -match "(?m)^name\s*:" -and $content -match "(?m)^on\s*:" -and $content -match "(?m)^jobs\s*:"
            
            # Perform all validations
            $this.ValidateBasicSyntax()
            $this.ValidateIndentation()
            $this.ValidateQuoting()
            $this.ValidateKeys()
            $this.ValidateValues()
            $this.ValidateStructure()
            $this.ValidateSpecialCharacters()
            $this.ValidateComments()
            
            if ($enableGitHubActions -or $this.IsGitHubActionsWorkflow) {
                $this.ValidateGitHubActions()
            }
        }
        catch {
            $this.Results.Add([ValidationResult]::new("System", "Error", "Validation error: $($_.Exception.Message)", 0, ""))
        }
    }
    
    [void] ValidateBasicSyntax() {
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            # Check for tabs
            if ($line -match "`t") {
                $this.Results.Add([ValidationResult]::new("Syntax", "Error", "Tab characters found (YAML requires spaces)", $lineNum, $line.Trim()))
            }
            
            # Check for trailing whitespace
            if ($line -match '\s+$' -and $line.Trim() -ne "") {
                $this.Results.Add([ValidationResult]::new("Style", "Warning", "Trailing whitespace found", $lineNum, $line))
            }
            
            # Check for missing space after colon
            if ($line -match ':[^\s\r\n]' -and $line -notmatch 'https?://' -and $line -notmatch '^\s*#') {
                $this.Results.Add([ValidationResult]::new("Syntax", "Error", "Missing space after colon", $lineNum, $line.Trim()))
            }
            
            # Check for empty keys
            if ($line -match '^\s*:\s*\S') {
                $this.Results.Add([ValidationResult]::new("Syntax", "Error", "Empty key found", $lineNum, $line.Trim()))
            }
            
            # Check for duplicate colons in key
            if ($line -match '^\s*[^:]+:.*:.*$' -and $line -notmatch '^\s*#' -and $line -notmatch 'https?://') {
                $this.Results.Add([ValidationResult]::new("Syntax", "Warning", "Multiple colons in line (potential key/value issue)", $lineNum, $line.Trim()))
            }
        }
    }
    
    [void] ValidateIndentation() {
        $indentLevels = @()
        $previousIndent = 0
        
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            if ($line -match '^(\s*)(.+)$' -and $line.Trim() -ne "" -and -not $line.Trim().StartsWith('#')) {
                $indent = $matches[1].Length
                $content = $matches[2]
                
                # Track indent levels
                if ($indent -gt 0 -and $indentLevels -notcontains $indent) {
                    $indentLevels += $indent
                }
                
                # Check for non-multiple of 2 indentation
                if ($indent % 2 -ne 0) {
                    $this.Results.Add([ValidationResult]::new("Style", "Warning", "Indentation is not a multiple of 2 spaces", $lineNum, $line))
                }
                
                # Check for inconsistent indentation jumps
                if ($indent -gt $previousIndent -and ($indent - $previousIndent) -gt 2) {
                    $this.Results.Add([ValidationResult]::new("Style", "Warning", "Large indentation jump (jumped by $($indent - $previousIndent) spaces)", $lineNum, $line.Trim()))
                }
                
                $previousIndent = $indent
            }
        }
        
        # Check for consistent spacing across indent levels
        $sortedIndents = $indentLevels | Sort-Object
        for ($i = 1; $i -lt $sortedIndents.Count; $i++) {
            $diff = $sortedIndents[$i] - $sortedIndents[$i-1]
            if ($diff -ne 2) {
                $this.Results.Add([ValidationResult]::new("Style", "Info", "Inconsistent indentation spacing: $($sortedIndents[$i-1]) to $($sortedIndents[$i]) spaces", 0, ""))
            }
        }
    }
    
    [void] ValidateQuoting() {
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            if ($line.Trim().StartsWith('#')) { continue }
            
            # Check for unmatched quotes
            $singleQuoteCount = ($line.ToCharArray() | Where-Object { $_ -eq "'" }).Count
            $doubleQuoteCount = ($line.ToCharArray() | Where-Object { $_ -eq '"' }).Count
            
            if ($singleQuoteCount % 2 -ne 0) {
                $this.Results.Add([ValidationResult]::new("Syntax", "Error", "Unmatched single quote", $lineNum, $line.Trim()))
            }
            
            if ($doubleQuoteCount % 2 -ne 0) {
                $this.Results.Add([ValidationResult]::new("Syntax", "Error", "Unmatched double quote", $lineNum, $line.Trim()))
            }
            
            # Check for potentially unquoted special values
            if ($line -match ':\s*(yes|no|true|false|on|off|null|~)\s*$' -and $line -notmatch '".*"' -and $line -notmatch "'.*'") {
                $this.Results.Add([ValidationResult]::new("Style", "Info", "Consider quoting boolean/null value to ensure string interpretation", $lineNum, $line.Trim()))
            }            # Check for unquoted values with special characters
            if ($line -match ':\s*[^"\s][^"]*[\\@#\$%\^&\*\(\)\[\]\{\}|>]' -and $line -notmatch '".*"' -and $line -notmatch "'.*'" -and $line -notmatch '^\s*#') {
                $this.Results.Add([ValidationResult]::new("Style", "Warning", "Unquoted value contains special characters", $lineNum, $line.Trim()))
            }
        }
    }
    
    [void] ValidateKeys() {
        $seenKeys = @{}
        
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            if ($line.Trim().StartsWith('#')) { continue }
            
            # Extract key from key-value pairs
            if ($line -match '^\s*([^:\s][^:]*?):\s*(.*)$') {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()
                $indent = ($line -replace '^(\s*).*$', '$1').Length
                
                # Check for duplicate keys at same indent level
                $keyWithIndent = "$indent`:$key"
                if ($seenKeys.ContainsKey($keyWithIndent)) {
                    $this.Results.Add([ValidationResult]::new("Structure", "Warning", "Duplicate key '$key' at same level (first seen at line $($seenKeys[$keyWithIndent]))", $lineNum, $line.Trim()))
                } else {
                    $seenKeys[$keyWithIndent] = $lineNum
                }
                
                # Check for empty keys
                if ($key -eq "") {
                    $this.Results.Add([ValidationResult]::new("Syntax", "Error", "Empty key found", $lineNum, $line.Trim()))
                }
                
                # Check for keys with leading/trailing spaces
                if ($key -ne $key.Trim()) {
                    $this.Results.Add([ValidationResult]::new("Style", "Warning", "Key has leading or trailing spaces", $lineNum, $line.Trim()))
                }
                
                # Check for numeric keys that might need quoting
                if ($key -match '^\d+$') {
                    $this.Results.Add([ValidationResult]::new("Style", "Info", "Numeric key '$key' - consider quoting if string interpretation intended", $lineNum, $line.Trim()))
                }
            }
        }
    }
    
    [void] ValidateValues() {
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            if ($line.Trim().StartsWith('#')) { continue }
            
            if ($line -match '^\s*[^:]+:\s*(.*)$') {
                $value = $matches[1].Trim()
                
                # Check for empty values (not necessarily bad, but worth noting)
                if ($value -eq "" -and $i + 1 -lt $this.Lines.Count) {
                    $nextLine = $this.Lines[$i + 1]
                    if (-not ($nextLine -match '^\s{2,}' -or $nextLine.Trim() -eq "")) {
                        $this.Results.Add([ValidationResult]::new("Structure", "Info", "Empty value - may be intentional", $lineNum, $line.Trim()))
                    }
                }
                
                # Check for potentially problematic multiline indicators
                if ($value -match '^[|>]' -and $i + 1 -lt $this.Lines.Count) {
                    $nextLine = $this.Lines[$i + 1]
                    $currentIndent = ($line -replace '^(\s*).*$', '$1').Length
                    $nextIndent = ($nextLine -replace '^(\s*).*$', '$1').Length
                    
                    if ($nextLine.Trim() -ne "" -and $nextIndent -le $currentIndent) {
                        $this.Results.Add([ValidationResult]::new("Syntax", "Warning", "Multiline block may not be properly indented", $lineNum, $line.Trim()))
                    }
                }
            }
        }
    }
    
    [void] ValidateStructure() {
        $braceCount = 0
        $bracketCount = 0
        
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            if ($line.Trim().StartsWith('#')) { continue }
            
            # Count braces and brackets
            $braceCount += ($line.ToCharArray() | Where-Object { $_ -eq '{' }).Count
            $braceCount -= ($line.ToCharArray() | Where-Object { $_ -eq '}' }).Count
            $bracketCount += ($line.ToCharArray() | Where-Object { $_ -eq '[' }).Count
            $bracketCount -= ($line.ToCharArray() | Where-Object { $_ -eq ']' }).Count
            
            # Check for mixed array/object syntax
            if ($line -match '^\s*-\s*\w+:' -and $line -match '\[.*\]') {
                $this.Results.Add([ValidationResult]::new("Style", "Warning", "Mixed array/object syntax on same line", $lineNum, $line.Trim()))
            }
        }
        
        # Check for unmatched braces/brackets
        if ($braceCount -ne 0) {
            $this.Results.Add([ValidationResult]::new("Syntax", "Error", "Unmatched braces (difference: $braceCount)", 0, ""))
        }
        
        if ($bracketCount -ne 0) {
            $this.Results.Add([ValidationResult]::new("Syntax", "Error", "Unmatched brackets (difference: $bracketCount)", 0, ""))
        }
    }
    
    [void] ValidateSpecialCharacters() {
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            if ($line.Trim().StartsWith('#')) { continue }
            
            # Check for Unicode issues
            if ($line -match '[^\x00-\x7F]') {
                $this.Results.Add([ValidationResult]::new("Encoding", "Info", "Non-ASCII characters found", $lineNum, $line.Trim()))
            }
            
            # Check for Windows line endings in mixed file
            if ($line.EndsWith("`r")) {
                $this.Results.Add([ValidationResult]::new("Encoding", "Info", "Windows line ending (CRLF) detected", $lineNum, ""))
            }
            
            # Check for potential escape sequence issues
            if ($line -match '\\[^"\\\/bfnrt]' -and $line -notmatch '".*\\[^"\\\/bfnrt].*"') {
                $this.Results.Add([ValidationResult]::new("Syntax", "Warning", "Potentially invalid escape sequence", $lineNum, $line.Trim()))
            }
        }
    }
    
    [void] ValidateComments() {
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            # Check for inline comments without proper spacing
            if ($line -match '\S#' -and -not $line.Trim().StartsWith('#')) {
                $this.Results.Add([ValidationResult]::new("Style", "Warning", "Inline comment without space before #", $lineNum, $line.Trim()))
            }
            
            # Check for TODO/FIXME comments
            if ($line -match '#.*(TODO|FIXME|XXX|HACK)') {
                $this.Results.Add([ValidationResult]::new("Content", "Info", "Development comment found", $lineNum, $line.Trim()))
            }
        }
    }
    
    [void] ValidateGitHubActions() {
        $content = $this.Lines -join "`n"
        
        # Check required top-level keys
        foreach ($key in $this.GitHubActionsSchema.RequiredTopLevel) {
            if ($content -notmatch "(?m)^$key\s*:") {
                $this.Results.Add([ValidationResult]::new("GitHub Actions", "Error", "Missing required top-level key: $key", 0, ""))
            }
        }
        
        # Validate trigger events
        if ($content -match "(?m)^on\s*:") {
            $this.ValidateWorkflowTriggers()
        }
        
        # Validate jobs
        if ($content -match "(?m)^jobs\s*:") {
            $this.ValidateJobs()
        }
        
        # Check for common GitHub Actions patterns
        $this.ValidateGitHubActionsPatterns()
    }
    
    [void] ValidateWorkflowTriggers() {
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            # Look for trigger event definitions
            if ($line -match '^\s{2}(\w+):' -and $line -match "^on\s*:" -eq $false) {
                $event = $matches[1]
                if ($this.GitHubActionsSchema.TriggerEvents -notcontains $event -and $line.IndexOf('on:') -eq -1) {
                    $this.Results.Add([ValidationResult]::new("GitHub Actions", "Warning", "Unknown trigger event: $event", $lineNum, $line.Trim()))
                }
            }
        }
    }
    
    [void] ValidateJobs() {
        $inJobsSection = $false
        $currentJob = ""
        
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            # Detect jobs section
            if ($line -match '^jobs\s*:') {
                $inJobsSection = $true
                continue
            }
            
            # Exit jobs section
            if ($inJobsSection -and $line -match '^[a-zA-Z]' -and $line -notmatch '^\s') {
                $inJobsSection = $false
            }
            
            if ($inJobsSection) {
                # Job definition
                if ($line -match '^\s{2}([a-zA-Z0-9_-]+)\s*:') {
                    $currentJob = $matches[1]
                }
                
                # Validate runs-on
                if ($line -match '^\s{4}runs-on\s*:\s*(.+)$') {
                    $runner = $matches[1].Trim().Trim('"').Trim("'")
                    if ($this.GitHubActionsSchema.RunnerLabels -notcontains $runner -and $runner -notmatch '\$\{\{') {
                        $this.Results.Add([ValidationResult]::new("GitHub Actions", "Warning", "Unknown runner label: $runner", $lineNum, $line.Trim()))
                    }
                }
                
                # Validate shell
                if ($line -match '^\s+shell\s*:\s*(.+)$') {
                    $shell = $matches[1].Trim().Trim('"').Trim("'")
                    if ($this.GitHubActionsSchema.Shells -notcontains $shell) {
                        $this.Results.Add([ValidationResult]::new("GitHub Actions", "Warning", "Unknown shell: $shell", $lineNum, $line.Trim()))
                    }
                }
            }
        }
    }
    
    [void] ValidateGitHubActionsPatterns() {
        for ($i = 0; $i -lt $this.Lines.Count; $i++) {
            $line = $this.Lines[$i]
            $lineNum = $i + 1
            
            # Check for potential security issues
            if ($line -match '\$\{\{\s*github\.event\.') {
                $this.Results.Add([ValidationResult]::new("Security", "Warning", "Direct use of github.event data - ensure proper validation", $lineNum, $line.Trim()))
            }
            
            # Check for missing step names
            if ($line -match '^\s*-\s*uses:' -or $line -match '^\s*-\s*run:') {
                # Look back for name
                $hasName = $false
                for ($j = $i - 1; $j -ge 0 -and $this.Lines[$j] -match '^\s'; $j--) {
                    if ($this.Lines[$j] -match '^\s*name\s*:') {
                        $hasName = $true
                        break
                    }
                    if ($this.Lines[$j] -match '^\s*-\s') {
                        break
                    }
                }
                if (-not $hasName) {
                    $this.Results.Add([ValidationResult]::new("Style", "Info", "Step without name - consider adding for better readability", $lineNum, $line.Trim()))
                }
            }
            
            # Check for hardcoded secrets
            if ($line -match 'password|token|key|secret' -and $line -notmatch '\$\{\{\s*secrets\.' -and $line -match ':\s*[^$]') {
                $this.Results.Add([ValidationResult]::new("Security", "Warning", "Potential hardcoded credential - use secrets instead", $lineNum, $line.Trim()))
            }
        }
    }
    
    [hashtable] GetSummary() {
        $summary = @{
            Total = $this.Results.Count
            Errors = ($this.Results | Where-Object { $_.Severity -eq "Error" }).Count
            Warnings = ($this.Results | Where-Object { $_.Severity -eq "Warning" }).Count
            Info = ($this.Results | Where-Object { $_.Severity -eq "Info" }).Count
            ByType = @{}
        }
        
        foreach ($result in $this.Results) {
            if (-not $summary.ByType.ContainsKey($result.Type)) {
                $summary.ByType[$result.Type] = 0
            }
            $summary.ByType[$result.Type]++
        }
        
        return $summary
    }
}

# Main execution
Write-Host "=== Comprehensive YAML Validation ===" -ForegroundColor Cyan
Write-Host "File: $YamlFile" -ForegroundColor Yellow
Write-Host

$validator = [YamlValidator]::new()
$validator.ValidateFile($YamlFile, $GitHubActions)

$summary = $validator.GetSummary()

# Display results
if ($summary.Total -eq 0) {
    Write-Host "✅ No issues found! YAML appears to be valid." -ForegroundColor Green
} else {
    Write-Host "📊 Validation Summary:" -ForegroundColor Yellow
    Write-Host "  Total Issues: $($summary.Total)" -ForegroundColor Gray
    Write-Host "  Errors: $($summary.Errors)" -ForegroundColor Red
    Write-Host "  Warnings: $($summary.Warnings)" -ForegroundColor Yellow
    Write-Host "  Info: $($summary.Info)" -ForegroundColor Cyan
    Write-Host
    
    if ($summary.ByType.Count -gt 0) {
        Write-Host "📈 Issues by Type:" -ForegroundColor Yellow
        foreach ($type in $summary.ByType.Keys | Sort-Object) {
            Write-Host "  $type`: $($summary.ByType[$type])" -ForegroundColor Gray
        }
        Write-Host
    }
    
    # Group and display results
    $groupedResults = $validator.Results | Group-Object Severity
    
    foreach ($group in $groupedResults | Sort-Object { @("Error", "Warning", "Info").IndexOf($_.Name) }) {
        $color = switch ($group.Name) {
            "Error" { "Red" }
            "Warning" { "Yellow" }
            "Info" { "Cyan" }
            default { "Gray" }
        }
        
        Write-Host "🔍 $($group.Name)s ($($group.Count)):" -ForegroundColor $color
        
        foreach ($result in $group.Group | Sort-Object LineNumber) {
            $lineInfo = if ($result.LineNumber -gt 0) { " (Line $($result.LineNumber))" } else { "" }
            Write-Host "  [$($result.Type)]$lineInfo $($result.Message)" -ForegroundColor $color
            
            if ($Detailed -and $result.Context) {
                Write-Host "    Context: $($result.Context)" -ForegroundColor DarkGray
            }
        }
        Write-Host
    }
}

# Export report if requested
if ($ExportReport) {
    $reportPath = $YamlFile -replace '\.[^.]*$', '-validation-report.json'
    $reportData = @{
        File = $YamlFile
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Summary = $summary
        Results = $validator.Results
        IsGitHubActions = $validator.IsGitHubActionsWorkflow
    }
    
    $reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Host "📄 Detailed report exported to: $reportPath" -ForegroundColor Green
}

Write-Host
if ($summary.Errors -gt 0) {
    Write-Host "❌ Validation completed with errors!" -ForegroundColor Red
    exit 1
} elseif ($summary.Warnings -gt 0) {
    Write-Host "⚠️ Validation completed with warnings." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "✅ Validation completed successfully!" -ForegroundColor Green
    exit 0
}
        # Required top-level keys for GitHub Actions
        $requiredGHA = @('name', 'on', 'jobs')
        foreach ($req in $requiredGHA) {
            if ($content -notmatch "^$req\s*:") {
                $githubActionsIssues += "Missing required GitHub Actions key: '$req'"
            }
        }
        
        # Validate job structure
        $jobsMatch = $content -match '(?s)jobs:\s*\n(.*?)(?=\n\w+:|$)'
        if ($jobsMatch) {
            # Check for job-specific requirements
            $jobPattern = '^\s{2}([a-zA-Z0-9_-]+):\s*$'
            $jobMatches = [regex]::Matches($content, $jobPattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
            
            foreach ($jobMatch in $jobMatches) {
                $jobName = $jobMatch.Groups[1].Value
                $jobSection = $content -replace "(?s).*?^\s{2}$jobName\s*:\s*\n(.*?)(?=^\s{2}\w+:|$)", '$1'
                
                # Check for required job keys
                $requiredJobKeys = @('runs-on')
                foreach ($jobKey in $requiredJobKeys) {
                    if ($jobSection -notmatch "$jobKey\s*:") {
                        $githubActionsIssues += "Job '$jobName' missing required key: '$jobKey'"
                    }
                }
                
                # Check for empty runs-on
                if ($jobSection -match 'runs-on:\s*$') {
                    $githubActionsIssues += "Job '$jobName' has empty 'runs-on' value"
                }
                
                # Check for empty needs arrays
                if ($jobSection -match 'needs:\s*$') {
                    $warnings += "Job '$jobName' has empty 'needs' value (might be intentional)"
                }
            }
        }
        
        # Check for common GitHub Actions patterns
        if ($content -match '\$\{\{.*\}\}') {
            Write-Host "✓ GitHub Actions expressions found" -ForegroundColor Green
        }
        
        # Validate action versions
        $actionMatches = [regex]::Matches($content, 'uses:\s*([^@\s]+)(@[^\s]*)?')
        foreach ($actionMatch in $actionMatches) {
            $action = $actionMatch.Groups[1].Value
            $version = $actionMatch.Groups[2].Value
            
            if ([string]::IsNullOrEmpty($version)) {
                $warnings += "Action '$action' used without version specification"
            } elseif ($version -eq '@main' -or $version -eq '@master') {
                $warnings += "Action '$action' using unstable branch reference '$version'"
            }
        }
    }
    
    # Report all findings
    Write-Host
    Write-Host "=== Validation Results ===" -ForegroundColor Cyan
    
    $totalIssues = $syntaxIssues.Count + $structureIssues.Count + $githubActionsIssues.Count
    $totalWarnings = $warnings.Count
    
    if ($totalIssues -eq 0 -and $totalWarnings -eq 0) {
        Write-Host "🎉 YAML validation passed with no issues!" -ForegroundColor Green
    } else {
        if ($totalIssues -gt 0) {
            Write-Host "❌ Found $totalIssues critical issues:" -ForegroundColor Red
            Write-Host
            
            if ($syntaxIssues.Count -gt 0) {
                Write-Host "Syntax Issues:" -ForegroundColor Red
                foreach ($issue in $syntaxIssues) {
                    Write-Host "  • $issue" -ForegroundColor Red
                }
                Write-Host
            }
            
            if ($structureIssues.Count -gt 0) {
                Write-Host "Structure Issues:" -ForegroundColor Red
                foreach ($issue in $structureIssues) {
                    Write-Host "  • $issue" -ForegroundColor Red
                }
                Write-Host
            }
            
            if ($githubActionsIssues.Count -gt 0) {
                Write-Host "GitHub Actions Issues:" -ForegroundColor Red
                foreach ($issue in $githubActionsIssues) {
                    Write-Host "  • $issue" -ForegroundColor Red
                }
                Write-Host
            }
        }
        
        if ($totalWarnings -gt 0) {
            Write-Host "⚠️ Found $totalWarnings warnings:" -ForegroundColor Yellow
            Write-Host
            foreach ($warning in $warnings) {
                Write-Host "  • $warning" -ForegroundColor Yellow
            }
            Write-Host
        }
        
        if ($totalIssues -gt 0) {
            Write-Host "These issues should be fixed before using the YAML file." -ForegroundColor Red
        } else {
            Write-Host "Warnings are advisory - the YAML should still work correctly." -ForegroundColor Yellow
        }
    }
    
    if ($Detailed) {
        Write-Host
        Write-Host "=== Detailed Analysis ===" -ForegroundColor Cyan
        
        # File statistics
        $fileSize = (Get-Item $YamlFile).Length
        Write-Host "File size: $fileSize bytes" -ForegroundColor Gray
        Write-Host "Line count: $($lines.Count)" -ForegroundColor Gray
        Write-Host "Non-empty lines: $(($lines | Where-Object { $_ -notmatch '^\s*$' }).Count)" -ForegroundColor Gray
        Write-Host "Comment lines: $(($lines | Where-Object { $_ -match '^\s*#' }).Count)" -ForegroundColor Gray
        
        # Indentation analysis
        if ($indentLevels.Count -gt 0) {
            Write-Host
            Write-Host "Indentation levels found:" -ForegroundColor Gray
            foreach ($level in $indentLevels.Keys | Sort-Object) {
                Write-Host "  $level spaces: $($indentLevels[$level].Count) keys" -ForegroundColor Gray
            }
        }
        
        # Job analysis for GitHub Actions
        if ($GitHubActions -or $content -match 'jobs:') {
            $jobMatches = [regex]::Matches($content, '^\s{2}([a-zA-Z0-9_-]+):\s*$', [System.Text.RegularExpressions.RegexOptions]::Multiline)
            if ($jobMatches.Count -gt 0) {
                Write-Host
                Write-Host "Jobs found ($($jobMatches.Count)):" -ForegroundColor Gray
                foreach ($match in $jobMatches) {
                    $jobName = $match.Groups[1].Value
                    Write-Host "  • $jobName" -ForegroundColor Gray
                }
            }
        }
    }   $jobName = $match.Value.Trim().TrimEnd(':')
        Write-Host "  • $jobName" -ForegroundColor Gray
    }
    
} catch {
    Write-Error "Failed to validate YAML: $($_.Exception.Message)"
    exit 1
}

Write-Host
Write-Host "Validation completed!" -ForegroundColor Green

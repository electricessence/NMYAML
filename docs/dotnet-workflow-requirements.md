# .NET Library CI/CD Workflow Requirements

## Overview
This document outlines the requirements for a .NET library CI/CD workflow that uses `<VersionPrefix/>` and follows an efficient, logical flow with clear separation of concerns.

## Key Principles
- **Efficiency**: Keep steps together that benefit from each other
- **Logical Grouping**: Break apart functionality so GitHub's flow diagram shows clear groups and progression
- **PowerShell Integration**: Use PowerShell scripts for complex functionality rather than overcomplicated YAML
- **Well-Defined Functions**: PowerShell script functions should be clearly documented for expectations

## Workflow Blocks

### a) Build & Test
**Purpose**: Build library in Debug mode and run tests using the same build
- Build the library as Debug configuration
- If build errors occur:
  - Make errors obvious to repo owner
  - Jump to Summary block
- If build succeeds:
  - Use existing build (no rebuild) to run tests
  - If test errors occur:
    - Report test failures
    - Jump to Summary block

### b) Check for Tag
**Purpose**: Determine if current commit has a tag
- If tag exists: Jump to **Pack & Publish** block
- If no tag: Continue to next block

### c) Check Success of Previous Build
**Purpose**: Verify previous build status to determine workflow path
- If previous build failed: Jump to **Pack & Publish** block
- If previous build succeeded: Continue to **Diff Check** block

### d) Diff Check
**Purpose**: Detect changes since last publish (only if previous build was successful)
- **Complex Step**: Requires PowerShell scripting
- **PowerShell Function Expectation**:
  - Returns `true` if no changes (same as last publish)
  - Returns `false` if changes detected
- **Flow Logic**:
  - If no changes detected: Skip to **Summary** block
  - If changes detected: Continue to **Pack & Publish** block

### p) Pack & Publish
**Purpose**: Pack and publish the library to GitHub Packages with appropriate versioning

#### p.A) Tagged Commit Scenario
- **No suffix used**
- **Dual publication**:
  - Release version (e.g., `3.2.1`)
  - Debug version (e.g., `3.2.1-debug`)

#### p.B) Non-Tagged Commit Scenario
- **Suffix format**: Uses branch name and timestamp
- **Timestamp format**: Condensed date + 24-hour time (no seconds)
- **Examples**:
  - Non-main branch: `3.2.1-branch-250403-1330`
  - Main branch: `3.2.1-250403-1330`

### z) Summary
**Purpose**: Provide comprehensive summary of workflow execution results
- Summarize all executed steps
- Report final status and outcomes

## Technical Implementation Notes

### PowerShell Script Functions Required

1. **Build-DotNetLibrary**
   - Build library in Debug configuration
   - Return build success/failure status
   - Capture and format build errors

2. **Test-DotNetLibrary**
   - Run tests using existing Debug build
   - Return test success/failure status
   - Capture and format test results

3. **Get-CommitTag**
   - Check if current commit has associated tag
   - Return tag information or null

4. **Get-PreviousBuildStatus**
   - Query previous workflow run status
   - Return success/failure boolean

5. **Compare-ChangesFromLastPublish**
   - Complex diff analysis function
   - Compare current state vs last published version
   - Return boolean: true (no changes) / false (changes detected)

6. **New-PackageVersion**
   - Generate appropriate version suffix
   - Handle tag vs non-tag scenarios
   - Format timestamp for versioning

7. **Publish-GitHubPackage**
   - Pack and publish to GitHub Packages
   - Handle dual publication for tagged releases
   - Manage version suffixes

8. **Write-WorkflowSummary**
   - Generate comprehensive execution summary
   - Format results for GitHub Actions summary

### GitHub Actions Flow Visualization
The workflow should create a clear visual flow in GitHub's Actions interface:
```
Build & Test → Check for Tag → Check Previous Build → Diff Check → Pack & Publish → Summary
     ↓              ↓                    ↓               ↓              ↑
  [Fail] ────────────────────────────────────────────────────────────────┘
     ↓              ↓                    ↓               ↓
  Summary        Pack & Publish      Pack & Publish   Summary
```

## Version Management Strategy

### VersionPrefix Usage
- Library uses `<VersionPrefix/>` in project file
- Base version (e.g., `3.2.1`) comes from this setting
- Suffixes are dynamically applied based on build context

### Suffix Patterns
- **Tagged Release**: No suffix (`3.2.1`) + Debug variant (`3.2.1-debug`)
- **Main Branch**: Timestamp only (`3.2.1-250403-1330`)
- **Feature Branch**: Branch + Timestamp (`3.2.1-feature-250403-1330`)

This workflow design ensures efficient CI/CD processing while maintaining clear separation of concerns and comprehensive error handling.

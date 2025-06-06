# YAML-XML Transformation Toolkit

This toolkit provides tools to transform between YAML and XML formats, with support for both namespaced and non-namespaced XML variants.

## Directory Structure

```
scripts/
├── demos/                          # Demonstration scripts
│   ├── Complete-SchemaConversionExample.ps1  # Comprehensive demo
│   ├── Demo-SchemaConversion.ps1   # Simple schema conversion demo
│   ├── Demo-SchemaValidation.ps1   # Schema validation demo
│   └── Schema-Comparison-Demo.ps1  # Namespaced vs non-namespaced comparison
├── modules/                        # PowerShell modules
│   ├── XmlYamlUtils.psm1           # Core transformation utilities
│   ├── XmlYamlSchema.psm1          # Schema management utilities
│   ├── TerminalOutput.psm1         # Terminal formatting utilities
│   └── SchemaConversionReport.psm1 # Reporting utilities
├── validation/                     # Validation scripts
│   ├── Test-ComplexSchemaValidation.ps1 # Complex XML validation tests
│   ├── Test-SchemaConversion.ps1   # Schema conversion test suite
│   ├── Validate-AllXmlSamples.ps1  # Batch validation script
│   └── Validate-XmlWithSchema.ps1  # XML validation script
├── Convert-YamlXml.ps1             # Main conversion script
├── Manage-YamlSchema.ps1           # Schema management script
├── Convert-NamespacedSchema.ps1    # Schema namespace conversion script
├── Compare-XmlSchemas.ps1          # Schema comparison script
├── Yaml-Xml-Cheatsheet.ps1         # Reference guide for YAML XML format
├── transform.ps1                   # XML to YAML transformation script
├── transform.bat                   # Batch wrapper for transform.ps1
└── convert-schema.bat              # Batch wrapper for Convert-NamespacedSchema.ps1
```

## Modules

### XmlYamlUtils.psm1

Core utilities for XML-YAML transformation:

- **Test-XmlValidation** - Tests XML validation against an XSD schema
- **Convert-XmlToYaml** - Transforms XML to YAML using XSLT
- **Show-YamlContent** - Displays YAML content with syntax highlighting

### XmlYamlSchema.psm1

Utilities for XML schema management:

- **New-CombinedSchema** - Creates a combined schema supporting both namespaced and non-namespaced XML
- **Test-SchemaFlexibility** - Tests if a schema supports both namespaced and non-namespaced XML
- **Test-XmlAgainstSchema** - Tests XML validation against an XSD schema

### TerminalOutput.psm1

Terminal formatting and user interface utilities:

- **Write-Banner** - Displays a formatted banner with customizable style
- **Write-InfoMessage** - Displays an informational message with optional styling
- **Write-SuccessMessage** - Displays a success message with green highlighting
- **Write-ErrorMessage** - Displays an error message with red highlighting
- **Write-WarningMessage** - Displays a warning message with yellow highlighting
- **Write-ConsoleTable** - Displays data in a formatted table layout
- **Show-ActivitySpinner** - Displays an animated spinner during long-running operations

### SchemaConversionReport.psm1

Reporting utilities for schema conversion:

- **Add-ConversionLogEntry** - Records a schema conversion change
- **Clear-ConversionLog** - Resets the conversion log
- **Get-ConversionLog** - Returns the complete conversion log
- **Get-ConversionSummary** - Summarizes conversion changes by type
- **Export-ConversionLog** - Exports the conversion log to an XML file

## Main Scripts

### Convert-YamlXml.ps1

Main transformation script with options:

```powershell
.\Convert-YamlXml.ps1 [-Mode <string>] [-XmlFile <string>] [-XsltFile <string>] [-OutputFile <string>] [-ValidateInput] [-XsdFile <string>] [-ShowOutput] [-UseNamespaces]
```

Parameters:
- **Mode** - Transformation mode (xml-to-yaml, yaml-to-xml)
- **XmlFile** - Path to the XML file
- **XsltFile** - Path to the XSLT stylesheet
- **OutputFile** - Path to save the output
- **ValidateInput** - Validate the input XML against an XSD schema
- **XsdFile** - Path to the XSD schema for validation
- **ShowOutput** - Display the transformation output
- **UseNamespaces** - Use XML namespaces

### Manage-YamlSchema.ps1

Schema management script with options:

```powershell
.\Manage-YamlSchema.ps1 [-Action <string>] [-NamespacedSchemaPath <string>] [-NonNamespacedSchemaPath <string>] [-OutputSchemaPath <string>] [-NamespacedXmlPath <string>] [-NonNamespacedXmlPath <string>]
```

Parameters:
- **Action** - Management action (test, combine, convert)
- **NamespacedSchemaPath** - Path to the namespaced XML schema
- **NonNamespacedSchemaPath** - Path to the non-namespaced XML schema
- **OutputSchemaPath** - Path to save the combined schema
- **NamespacedXmlPath** - Path to the namespaced sample XML
- **NonNamespacedXmlPath** - Path to the non-namespaced sample XML

### Convert-NamespacedSchema.ps1

Schema namespace conversion script with options:

```powershell
.\Convert-NamespacedSchema.ps1 [-InputSchemaPath <string>] [-OutputSchemaPath <string>] [-Backup] [-GenerateReport] [-ReportPath <string>]
```

Parameters:
- **InputSchemaPath** - Path to the input namespaced schema
- **OutputSchemaPath** - Path to save the non-namespaced schema
- **Backup** - Create a backup of the existing output schema
- **GenerateReport** - Generate a detailed conversion report
- **ReportPath** - Path to save the conversion report

### Compare-XmlSchemas.ps1

Schema comparison tool with options:

```powershell
.\Compare-XmlSchemas.ps1 -Schema1Path <string> -Schema2Path <string> [-CompareStructureOnly] [-IgnoreNamespaces]
```

Parameters:
- **Schema1Path** - Path to the first XML schema
- **Schema2Path** - Path to the second XML schema
- **CompareStructureOnly** - Compare only schema structure (not content)
- **IgnoreNamespaces** - Ignore namespace differences during comparison

### Test-SchemaConversion.ps1

Comprehensive test suite for schema conversion:

```powershell
.\Test-SchemaConversion.ps1 [-NamespacedSchemaPath <string>] [-NonNamespacedSchemaPath <string>] [-SamplesDirectory <string>]
```

Parameters:
- **NamespacedSchemaPath** - Path to the namespaced XML schema
- **NonNamespacedSchemaPath** - Path to the non-namespaced XML schema
- **SamplesDirectory** - Directory for test case samples

## Schema Conversion Workflow

The toolkit provides a complete workflow for managing XML schemas with namespace variations:

1. **Convert a Namespaced Schema to Non-namespaced**
   ```powershell
   # Using the dedicated conversion script
   .\Convert-NamespacedSchema.ps1 -InputSchemaPath "..\schemas\yaml-schema.xsd" -OutputSchemaPath "..\schemas\yaml-schema-no-namespace.xsd" -GenerateReport
   
   # Or using the management script
   .\Manage-YamlSchema.ps1 -Action convert
   ```

2. **Test Schema Flexibility**
   ```powershell
   .\Manage-YamlSchema.ps1 -Action test
   ```

3. **Compare Schemas for Semantic Equivalence**
   ```powershell
   .\Compare-XmlSchemas.ps1 -Schema1Path "..\schemas\yaml-schema.xsd" -Schema2Path "..\schemas\yaml-schema-no-namespace.xsd" -IgnoreNamespaces
   ```

4. **Run Comprehensive Tests**
   ```powershell
   .\Test-SchemaConversion.ps1
   ```

5. **Create a Combined Schema (supports both variants)**
   ```powershell
   .\Manage-YamlSchema.ps1 -Action combine
   ```

## Examples

### Convert XML to YAML

```powershell
.\Convert-YamlXml.ps1 -Mode xml-to-yaml -XmlFile sample.yaml.xml -OutputFile output.yaml -ShowOutput
```

### Validate XML with Schema

```powershell
.\Convert-YamlXml.ps1 -Mode xml-to-yaml -XmlFile sample.yaml.xml -OutputFile output.yaml -ValidateInput -XsdFile yaml-schema.xsd
```

### Test Schema Flexibility

```powershell
.\Manage-YamlSchema.ps1 -Action test
```

### Create Combined Schema

```powershell
.\Manage-YamlSchema.ps1 -Action combine
```

# Scripts Documentation

## Validation Shortcut Scripts

These PowerShell scripts provide convenient shortcuts for common validation scenarios using the NMYAML CLI tool:

### Validate-GitHubActionsXml.ps1
Validates XML files against the GitHub Actions schema.

```powershell
# Basic validation
.\Validate-GitHubActionsXml.ps1 -XmlPath "samples\dotnet-library-workflow.xml"

# Detailed validation with verbose output
.\Validate-GitHubActionsXml.ps1 -XmlPath "samples\github-workflow.xml" -Detailed -Verbose

# Validation without colored output
.\Validate-GitHubActionsXml.ps1 -XmlPath "samples\dotnet-library-workflow.xml" -NoColor
```

**Features:**
- Automatically uses the GitHub Actions schema from `schemas\github-actions-schema.xsd`
- Shows validation errors with line numbers and detailed messages
- Supports verbose mode for debugging
- Compatible with terminals that don't support ANSI colors

### Validate-XmlSyntax.ps1
Validates XML files for syntax errors only (no schema validation).

```powershell
# Check XML syntax only
.\Validate-XmlSyntax.ps1 -XmlPath "samples\dotnet-library-workflow.xml"

# Detailed syntax validation
.\Validate-XmlSyntax.ps1 -XmlPath "samples\github-workflow.xml" -Detailed -Verbose
```

**Features:**
- Fast syntax-only validation
- Useful for checking if XML is well-formed
- No schema dependencies required

### Validate-YamlCli.ps1
Validates YAML files using the NMYAML CLI tool.

```powershell
# Basic YAML syntax validation
.\Validate-YamlCli.ps1 -YamlPath "output\dotnet-library-workflow.yml"

# GitHub Actions specific validation
.\Validate-YamlCli.ps1 -YamlPath "output\github-workflow.yml" -GitHubActions -Detailed

# Export validation report
.\Validate-YamlCli.ps1 -YamlPath "output\workflow.yml" -GitHubActions -ExportReport
```

**Features:**
- YAML syntax validation
- Optional GitHub Actions workflow structure validation
- Export validation reports to JSON
- Detailed error reporting with line numbers

### Run-FullPipeline.ps1
Complete XML-to-YAML pipeline with validation and transformation.

```powershell
# Full pipeline: validate XML → transform → validate YAML
.\Run-FullPipeline.ps1 -XmlPath "samples\dotnet-library-workflow.xml"

# Custom output path with detailed logging
.\Run-FullPipeline.ps1 -XmlPath "samples\github-workflow.xml" -OutputPath "output\my-workflow.yml" -Detailed -Verbose

# Skip validation steps
.\Run-FullPipeline.ps1 -XmlPath "samples\workflow.xml" -SkipXmlValidation -SkipYamlValidation -Force
```

**Features:**
- Three-step pipeline: XML validation → transformation → YAML validation
- Optional steps can be skipped
- Automatic output path generation
- Force overwrite existing files
- Comprehensive error reporting

## Usage Examples

### Quick Schema Validation
```powershell
# Validate the dotnet library workflow against GitHub Actions schema
.\Validate-GitHubActionsXml.ps1 samples\dotnet-library-workflow.xml
```

### Complete Workflow Processing
```powershell
# Process XML through complete pipeline
.\Run-FullPipeline.ps1 samples\dotnet-library-workflow.xml

# Output will be in samples\dotnet-library-workflow.yml
```

### Debugging Validation Issues
```powershell
# Get detailed information about validation failures
.\Validate-GitHubActionsXml.ps1 samples\dotnet-library-workflow.xml -Detailed -Verbose
```

## Prerequisites

All scripts require:
- The NMYAML CLI tool to be built (`dotnet build` in the project root)
- PowerShell 5.1 or PowerShell Core 6+
- .NET 9.0 SDK

## Error Handling

All scripts:
- Exit with code 0 on success
- Exit with code 1 on validation failures or errors
- Provide detailed error messages and suggestions
- Support `--no-color` for CI/CD environments

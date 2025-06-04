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
- **UseNamespaces** - Use XML namespaces

### Manage-YamlSchema.ps1

Schema management script:

```powershell
.\Manage-YamlSchema.ps1 [-Action <string>] [-NamespacedSchemaPath <string>] [-NonNamespacedSchemaPath <string>] [-OutputSchemaPath <string>] [-NamespacedXmlPath <string>] [-NonNamespacedXmlPath <string>]
```

Parameters:
- **Action** - Management action (test, combine)
- **NamespacedSchemaPath** - Path to the namespaced schema
- **NonNamespacedSchemaPath** - Path to the non-namespaced schema
- **OutputSchemaPath** - Path to save the combined schema
- **NamespacedXmlPath** - Path to a namespaced XML sample
- **NonNamespacedXmlPath** - Path to a non-namespaced XML sample

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

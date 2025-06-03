# YAML-XML Transformation Toolkit

This toolkit provides tools to transform between YAML and XML formats, with support for both namespaced and non-namespaced XML variants.

## Directory Structure

```
scripts/
├── modules/
│   ├── XmlYamlUtils.psm1     # Core transformation utilities
│   └── XmlYamlSchema.psm1    # Schema management utilities
├── Convert-YamlXml.ps1       # Main conversion script
└── Manage-YamlSchema.ps1     # Schema management script
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

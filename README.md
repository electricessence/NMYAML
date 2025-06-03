# NMYAML: XML-YAML Transformation Framework

A comprehensive framework for transforming between XML and YAML formats with support for validation, namespaces, and integration with PowerShell.

## Features

- **XML to YAML Transformation** - Convert XML documents to YAML format
- **Schema Validation** - Validate XML against XSD schemas
- **Namespace Support** - Handle both namespaced and non-namespaced XML
- **XSLT-based Transformation** - Use XSLT stylesheets for flexible transformations
- **PowerShell Integration** - Easy to use from PowerShell scripts and modules
- **UTF-8 Support** - Proper handling of UTF-8 encoding

## Directory Structure

```
NMYAML/
├── scripts/                   # PowerShell scripts and modules
│   ├── modules/               # PowerShell modules
│   │   ├── XmlYamlUtils.psm1  # Core transformation utilities
│   │   └── XmlYamlSchema.psm1 # Schema management utilities
│   ├── Convert-YamlXml.ps1    # Main conversion script
│   └── Manage-YamlSchema.ps1  # Schema management script
├── xslt/                      # XSLT stylesheets
├── schemas/                   # XSD schemas
└── samples/                   # Sample XML and YAML files
```

## Getting Started

### Prerequisites

- Windows PowerShell 5.1 or PowerShell Core 7.0+
- .NET Framework 4.7.2+ or .NET Core 3.1+

### Basic Usage

1. Transform XML to YAML:

```powershell
cd scripts
.\Convert-YamlXml.ps1 -Mode xml-to-yaml -XmlFile ..\samples\sample.yaml.xml -OutputFile output.yaml
```

2. Validate XML Schema:

```powershell
cd scripts
.\Manage-YamlSchema.ps1 -Action test
```

## Understanding the Components

### XML Schema (XSD)

Two schema options are provided:

1. **yaml-schema.xsd** - Schema for namespaced XML (`xmlns:yaml="http://yaml.org/xml/1.2"`)
2. **yaml-schema-no-namespace.xsd** - Schema for non-namespaced XML

### XSLT Stylesheets

1. **xml-to-yaml-universal.xslt** - Transforms both namespaced and non-namespaced XML to YAML
2. **xml-to-yaml-simple.xslt** - Simplified transformation for basic YAML output

### XML Formats

The framework supports two XML formats:

1. **Namespaced XML**:

```xml
<yaml:document xmlns:yaml="http://yaml.org/xml/1.2">
  <yaml:mapping>
    <yaml:entry>
      <yaml:key>
        <yaml:scalar type="string">name</yaml:scalar>
      </yaml:key>
      <yaml:value>
        <yaml:scalar type="string">John Doe</yaml:scalar>
      </yaml:value>
    </yaml:entry>
  </yaml:mapping>
</yaml:document>
```

2. **Non-namespaced XML**:

```xml
<document>
  <mapping>
    <entry key="name">
      <scalar type="string">John Doe</scalar>
    </entry>
  </mapping>
</document>
```

## Advanced Usage

### Creating a Combined Schema

To create a schema that supports both namespaced and non-namespaced XML:

```powershell
cd scripts
.\Manage-YamlSchema.ps1 -Action combine
```

### Using PowerShell Modules Directly

```powershell
Import-Module ".\scripts\modules\XmlYamlUtils.psm1"
Convert-XmlToYaml -XmlFile "sample.yaml.xml" -XsltFile "xml-to-yaml-universal.xslt" -OutputFile "output.yaml"
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

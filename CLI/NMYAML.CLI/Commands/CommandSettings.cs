using Spectre.Console.Cli;
using System.ComponentModel;

namespace NMYAML.CLI.Commands;

public class BaseSettings : CommandSettings
{
	[CommandOption("-v|--verbose")]
	[Description("Enable verbose output")]
	public bool Verbose { get; set; }

	[CommandOption("--no-color")]
	[Description("Disable colored output")]
	public bool NoColor { get; set; }
}

public class TransformSettings : BaseSettings
{
	[CommandArgument(0, "<INPUT>")]
	[Description("Input XML file path")]
	public string InputPath { get; set; } = string.Empty;

	[CommandArgument(1, "<OUTPUT>")]
	[Description("Output YAML file path")]
	public string OutputPath { get; set; } = string.Empty;

	[CommandOption("--xslt")]
	[Description("Custom XSLT transform file path")]
	public string? XsltPath { get; set; }

	[CommandOption("-f|--force")]
	[Description("Force overwrite existing output file")]
	public bool ForceOverwrite { get; set; }
}

public class ValidateSettings : BaseSettings
{
	[CommandArgument(0, "<FILE>")]
	[Description("File to validate")]
	public string FilePath { get; set; } = string.Empty;

	[CommandOption("-s|--schema")]
	[Description("XSD schema file path (for XML validation)")]
	public string? SchemaPath { get; set; }

	[CommandOption("-d|--detailed")]
	[Description("Show detailed validation results")]
	public bool Detailed { get; set; }

	[CommandOption("--github-actions")]
	[Description("Enable GitHub Actions specific validation")]
	public bool GitHubActions { get; set; }
}

public class ConvertSettings : BaseSettings
{
	[CommandArgument(0, "<INPUT>")]
	[Description("Input XML file path")]
	public string InputPath { get; set; } = string.Empty;

	[CommandArgument(1, "<OUTPUT>")]
	[Description("Output YAML file path")]
	public string OutputPath { get; set; } = string.Empty;

	[CommandOption("--schema")]
	[Description("XSD schema file path for XML validation")]
	public string? SchemaPath { get; set; }

	[CommandOption("--xslt")]
	[Description("Custom XSLT transform file path")]
	public string? XsltPath { get; set; }

	[CommandOption("--skip-xml-validation")]
	[Description("Skip XML schema validation")]
	public bool SkipXmlValidation { get; set; }

	[CommandOption("--skip-yaml-validation")]
	[Description("Skip YAML syntax validation")]
	public bool SkipYamlValidation { get; set; }

	[CommandOption("-f|--force")]
	[Description("Force overwrite existing output file")]
	public bool ForceOverwrite { get; set; }

	[CommandOption("-d|--detailed")]
	[Description("Show detailed validation results")]
	public bool DetailedOutput { get; set; }
}

public class SchemaValidateSettings : BaseSettings
{
	[CommandArgument(0, "<XML_FILE>")]
	[Description("XML file to validate")]
	public string XmlPath { get; set; } = string.Empty;

	[CommandArgument(1, "<SCHEMA_FILE>")]
	[Description("XSD schema file")]
	public string SchemaPath { get; set; } = string.Empty;

	[CommandOption("-d|--detailed")]
	[Description("Show detailed validation results")]
	public bool Detailed { get; set; }
}

public class YamlValidateSettings : BaseSettings
{
	[CommandArgument(0, "<YAML_FILE>")]
	[Description("YAML file to validate")]
	public string YamlPath { get; set; } = string.Empty;

	[CommandOption("-d|--detailed")]
	[Description("Show detailed validation results")]
	public bool Detailed { get; set; }

	[CommandOption("--github-actions")]
	[Description("Enable GitHub Actions specific validation")]
	public bool GitHubActions { get; set; }

	[CommandOption("-e|--export-report")]
	[Description("Export validation report to JSON file")]
	public bool ExportReport { get; set; }
}

public class YamlFormatSettings : BaseSettings
{
	[CommandArgument(0, "<YAML_FILE>")]
	[Description("YAML file to format")]
	public string YamlPath { get; set; } = string.Empty;

	[CommandOption("-o|--output")]
	[Description("Output file path (default: overwrite input)")]
	public string? OutputPath { get; set; }

	[CommandOption("--indent")]
	[Description("Indentation size (default: 2)")]
	public int IndentSize { get; set; } = 2;

	[CommandOption("--dry-run")]
	[Description("Show what would be changed without modifying files")]
	public bool DryRun { get; set; }
}
